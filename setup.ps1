$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$terminalIcon = Join-Path $root "emberRes\eshIcon\icon.png"
$fileIcon     = Join-Path $root "emberRes\eshIcon\esh.ico"
$corePath     = Join-Path $root "emberCore\emberCore.psm1"
$profilePath  = Join-Path $root "emberCore\emberProfile.ps1"

$psExe = $null
if (Get-Command "pwsh" -ErrorAction SilentlyContinue) {
    $psExe = "pwsh.exe"
} elseif (Get-Command "powershell" -ErrorAction SilentlyContinue) {
    $psExe = "powershell.exe"
} else {
    Write-Host "No compatible PowerShell found." -ForegroundColor Red
    Read-Host "Press enter to close"
    exit
}
Write-Host "Using: $psExe" -ForegroundColor Cyan

$hasWT = $false
if (Get-Command "wt" -ErrorAction SilentlyContinue) {
    $hasWT = $true
}

$fso = New-Object -ComObject Scripting.FileSystemObject
$rootShort        = $fso.GetFolder($root).ShortPath
$corePathShort    = Join-Path $rootShort "emberCore\emberCore.psm1"
$profilePathShort = Join-Path $rootShort "emberCore\emberProfile.ps1"

$innerCmd   = 'Import-Module ' + "'" + $corePathShort + "'" + '; . ' + "'" + $profilePathShort + "'"
$launchArgs = '-NoExit -ExecutionPolicy Bypass -Command "' + $innerCmd + '"'
$launchCmd  = $psExe + ' ' + $launchArgs

if ($hasWT) {
    $wtSettings = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (Test-Path $wtSettings) {
        $json = Get-Content $wtSettings -Raw | ConvertFrom-Json
        $wtInnerCmd  = 'Import-Module ' + "'" + $corePath + "'" + '; . ' + "'" + $profilePath + "'"
        $wtLaunchCmd = $psExe + ' -NoExit -ExecutionPolicy Bypass -Command "' + $wtInnerCmd + '"'
        $emberProfile = @{
            name              = "emberShell"
            commandline       = $wtLaunchCmd
            icon              = $terminalIcon
            startingDirectory = $root
        }
        if (-not $json.profiles) {
            $json | Add-Member -MemberType NoteProperty -Name profiles -Value @{ list = @() }
        }
        if (-not $json.profiles.list) {
            $json.profiles | Add-Member -MemberType NoteProperty -Name list -Value @()
        }
        $exists = $json.profiles.list | Where-Object { $_.name -eq "emberShell" }
        if (-not $exists) {
            $json.profiles.list += $emberProfile
        } else {
            $idx = [array]::IndexOf($json.profiles.list, $exists)
            $json.profiles.list[$idx] = $emberProfile
        }
        $json | ConvertTo-Json -Depth 20 | Set-Content $wtSettings -Encoding utf8
        Write-Host "Windows Terminal profile registered." -ForegroundColor Cyan
    } else {
        Write-Host "wt found but settings.json missing - skipping WT profile." -ForegroundColor Yellow
        $hasWT = $false
    }
}


$staleKeys = @(
    "HKCU:\Software\Classes\efasShellScript",
    "HKCU:\Software\Classes\emberShell.Script",
    "HKCU:\Software\Classes\emberShell.Extension"
)
foreach ($key in $staleKeys) {
    if (Test-Path $key) {
        Remove-Item -Path $key -Recurse -Force
        #Write-Host "Removed stale key: $key" -ForegroundColor DarkYellow
    }
}

$eshProgId = "emberShellScript"
New-Item -Path "HKCU:\Software\Classes\.esh" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Classes\.esh" -Name "(Default)" -Value $eshProgId
New-Item -Path "HKCU:\Software\Classes\$eshProgId" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Classes\$eshProgId" -Name "(Default)" -Value "emberShell Script"
New-Item -Path "HKCU:\Software\Classes\$eshProgId\DefaultIcon" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Classes\$eshProgId\DefaultIcon" -Name "(Default)" -Value $fileIcon

$esxProgId = "emberShellExtension"
New-Item -Path "HKCU:\Software\Classes\.esx" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Classes\.esx" -Name "(Default)" -Value $esxProgId
New-Item -Path "HKCU:\Software\Classes\$esxProgId" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Classes\$esxProgId" -Name "(Default)" -Value "emberShell Extension"
New-Item -Path "HKCU:\Software\Classes\$esxProgId\DefaultIcon" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Classes\$esxProgId\DefaultIcon" -Name "(Default)" -Value $fileIcon

<#
Write-Host "ESH: $(Get-ItemPropertyValue "HKCU:\Software\Classes\$eshProgId" "(Default)")" -ForegroundColor Yellow
Write-Host "ESH icon: $(Get-ItemPropertyValue "HKCU:\Software\Classes\$eshProgId\DefaultIcon" "(Default)")" -ForegroundColor Yellow
Write-Host "ESX: $(Get-ItemPropertyValue "HKCU:\Software\Classes\$esxProgId" "(Default)")" -ForegroundColor Yellow
Write-Host "ESX icon: $(Get-ItemPropertyValue "HKCU:\Software\Classes\$esxProgId\DefaultIcon" "(Default)")" -ForegroundColor Yellow
#>
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$root*") {
    [Environment]::SetEnvironmentVariable("PATH", ($currentPath + ";" + $root), "User")
}

$launcher = Join-Path $root "emberShell.bat"
if ($hasWT) {
    $batContent = "@echo off" + [Environment]::NewLine + "wt -p `"emberShell`""
} else {
    $batContent = "@echo off" + [Environment]::NewLine + "start `"`" " + $launchCmd
}
[System.IO.File]::WriteAllText($launcher, $batContent, [System.Text.Encoding]::ASCII)

$iconCache = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Explorer"
Get-ChildItem -Path $iconCache -Filter "iconcache*" | Remove-Item -Force -ErrorAction SilentlyContinue

$code = @'
[System.Runtime.InteropServices.DllImport("shell32.dll")]
public static extern void SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2);
'@
$shell = Add-Type -MemberDefinition $code -Name WinShell -Namespace Win32 -PassThru
$shell::SHChangeNotify(0x08000000, 0x0000, [IntPtr]::Zero, [IntPtr]::Zero)

$termLabel = if ($hasWT) { "Windows Terminal" } else { "standalone window (no wt)" }
Write-Host "emberShell setup complete." -ForegroundColor Green
Write-Host "  Shell:    $psExe" -ForegroundColor DarkCyan
Write-Host "  Terminal: $termLabel" -ForegroundColor DarkCyan
Write-Host "  Root:     $root" -ForegroundColor DarkCyan
Read-Host "Press enter to close"