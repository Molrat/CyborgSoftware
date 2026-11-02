<#
.SYNOPSIS
    Runs CyborgSoftware's tests across all layers, skipping any layer whose prerequisites aren't met.

.DESCRIPTION
    Default behaviour (no switches) runs every layer:
      (1) Unit       tests/unit/**                - no prerequisites
      (2) Component  tests/component/**           - needs Docker Desktop running
      (3) E2E        tests/e2e/**                 - needs the compose stack up (cyborgsoftware-caddy)
      (4) Frontend   containers/frontend (Vitest + design-system lint) - needs npm
      (5) Browser    tests/browser (Playwright)   - needs the compose stack up, npm and Chrome

    Layers whose prerequisites aren't met are SKIPPED, not failed.

.PARAMETER Unit
    Run only the unit-test layer. Combinable with the other layer switches.

.PARAMETER Component
    Run only the component-test layer.

.PARAMETER E2E
    Run only the e2e layer.

.PARAMETER Frontend
    Run only the frontend layer: Vitest, then the design-system lint.

.PARAMETER Browser
    Run only the browser layer: Playwright journeys in Chrome against the
    running stack. Installs its npm packages on first use.

.PARAMETER NoBuild
    Pass --no-build to every dotnet test invocation. Useful when the test
    projects are already built and you only want to re-run.

.PARAMETER Filter
    Pass a --filter expression to every dotnet test invocation. Has no effect
    on the frontend or browser layers.

.EXAMPLE
    .\run-tests.ps1
    Runs every layer whose prerequisites are met.

.EXAMPLE
    .\run-tests.ps1 -Unit -Frontend
    Runs only the unit + frontend layers (fastest feedback loop, no Docker needed).

.EXAMPLE
    .\run-tests.ps1 -Component -NoBuild -Filter "FullyQualifiedName~<Feature>"
    Re-runs a single component test without rebuilding.
#>

[CmdletBinding()]
param(
    [switch]$Unit,
    [switch]$Component,
    [switch]$E2E,
    [switch]$Frontend,
    [switch]$Browser,
    [switch]$NoBuild,
    [string]$Filter
)

# If no layer is explicitly selected, run them all.
$runAll = -not ($Unit -or $Component -or $E2E -or $Frontend -or $Browser)

$repoRoot = $PSScriptRoot
$results  = [System.Collections.Generic.List[object]]::new()

function Write-Header($text) {
    Write-Host ""
    Write-Host ("=" * 67) -ForegroundColor Cyan
    Write-Host " $text"   -ForegroundColor Cyan
    Write-Host ("=" * 67) -ForegroundColor Cyan
}

function Add-Result {
    param([string]$Layer, [string]$Status, [TimeSpan]$Duration = [TimeSpan]::Zero, [string]$Note = "")
    $results.Add([pscustomobject]@{
        Layer    = $Layer
        Status   = $Status
        Duration = $Duration
        Note     = $Note
    })
}

function Test-DockerRunning {
    try {
        & docker info --format '{{.ServerVersion}}' 2>$null | Out-Null
        return $LASTEXITCODE -eq 0
    } catch { return $false }
}

function Test-StackRunning {
    try {
        $out = & docker ps --filter 'name=cyborgsoftware-caddy' --format '{{.Names}}' 2>$null
        return ($LASTEXITCODE -eq 0) -and ($out -match 'cyborgsoftware-caddy')
    } catch { return $false }
}

function Invoke-DotnetTestProjects {
    param([string]$Layer, [string]$LayerPath)

    $projects = Get-ChildItem -Path $LayerPath -Filter '*.csproj' -Recurse -ErrorAction SilentlyContinue
    if (-not $projects) {
        Write-Host "No .csproj files under $LayerPath - skipping." -ForegroundColor Yellow
        Add-Result $Layer 'SKIP' ([TimeSpan]::Zero) 'no projects'
        return
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $anyFailed = $false

    foreach ($p in $projects) {
        Write-Host ""
        Write-Host "-> $($p.BaseName)" -ForegroundColor Gray

        $dotnetArgs = @('test', $p.FullName, '--logger', 'console;verbosity=minimal', '--nologo')
        if ($NoBuild) { $dotnetArgs += '--no-build' }
        if ($Filter)  { $dotnetArgs += @('--filter', $Filter) }

        & dotnet @dotnetArgs
        if ($LASTEXITCODE -ne 0) { $anyFailed = $true }
    }

    $sw.Stop()
    $status = if ($anyFailed) { 'FAIL' } else { 'PASS' }
    Add-Result $Layer $status $sw.Elapsed
}

# ----------------------------------------------------------------------------
# (1) Unit
# ----------------------------------------------------------------------------
if ($runAll -or $Unit) {
    Write-Header 'Unit (.NET)'
    Invoke-DotnetTestProjects 'Unit (.NET)' (Join-Path $repoRoot 'tests/unit')
}

# ----------------------------------------------------------------------------
# (2) Component - needs Docker Desktop
# ----------------------------------------------------------------------------
if ($runAll -or $Component) {
    Write-Header 'Component (.NET)'
    if (-not (Test-DockerRunning)) {
        Write-Host "Docker daemon not reachable - skipping component layer." -ForegroundColor Yellow
        Write-Host "Start Docker Desktop and re-run."                        -ForegroundColor Yellow
        Add-Result 'Component (.NET)' 'SKIP' ([TimeSpan]::Zero) 'Docker not running'
    } else {
        Invoke-DotnetTestProjects 'Component (.NET)' (Join-Path $repoRoot 'tests/component')
    }
}

# ----------------------------------------------------------------------------
# (3) E2E - needs the compose stack up
# ----------------------------------------------------------------------------
if ($runAll -or $E2E) {
    Write-Header 'E2E (.NET)'
    if (-not (Test-DockerRunning)) {
        Write-Host "Docker daemon not reachable - skipping e2e layer." -ForegroundColor Yellow
        Add-Result 'E2E (.NET)' 'SKIP' ([TimeSpan]::Zero) 'Docker not running'
    } elseif (-not (Test-StackRunning)) {
        Write-Host "cyborgsoftware-caddy not running - skipping e2e layer."                  -ForegroundColor Yellow
        Write-Host "Bring the stack up first:"                                   -ForegroundColor Yellow
        Write-Host "    docker compose up -d"         -ForegroundColor Yellow
        Add-Result 'E2E (.NET)' 'SKIP' ([TimeSpan]::Zero) 'stack not running'
    } else {
        Invoke-DotnetTestProjects 'E2E (.NET)' (Join-Path $repoRoot 'tests/e2e')
    }
}

# ----------------------------------------------------------------------------
# (4) Frontend - Vitest via npm
# ----------------------------------------------------------------------------
if ($runAll -or $Frontend) {
    Write-Header 'Frontend (Vitest)'
    $fePath = Join-Path $repoRoot 'containers/frontend'
    if (-not (Test-Path (Join-Path $fePath 'package.json'))) {
        Write-Host "containers/frontend/package.json not found - skipping." -ForegroundColor Yellow
        Add-Result 'Frontend (Vitest)' 'SKIP' ([TimeSpan]::Zero) 'no package.json'
    } else {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        Push-Location $fePath
        $code = 1
        $lintCode = 1
        try {
            & npm test
            $code = $LASTEXITCODE
            # The design system's checks (docs/architecture/design-system.md):
            # a screen built outside src/kit/ fails this layer.
            & npm run lint
            $lintCode = $LASTEXITCODE
        } finally {
            Pop-Location
        }
        $sw.Stop()
        $status = if ($code -eq 0 -and $lintCode -eq 0) { 'PASS' } else { 'FAIL' }
        $note = if ($lintCode -ne 0) { 'design-system lint failed' } else { '' }
        Add-Result 'Frontend (Vitest)' $status $sw.Elapsed $note
    }
}

# ----------------------------------------------------------------------------
# (5) Browser - Playwright against the compose stack
# ----------------------------------------------------------------------------
if ($runAll -or $Browser) {
    Write-Header 'Browser (Playwright)'
    $brPath = Join-Path $repoRoot 'tests/browser'
    if (-not (Test-DockerRunning)) {
        Write-Host "Docker daemon not reachable - skipping browser layer." -ForegroundColor Yellow
        Add-Result 'Browser (Playwright)' 'SKIP' ([TimeSpan]::Zero) 'Docker not running'
    } elseif (-not (Test-StackRunning)) {
        Write-Host "cyborgsoftware-caddy not running - skipping browser layer."   -ForegroundColor Yellow
        Write-Host "Bring the stack up first:"                            -ForegroundColor Yellow
        Write-Host "    docker compose up -d"  -ForegroundColor Yellow
        Add-Result 'Browser (Playwright)' 'SKIP' ([TimeSpan]::Zero) 'stack not running'
    } else {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        Push-Location $brPath
        $code = 1
        try {
            # Three packages; installing them is cheaper than a layer skipped
            # for a missing node_modules and mistaken for a pass.
            if (-not (Test-Path 'node_modules')) { & npm ci }
            & npx playwright test
            $code = $LASTEXITCODE
        } finally {
            Pop-Location
        }
        $sw.Stop()
        $status = if ($code -eq 0) { 'PASS' } else { 'FAIL' }
        Add-Result 'Browser (Playwright)' $status $sw.Elapsed
    }
}

# ----------------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------------
Write-Header 'Summary'

foreach ($r in $results) {
    $color = switch ($r.Status) {
        'PASS'  { 'Green' }
        'FAIL'  { 'Red'   }
        'SKIP'  { 'Yellow'}
        default { 'Magenta' }
    }
    $line = "  {0,-22} {1,-6}" -f $r.Layer, $r.Status
    if ($r.Duration -gt [TimeSpan]::Zero) {
        $line += " ({0,5:N1}s)" -f $r.Duration.TotalSeconds
    } else {
        $line += "         "
    }
    if ($r.Note) { $line += "  - " + $r.Note }
    Write-Host $line -ForegroundColor $color
}

$failed = $results | Where-Object { $_.Status -eq 'FAIL' }
Write-Host ""
if ($failed) {
    $count = $failed.Count
    Write-Host "FAILED: $count layer(s)" -ForegroundColor Red
    exit 1
} else {
    Write-Host "All run layers passed." -ForegroundColor Green
    exit 0
}
