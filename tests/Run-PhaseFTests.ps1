param(
    [string]$AutoHotkeyPath = "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe",
    [switch]$Desktop
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $AutoHotkeyPath -PathType Leaf)) {
    throw 'AutoHotkey v2 executable not found. Specify -AutoHotkeyPath.'
}
$testScript = Join-Path $PSScriptRoot 'PhaseF.Tests.ahk'
$outputBase = Join-Path ([IO.Path]::GetTempPath()) ('nwc-tests-' + [guid]::NewGuid().ToString('N'))
$stdoutPath = "$outputBase.stdout"
$stderrPath = "$outputBase.stderr"
try {
    $testArguments = '/ErrorStdOut "' + $testScript + '"'
    if ($Desktop) { $testArguments += ' --desktop' }
    $testProcess = Start-Process -FilePath $AutoHotkeyPath -ArgumentList $testArguments `
        -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
    Get-Content -LiteralPath $stdoutPath
    Get-Content -LiteralPath $stderrPath
    if ($testProcess.ExitCode -ne 0) {
        throw "Phase F tests failed with exit code $($testProcess.ExitCode)."
    }
} finally {
    foreach ($outputPath in @($stdoutPath, $stderrPath)) {
        if (Test-Path -LiteralPath $outputPath) {
            Remove-Item -LiteralPath $outputPath
        }
    }
}
