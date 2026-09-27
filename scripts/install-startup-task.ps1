[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$AutoHotkeyPath,
    [ValidateRange(0, 86400)]
    [int]$DelaySeconds = 0,
    [string]$TaskName = 'NumpadWindowController-Logon',
    [switch]$Preview,
    [switch]$PassThru
)

$ErrorActionPreference = 'Stop'
$TaskPath = '\'

function Assert-NumpadWindowControllerTaskName {
    param([Parameter(Mandatory = $true)][string]$Name)

    if ($Name -notmatch '^NumpadWindowController(?:-[A-Za-z0-9._-]+)?$') {
        throw "TaskName must be NumpadWindowController or start with NumpadWindowController-."
    }
}

function Get-AutoHotkeyMajorVersion {
    param([Parameter(Mandatory = $true)][string]$Path)

    $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($Path)
    $versionText = if ($versionInfo.ProductVersion) {
        $versionInfo.ProductVersion
    } else {
        $versionInfo.FileVersion
    }

    $match = [regex]::Match([string]$versionText, '^\s*(\d+)')
    if (-not $match.Success) {
        throw "Cannot determine the AutoHotkey version: $Path"
    }

    return [int]$match.Groups[1].Value
}

function Resolve-AutoHotkeyV2Path {
    param([string]$RequestedPath)

    $candidates = New-Object System.Collections.Generic.List[string]
    if ($RequestedPath) {
        $candidates.Add($RequestedPath)
    } else {
        if ($env:ProgramFiles) {
            $candidates.Add((Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey64.exe'))
            $candidates.Add((Join-Path $env:ProgramFiles 'AutoHotkey\v2\AutoHotkey.exe'))
            $candidates.Add((Join-Path $env:ProgramFiles 'AutoHotkey\AutoHotkey.exe'))
        }
        if (${env:ProgramFiles(x86)}) {
            $candidates.Add((Join-Path ${env:ProgramFiles(x86)} 'AutoHotkey\v2\AutoHotkey32.exe'))
            $candidates.Add((Join-Path ${env:ProgramFiles(x86)} 'AutoHotkey\v2\AutoHotkey.exe'))
        }

        foreach ($commandName in @('AutoHotkey64.exe', 'AutoHotkey32.exe', 'AutoHotkey.exe')) {
            $command = Get-Command $commandName -CommandType Application -ErrorAction SilentlyContinue |
                Select-Object -First 1
            if ($command) {
                $candidates.Add($command.Source)
            }
        }
    }

    $seen = @{}
    foreach ($candidate in $candidates) {
        if (-not $candidate) {
            continue
        }

        try {
            $resolved = (Resolve-Path -LiteralPath $candidate -ErrorAction Stop).ProviderPath
        } catch {
            continue
        }

        if ($seen.ContainsKey($resolved)) {
            continue
        }
        $seen[$resolved] = $true

        if ((Get-Item -LiteralPath $resolved).PSIsContainer) {
            continue
        }

        if ((Get-AutoHotkeyMajorVersion -Path $resolved) -eq 2) {
            return $resolved
        }
    }

    if ($RequestedPath) {
        throw "AutoHotkey v2 executable was not found at the specified path: $RequestedPath"
    }
    throw 'AutoHotkey v2 executable was not found. Install AutoHotkey v2 or specify -AutoHotkeyPath.'
}

function New-StartupTaskPlan {
    param(
        [Parameter(Mandatory = $true)][string]$ResolvedAutoHotkeyPath,
        [Parameter(Mandatory = $true)][string]$ControllerPath,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [Parameter(Mandatory = $true)][string]$UserId,
        [Parameter(Mandatory = $true)][string]$UserName,
        [Parameter(Mandatory = $true)][int]$Delay
    )

    $delayValue = if ($Delay -gt 0) {
        [System.Xml.XmlConvert]::ToString([TimeSpan]::FromSeconds($Delay))
    } else {
        $null
    }

    [pscustomobject]@{
        TaskName            = $TaskName
        TaskPath            = $TaskPath
        UserId              = $UserId
        UserName            = $UserName
        Trigger             = 'Logon'
        LogonType           = 'InteractiveToken'
        RunLevel            = 'LeastPrivilege'
        DelaySeconds        = $Delay
        Delay               = $delayValue
        Execute             = $ResolvedAutoHotkeyPath
        Arguments           = '"' + $ControllerPath + '"'
        WorkingDirectory    = $WorkingDirectory
        MultipleInstances   = 'IgnoreNew'
        ExecutionTimeLimit  = 'PT0S'
        ControllerPath      = $ControllerPath
    }
}

function Assert-RegisteredTaskMatchesPlan {
    param(
        [Parameter(Mandatory = $true)]$RegisteredTask,
        [Parameter(Mandatory = $true)]$Plan
    )

    $action = @($RegisteredTask.Actions)
    $trigger = @($RegisteredTask.Triggers | Where-Object {
        $_.CimClass.CimClassName -eq 'MSFT_TaskLogonTrigger'
    })

    if ($action.Count -ne 1 -or
        $action[0].Execute -ne $Plan.Execute -or
        $action[0].Arguments -ne $Plan.Arguments -or
        $action[0].WorkingDirectory -ne $Plan.WorkingDirectory) {
        throw 'The registered task action does not match the requested AutoHotkey command.'
    }
    if ($trigger.Count -ne 1) {
        throw 'The registered task does not have exactly one logon trigger.'
    }
    $registeredUserId = [string]$RegisteredTask.Principal.UserId
    if ($registeredUserId -match '^S-\d-(?:\d+-)+\d+$') {
        $registeredSid = $registeredUserId
    } else {
        try {
            $registeredSid = (New-Object System.Security.Principal.NTAccount($registeredUserId)).Translate(
                [System.Security.Principal.SecurityIdentifier]
            ).Value
        } catch {
            throw "Cannot resolve the registered task principal: $registeredUserId"
        }
    }
    if ($registeredSid -ne $Plan.UserId) {
        throw 'The registered task principal does not match the current user.'
    }
}

Assert-NumpadWindowControllerTaskName -Name $TaskName

$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$controllerPath = Join-Path $repositoryRoot 'NumpadWindowController.ahk'
if (-not (Test-Path -LiteralPath $controllerPath -PathType Leaf)) {
    throw "Controller script was not found: $controllerPath"
}

$resolvedAutoHotkeyPath = Resolve-AutoHotkeyV2Path -RequestedPath $AutoHotkeyPath
$currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$currentUser = $currentIdentity.Name
$currentUserSid = $currentIdentity.User.Value
$plan = New-StartupTaskPlan `
    -ResolvedAutoHotkeyPath $resolvedAutoHotkeyPath `
    -ControllerPath $controllerPath `
    -WorkingDirectory $repositoryRoot `
    -UserId $currentUserSid `
    -UserName $currentUser `
    -Delay $DelaySeconds

if ($Preview) {
    Write-Host "Preview only. No scheduled task was changed."
    Write-Host "Task: $TaskPath$TaskName"
    Write-Host "User logon: $currentUser"
    Write-Host "AutoHotkey v2: $resolvedAutoHotkeyPath"
    Write-Host "Controller: $controllerPath"
    Write-Host "Working directory: $repositoryRoot"
    Write-Host "Delay: $DelaySeconds second(s)"
    if ($PassThru) {
        $plan
    }
    return
}

Import-Module ScheduledTasks -ErrorAction Stop

$action = New-ScheduledTaskAction `
    -Execute $plan.Execute `
    -Argument $plan.Arguments `
    -WorkingDirectory $plan.WorkingDirectory
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $plan.UserId
if ($plan.Delay) {
    $trigger.Delay = $plan.Delay
}
$principal = New-ScheduledTaskPrincipal `
    -UserId $plan.UserId `
    -LogonType Interactive `
    -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit ([TimeSpan]::Zero) `
    -MultipleInstances IgnoreNew
$definition = New-ScheduledTask `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description 'Starts NumpadWindowController in the interactive desktop session when this user logs on.'

$existing = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
$verb = if ($existing) { 'Update' } else { 'Register' }
if ($PSCmdlet.ShouldProcess("$TaskPath$TaskName", "$verb logon startup task")) {
    Register-ScheduledTask `
        -TaskName $TaskName `
        -TaskPath $TaskPath `
        -InputObject $definition `
        -Force | Out-Null

    $registered = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction Stop
    Assert-RegisteredTaskMatchesPlan -RegisteredTask $registered -Plan $plan

    Write-Host "Startup task registered successfully: $TaskPath$TaskName"
    Write-Host "It will start NumpadWindowController when $currentUser logs on."
    Write-Host "Run level: standard user (least privilege)"
    Write-Host "Delay: $DelaySeconds second(s)"

    if ($PassThru) {
        $plan
    }
}
