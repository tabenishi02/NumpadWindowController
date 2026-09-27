[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$TaskName = 'NumpadWindowController-Logon',
    [switch]$Preview,
    [switch]$PassThru
)

$ErrorActionPreference = 'Stop'
$TaskPath = '\'

if ($TaskName -notmatch '^NumpadWindowController(?:-[A-Za-z0-9._-]+)?$') {
    throw "TaskName must be NumpadWindowController or start with NumpadWindowController-."
}

$result = [pscustomobject]@{
    TaskName = $TaskName
    TaskPath = $TaskPath
    Status   = if ($Preview) { 'Preview' } else { 'Pending' }
}

if ($Preview) {
    Write-Host "Preview only. No scheduled task was changed."
    Write-Host "Task to remove: $TaskPath$TaskName"
    if ($PassThru) {
        $result
    }
    return
}

Import-Module ScheduledTasks -ErrorAction Stop
$existing = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
if (-not $existing) {
    $result.Status = 'NotFound'
    Write-Host "Startup task is not registered: $TaskPath$TaskName"
    if ($PassThru) {
        $result
    }
    return
}

if ($PSCmdlet.ShouldProcess("$TaskPath$TaskName", 'Unregister startup task')) {
    Unregister-ScheduledTask `
        -TaskName $TaskName `
        -TaskPath $TaskPath `
        -Confirm:$false

    $remaining = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
    if ($remaining) {
        throw "The startup task still exists after removal: $TaskPath$TaskName"
    }

    $result.Status = 'Removed'
    Write-Host "Startup task removed successfully: $TaskPath$TaskName"
    if ($PassThru) {
        $result
    }
}
