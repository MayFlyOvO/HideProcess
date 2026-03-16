param(
    [Parameter(Position = 0)]
    [string]$Version
)

$ErrorActionPreference = "Stop"

$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$versionPropsPath = Join-Path $rootDir "build\Version.props"
$appProject = Join-Path $rootDir "BossKey.App\BossKey.App.csproj"
$issScript = Join-Path $rootDir "installer\BossKey.iss"

function Get-ReleaseVersion {
    param(
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw "Version file not found: $Path"
    }

    [xml]$xml = Get-Content -Path $Path -Raw
    $value = $xml.Project.PropertyGroup.AppVersion
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "AppVersion was not found in $Path"
    }

    return $value.Trim()
}

function Get-TargetFramework {
    param(
        [string]$ProjectPath
    )

    [xml]$xml = Get-Content -Path $ProjectPath -Raw
    $targetFramework = $xml.Project.PropertyGroup.TargetFramework | Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($targetFramework)) {
        throw "TargetFramework was not found in $ProjectPath"
    }

    return $targetFramework.Trim()
}

if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = Get-ReleaseVersion -Path $versionPropsPath
}

if ($Version -notmatch '^\d+\.\d+\.\d+(\.\d+)?$') {
    throw "Invalid version format: $Version. Use formats like 1.0.0 or 1.0.0.0."
}

$versionParts = $Version.Split('.')
$fileVersion = if ($versionParts.Count -eq 3) { "$Version.0" } else { $Version }
$isReleaseBuild = $Version -eq (Get-ReleaseVersion -Path $versionPropsPath)

$config = "Release"
$rid = "win-x64"

if ($isReleaseBuild) {
    $outRoot = Join-Path $rootDir "artifacts"
    $buildOut = Join-Path $outRoot "build"
    $publishOut = Join-Path $outRoot "publish"
    $singleOut = Join-Path $outRoot "singlefile"
    $singleFrameworkDependentOut = Join-Path $outRoot "singlefile-fd"
    $installerOut = Join-Path $outRoot "installer"
    $outputBaseName = "BossKey-Setup"
}
else {
    $outRoot = Join-Path $rootDir "artifacts\test-builds\$Version"
    $buildOut = Join-Path $outRoot "build"
    $publishOut = Join-Path $outRoot "publish"
    $singleOut = Join-Path $outRoot "singlefile"
    $singleFrameworkDependentOut = Join-Path $outRoot "singlefile-fd"
    $installerOut = Join-Path $outRoot "installer"
    $outputBaseName = "BossKey-Setup-$Version"
}

if (-not (Test-Path $appProject)) {
    throw "Project file not found: $appProject"
}

$targetFramework = Get-TargetFramework -ProjectPath $appProject
$isNetFrameworkTarget = $targetFramework -like "net4*"
$publishSelfContained = if ($isNetFrameworkTarget) { "false" } else { "true" }

Write-Host "[INFO] Version: $Version"
Write-Host "[INFO] TargetFramework: $targetFramework"
Write-Host "[INFO] Stopping running app to avoid file locks..."
Get-Process BossKey.App -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "[INFO] Cleaning output..."
if (Test-Path $buildOut) { Remove-Item $buildOut -Recurse -Force }
if (Test-Path $publishOut) { Remove-Item $publishOut -Recurse -Force }
if (Test-Path $singleOut) { Remove-Item $singleOut -Recurse -Force }
if (Test-Path $singleFrameworkDependentOut) { Remove-Item $singleFrameworkDependentOut -Recurse -Force }
if (Test-Path $installerOut) { Remove-Item $installerOut -Recurse -Force }

function Invoke-Step {
    param(
        [string]$Title,
        [string[]]$Command
    )

    Write-Host $Title
    & $Command[0] $Command[1..($Command.Length - 1)]
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $($Command -join ' ')"
    }
}

$versionArgs = @(
    "-p:AppVersion=$Version",
    "-p:Version=$Version",
    "-p:FileVersion=$fileVersion",
    "-p:AssemblyVersion=$fileVersion",
    "-p:InformationalVersion=$Version"
)
$buildFlags = @(
    "-p:NuGetAudit=false"
)

Invoke-Step "[1/7] Restore..." (@(
    "dotnet", "restore", $appProject
) + $buildFlags)

$buildCommand = @(
    "dotnet", "build", $appProject,
    "-c", $config,
    "-o", $buildOut
) + $versionArgs + $buildFlags
Invoke-Step "[2/7] Build $Version..." $buildCommand

$publishMultiFileCommand = @(
    "dotnet", "publish", $appProject,
    "-c", $config,
    "-r", $rid,
    "--self-contained", $publishSelfContained,
    "-p:PublishSingleFile=false",
    "-p:UpdateChannel=installer",
    "-p:DebugType=None",
    "-p:DebugSymbols=false",
    "-o", $publishOut
) + $versionArgs + $buildFlags
if ($isNetFrameworkTarget) {
    Invoke-Step "[3/7] Publish Multi-File (framework-dependent, $rid)..." $publishMultiFileCommand
}
else {
    Invoke-Step "[3/7] Publish Multi-File (self-contained, $rid)..." $publishMultiFileCommand
}

$singleFileEnabled = -not $isNetFrameworkTarget
$costuraSingleFilePrepared = $false
if ($singleFileEnabled) {
    $publishSingleFileCommand = @(
        "dotnet", "publish", $appProject,
        "-c", $config,
        "-r", $rid,
        "--self-contained", "true",
        "-p:PublishSingleFile=true",
        "-p:IncludeNativeLibrariesForSelfExtract=true",
        "-p:UpdateChannel=singlefile",
        "-p:DebugType=None",
        "-p:DebugSymbols=false",
        "-o", $singleOut
    ) + $versionArgs + $buildFlags
    Invoke-Step "[4/7] Publish Single-File (self-contained, $rid)..." $publishSingleFileCommand

    $singleFileExe = Join-Path $singleOut "BossKey.App.exe"
    if (Test-Path $singleFileExe) {
        Copy-Item $singleFileExe (Join-Path $singleOut "BossKey-SingleFile.exe") -Force
    }

    $publishFrameworkDependentSingleFileCommand = @(
        "dotnet", "publish", $appProject,
        "-c", $config,
        "-r", $rid,
        "--self-contained", "false",
        "-p:PublishSingleFile=true",
        "-p:IncludeNativeLibrariesForSelfExtract=true",
        "-p:UpdateChannel=singlefile",
        "-p:DebugType=None",
        "-p:DebugSymbols=false",
        "-o", $singleFrameworkDependentOut
    ) + $versionArgs + $buildFlags
    Invoke-Step "[5/7] Publish Single-File (framework-dependent, $rid)..." $publishFrameworkDependentSingleFileCommand

    $singleFrameworkDependentFileExe = Join-Path $singleFrameworkDependentOut "BossKey.App.exe"
    if (Test-Path $singleFrameworkDependentFileExe) {
        Copy-Item $singleFrameworkDependentFileExe (Join-Path $singleFrameworkDependentOut "BossKey-SingleFile-FD.exe") -Force
    }
}
else {
    Write-Host "[4/7] Prepare Single-File (Costura, $targetFramework)..."
    $publishedExe = Join-Path $publishOut "BossKey.App.exe"
    $costuraSingleFileExe = Join-Path $singleOut "BossKey-SingleFile.exe"
    New-Item -ItemType Directory -Path $singleOut -Force | Out-Null
    if (Test-Path $publishedExe) {
        Copy-Item $publishedExe $costuraSingleFileExe -Force

        $publishedConfig = Join-Path $publishOut "BossKey.App.exe.config"
        if (Test-Path $publishedConfig) {
            Copy-Item $publishedConfig (Join-Path $singleOut "BossKey-SingleFile.exe.config") -Force
        }

        $costuraSingleFilePrepared = $true
    }
    else {
        Write-Warning "Published executable not found for Costura single-file output: $publishedExe"
    }

    Write-Host "[5/7] Skip Single-File (framework-dependent): handled by Costura weaving for $targetFramework."
}

Write-Host "[6/7] Build Installer (Inno Setup)..."
if (-not (Test-Path $issScript)) {
    Write-Warning "Installer script not found: $issScript"
    Write-Warning "Skipping installer build."
}
elseif (-not (Test-Path (Join-Path $publishOut "BossKey.App.exe"))) {
    Write-Warning "Publish executable not found. Skipping installer build."
}
else {
    $iscc = (Get-Command ISCC.exe -ErrorAction SilentlyContinue).Source
    if (-not $iscc) {
        $isccCandidates = @(
            "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
            "C:\Program Files\Inno Setup 6\ISCC.exe"
        )
        $iscc = $isccCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    }

    if (-not $iscc) {
        Write-Warning "Inno Setup compiler (ISCC.exe) not found. Skipping installer build."
    }
    else {
        New-Item -ItemType Directory -Path $installerOut -Force | Out-Null
        Invoke-Step "    Running ISCC..." @(
            $iscc,
            "/DSourceDir=$publishOut",
            "/DSourceIcon=$(Join-Path $rootDir 'BossKey.App\Assets\BossKey.ico')",
            "/DOutputDir=$installerOut",
            "/DMyAppVersion=$Version",
            "/DOutputBaseName=$outputBaseName",
            $issScript
        )
    }
}

Write-Host "[7/7] Done."
Write-Host ""
Write-Host "Version: $Version"
Write-Host "Build output:"
Write-Host "  $buildOut"
Write-Host ""
Write-Host "Multi-file publish output:"
Write-Host "  $publishOut"
Write-Host ""
if ($singleFileEnabled) {
    Write-Host "Single-file publish output (self-contained):"
    Write-Host "  $(Join-Path $singleOut 'BossKey-SingleFile.exe')"
    Write-Host ""
    Write-Host "Single-file publish output (framework-dependent):"
    Write-Host "  $(Join-Path $singleFrameworkDependentOut 'BossKey-SingleFile-FD.exe')"
}
elseif ($costuraSingleFilePrepared) {
    Write-Host "Single-file publish output (Costura):"
    Write-Host "  $(Join-Path $singleOut 'BossKey-SingleFile.exe')"
    Write-Host "  $(Join-Path $singleOut 'BossKey-SingleFile.exe.config')"
}
else {
    Write-Host "Single-file publish output:"
    Write-Host "  N/A (PublishSingleFile is only supported for netcoreapp targets)"
}
Write-Host ""
Write-Host "Installer output:"
Write-Host "  $installerOut"
