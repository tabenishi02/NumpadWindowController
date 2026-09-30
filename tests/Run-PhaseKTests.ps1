param(
    [string]$AutoHotkeyPath = "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe"
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $AutoHotkeyPath -PathType Leaf)) {
    throw 'AutoHotkey v2 executable not found. Specify -AutoHotkeyPath.'
}

$testScript = Join-Path $PSScriptRoot 'PhaseK.Tests.ahk'
$outputBase = Join-Path ([IO.Path]::GetTempPath()) ('nwc-phase-k-' + [guid]::NewGuid().ToString('N'))
$stdoutPath = "$outputBase.stdout"
$stderrPath = "$outputBase.stderr"

try {
    $testArguments = '/ErrorStdOut "' + $testScript + '"'
    $testProcess = Start-Process -FilePath $AutoHotkeyPath -ArgumentList $testArguments `
        -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
    Get-Content -LiteralPath $stdoutPath
    Get-Content -LiteralPath $stderrPath
    if ($testProcess.ExitCode -ne 0) {
        throw "Phase K tests failed with exit code $($testProcess.ExitCode)."
    }
} finally {
    foreach ($outputPath in @($stdoutPath, $stderrPath)) {
        if (Test-Path -LiteralPath $outputPath) {
            Remove-Item -LiteralPath $outputPath
        }
    }
}
