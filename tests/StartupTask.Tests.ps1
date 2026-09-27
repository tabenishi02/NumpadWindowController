[CmdletBinding()]
param(
    [string]$AutoHotkeyPath = "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe",
    [switch]$Integration
)

$ErrorActionPreference = 'Stop'
$script:AssertionCount = 0

function Assert-Equal {
    param($Actual, $Expected, [string]$Name)

    if ($Actual -ne $Expected) {
        throw "$Name`nExpected: $Expected`nActual:   $Actual"
    }
    $script:AssertionCount++
}

function Assert-True {
    param([bool]$Condition, [string]$Name)

    if (-not $Condition) {
        throw $Name
    }
    $script:AssertionCount++
}

function Get-TaskXmlValue {
    param([xml]$Xml, [string]$XPath)

    $namespace = New-Object System.Xml.XmlNamespaceManager($Xml.NameTable)
    $namespace.AddNamespace('t', 'http://schemas.microsoft.com/windows/2004/02/mit/task')
    return $Xml.SelectSingleNode($XPath, $namespace).InnerText
}

function ConvertTo-SidValue {
    param([Parameter(Mandatory = $true)][string]$Identity)

    if ($Identity -match '^S-\d-(?:\d+-)+\d+$') {
        return $Identity
    }
    return (New-Object System.Security.Principal.NTAccount($Identity)).Translate(
        [System.Security.Principal.SecurityIdentifier]
    ).Value
}

$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$installScript = Join-Path $repositoryRoot 'scripts\install-startup-task.ps1'
$uninstallScript = Join-Path $repositoryRoot 'scripts\uninstall-startup-task.ps1'

Assert-True (Test-Path -LiteralPath $installScript -PathType Leaf) 'Install script exists'
Assert-True (Test-Path -LiteralPath $uninstallScript -PathType Leaf) 'Uninstall script exists'

$preview = & $installScript -AutoHotkeyPath $AutoHotkeyPath -Preview -PassThru
Assert-Equal $preview.TaskName 'NumpadWindowController-Logon' 'Default task name'
Assert-Equal $preview.TaskPath '\' 'Task path is exact root path'
Assert-Equal $preview.Trigger 'Logon' 'Trigger type'
Assert-Equal $preview.LogonType 'InteractiveToken' 'Interactive-only logon type'
Assert-Equal $preview.RunLevel 'LeastPrivilege' 'Standard-user run level'
Assert-Equal $preview.UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value) 'Current user SID'
Assert-Equal $preview.DelaySeconds 0 'Default delay'
Assert-Equal $preview.Execute (Resolve-Path -LiteralPath $AutoHotkeyPath).ProviderPath 'AutoHotkey executable'
Assert-Equal $preview.ControllerPath (Join-Path $repositoryRoot 'NumpadWindowController.ahk') 'Controller path'
Assert-Equal $preview.Arguments ('"' + $preview.ControllerPath + '"') 'Quoted controller argument'
Assert-Equal $preview.WorkingDirectory $repositoryRoot 'Working directory'
Assert-Equal $preview.MultipleInstances 'IgnoreNew' 'Task-level duplicate prevention'
Assert-Equal $preview.ExecutionTimeLimit 'PT0S' 'Unlimited controller runtime'

$delayed = & $installScript -AutoHotkeyPath $AutoHotkeyPath -DelaySeconds 45 -Preview -PassThru
Assert-Equal $delayed.DelaySeconds 45 'Optional delay seconds'
Assert-Equal $delayed.Delay 'PT45S' 'Optional delay serialization'

$uninstallPreview = & $uninstallScript -Preview -PassThru
Assert-Equal $uninstallPreview.TaskName 'NumpadWindowController-Logon' 'Uninstall exact task name'
Assert-Equal $uninstallPreview.TaskPath '\' 'Uninstall exact task path'
Assert-Equal $uninstallPreview.Status 'Preview' 'Uninstall preview is non-mutating'

$missingAutoHotkeyRejected = $false
try {
    & $installScript -AutoHotkeyPath (Join-Path $env:TEMP 'missing-autohotkey-v2.exe') -Preview | Out-Null
} catch {
    $missingAutoHotkeyRejected = $true
}
Assert-True $missingAutoHotkeyRejected 'Missing explicit AutoHotkey path is rejected'

$wrongVersionRejected = $false
try {
    & $installScript -AutoHotkeyPath "$env:WINDIR\System32\cmd.exe" -Preview | Out-Null
} catch {
    $wrongVersionRejected = $true
}
Assert-True $wrongVersionRejected 'Non-v2 executable is rejected'

$spaceRoot = Join-Path ([IO.Path]::GetTempPath()) ('NWC startup path with spaces ' + [guid]::NewGuid().ToString('N'))
try {
    $spaceScripts = Join-Path $spaceRoot 'scripts'
    New-Item -ItemType Directory -Path $spaceScripts -Force | Out-Null
    Copy-Item -LiteralPath $installScript -Destination $spaceScripts
    Set-Content -LiteralPath (Join-Path $spaceRoot 'NumpadWindowController.ahk') -Value '#Requires AutoHotkey v2.0' -Encoding UTF8

    $spacePreview = & (Join-Path $spaceScripts 'install-startup-task.ps1') `
        -AutoHotkeyPath $AutoHotkeyPath `
        -Preview `
        -PassThru
    Assert-Equal $spacePreview.WorkingDirectory $spaceRoot 'Working directory with spaces'
    Assert-Equal $spacePreview.Arguments ('"' + (Join-Path $spaceRoot 'NumpadWindowController.ahk') + '"') 'Quoted script path with spaces'
} finally {
    if (Test-Path -LiteralPath $spaceRoot) {
        Remove-Item -LiteralPath $spaceRoot -Recurse -Force
    }
}

if ($Integration) {
    Import-Module ScheduledTasks -ErrorAction Stop
    $integrationTaskName = 'NumpadWindowController-Test-' + $PID
    $neighborTaskName = 'NumpadWindowController-Test-Neighbor-' + $PID
    try {
        & $installScript `
            -AutoHotkeyPath $AutoHotkeyPath `
            -TaskName $integrationTaskName | Out-Null
        & $installScript `
            -AutoHotkeyPath $AutoHotkeyPath `
            -TaskName $neighborTaskName `
            -DelaySeconds 45 | Out-Null

        $task = Get-ScheduledTask -TaskName $integrationTaskName -TaskPath '\' -ErrorAction Stop
        [xml]$taskXml = Export-ScheduledTask -TaskName $integrationTaskName -TaskPath '\'
        $registeredTriggerUser = Get-TaskXmlValue $taskXml '/t:Task/t:Triggers/t:LogonTrigger/t:UserId'
        Assert-Equal (ConvertTo-SidValue $registeredTriggerUser) ([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value) 'Registered logon user'
        Assert-Equal (Get-TaskXmlValue $taskXml '/t:Task/t:Principals/t:Principal/t:LogonType') 'InteractiveToken' 'Registered interactive token'
        $registeredRunLevel = Get-TaskXmlValue $taskXml '/t:Task/t:Principals/t:Principal/t:RunLevel'
        Assert-True ([string]::IsNullOrWhiteSpace($registeredRunLevel) -or $registeredRunLevel.Trim() -eq 'LeastPrivilege') 'Registered task must not request highest privileges'
        Assert-Equal (Get-TaskXmlValue $taskXml '/t:Task/t:Actions/t:Exec/t:Command') $preview.Execute 'Registered AutoHotkey executable'
        Assert-Equal (Get-TaskXmlValue $taskXml '/t:Task/t:Actions/t:Exec/t:Arguments') $preview.Arguments 'Registered controller argument'
        Assert-Equal (Get-TaskXmlValue $taskXml '/t:Task/t:Actions/t:Exec/t:WorkingDirectory') $preview.WorkingDirectory 'Registered working directory'
        Assert-Equal (Get-TaskXmlValue $taskXml '/t:Task/t:Settings/t:MultipleInstancesPolicy') 'IgnoreNew' 'Registered multiple instance policy'
        Assert-Equal (Get-TaskXmlValue $taskXml '/t:Task/t:Settings/t:ExecutionTimeLimit') 'PT0S' 'Registered unlimited execution time'
        Assert-True ([string]::IsNullOrWhiteSpace((Get-TaskXmlValue $taskXml '/t:Task/t:Triggers/t:LogonTrigger/t:Delay'))) 'Registered default has no delay'

        & $uninstallScript -TaskName $integrationTaskName | Out-Null
        Assert-True (-not (Get-ScheduledTask -TaskName $integrationTaskName -TaskPath '\' -ErrorAction SilentlyContinue)) 'Integration task removed'
        Assert-True ([bool](Get-ScheduledTask -TaskName $neighborTaskName -TaskPath '\' -ErrorAction Stop)) 'Uninstall leaves other NumpadWindowController task untouched'
        [xml]$neighborXml = Export-ScheduledTask -TaskName $neighborTaskName -TaskPath '\'
        Assert-Equal (Get-TaskXmlValue $neighborXml '/t:Task/t:Triggers/t:LogonTrigger/t:Delay') 'PT45S' 'Registered optional logon delay'
        & $uninstallScript -TaskName $integrationTaskName | Out-Null
        Assert-True (-not (Get-ScheduledTask -TaskName $integrationTaskName -TaskPath '\' -ErrorAction SilentlyContinue)) 'Second uninstall is safe'
        & $uninstallScript -TaskName $neighborTaskName | Out-Null
    } finally {
        foreach ($testTaskName in @($integrationTaskName, $neighborTaskName)) {
            $leftover = Get-ScheduledTask -TaskName $testTaskName -TaskPath '\' -ErrorAction SilentlyContinue
            if ($leftover) {
                Unregister-ScheduledTask -TaskName $testTaskName -TaskPath '\' -Confirm:$false
            }
        }
    }
}

Write-Output "PASS $script:AssertionCount startup-task assertions"
