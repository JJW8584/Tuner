param(
    [ValidateSet('debug', 'release')]
    [string]$Mode = 'debug'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location -LiteralPath $projectRoot
try {
    & flutter build apk "--$Mode"
    if ($LASTEXITCODE -ne 0) { throw "Android $Mode build failed." }
    $apkDirectory = Join-Path $projectRoot 'build/app/outputs/flutter-apk'
    $source = Join-Path $apkDirectory "app-$Mode.apk"
    $target = Join-Path $apkDirectory 'Tuner.apk'
    Copy-Item -LiteralPath $source -Destination $target -Force
    Write-Output "APK: $target"
} finally {
    Pop-Location
}
