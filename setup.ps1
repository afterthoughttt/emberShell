param(
    [switch]$o
)
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$terminalIcon = Join-Path $root "emberRes\eshIcon\icon.png"
$fileIcon     = Join-Path $root "emberRes\eshIcon\esh.ico"
$corePath     = Join-Path $root "emberCore\emberCore.psm1"
$profilePath  = Join-Path $root "emberCore\emberProfile.ps1"

function confirm($content, $y, $n, $default) {
	write-host "$content`n[$y/$n]"
	$answer = read-host
	if ($answer -eq $y) {
		return $true
	} elseif ($answer -eq $n) {
		return $false
	} else {
		return $default
	}
}
if ($IsMacOS) {
	write-host "This Installer is Intended for Windows. you should not run it on MacOS." -fo r
	write-host "Launching lnxsetup.ps1..." -fo r
	. (join-path $root "lnxsetup.ps1")
} elseif ($IsLinux) {
	write-host "This Installer is Intended for Windows. you should not run it on Linux." -fo r
	write-host "Launching lnxsetup.ps1..." -fo r
	. (join-path $root "lnxsetup.ps1")
}

if ($o) {
	if(-not (get-command "pwsh" -ErrorAction SilentlyContinue)) {
		$instpwsh = $(confirm "Update PowerShell?" "Y" "n" $true)
	}
	if(-not (get-command "wt" -ErrorAction SilentlyContinue)) {
		$instwt = $(confirm "Install Windows Terminal?" "Y" "n" $true)
	}
	if(test-path (join-path $root "setup.sh")) {
		$plf = $(confirm "Delete Linux specific Files?" "y" "N" $false)
	}
	$useps1 = $(confirm "Create .ps1 launcher? (recommended over .bat)" "y" "N" $false)
}

if(-not (get-command "pwsh" -ErrorAction SilentlyContinue) -and ("--update-pwsh" -or "--update-powershell") -in $args) {
	winget install Microsoft.PowerShell
} elseif($instpwsh) {
	if(-not (get-command "pwsh" -ErrorAction SilentlyContinue)) {
		winget install Microsoft.PowerShell
	} else {
		write-host "PowerShell is already on the Latest Version." -ForegroundColor Red
	}
}

if(-not (get-command "wt" -ErrorAction SilentlyContinue) -and "--install-wt" -in $args) {
	winget install Microsoft.WindowsTerminal
} elseif($instwt) {
	if(-not (get-command "wt" -ErrorAction SilentlyContinue)) {
		winget install Microsoft.WindowsTerminal
	} else {
		write-host "Windows Terminal is already Installed." -ForegroundColor Red
	}
}

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

if ($useps1) {
    $ps1Content = @"
# launcher for eSh
if (!(gcm pwsh -ea silentlycontinue)) {
	if (gcm pwsh-preview -ea silentlycontinue) {
		sal pwsh pwsh-preview
	} elseif (gcm powershell -ea silentlycontinue) {
		sal pwsh powershell
	} else {
		function script:pwsh {
			if (test-path "`$env:PROGRAMFILES/PowerShell/*/pwsh.exe") { # check if ANY progfiles/powershell exists
				saps (gi "`$env:PROGRAMFILES/PowerShell/*/pwsh.exe" | sort { [version]`$_.Directory.Name } -desc | select -first 1 -exp FullName) @args # prefer the newest one
			} elseif (test-path "`$env:LOCALAPPDATA/PowerShell/*/pwsh.exe") { # check if ANY appdata/powershell exists
				saps (gi "`$env:LOCALAPPDATA/PowerShell/*/pwsh.exe" | sort { [version]`$_.Directory.Name } -desc | select -first 1 -exp FullName) @args # prefer the newest one
			} elseif (test-path "`$env:LOCALAPPDATA/Microsoft/WindowsApps/pwsh.exe") { # check if ANY MSIX or MSStore powershell exists
				saps "`$env:LOCALAPPDATA/Microsoft/WindowsApps/pwsh.exe" @args
			} elseif (test-path "`$env:WINDIR/System32/WindowsPowerShell/v1.0/powershell.exe") {
				saps "`$env:WINDIR/System32/WindowsPowerShell/v1.0/powershell.exe" @args
			} else {
				write-host "your powershell is not stored in any clean directory.``nplease add it to PATH.``npress enter to exit." -f r
				read-host
				exit
			}
		}
	}
}

pwsh -NoExit -ExecutionPolicy Bypass -Command "clear; Import-Module '$corePath'; . '$profilePath'"
"@
    [System.IO.File]::WriteAllText((Join-Path $root "emberShell.ps1"), $ps1Content, [System.Text.Encoding]::UTF8)
    Write-Host "PS1 launcher created." -ForegroundColor Cyan
}

$iconCache = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Explorer"
Get-ChildItem -Path $iconCache -Filter "iconcache*" | Remove-Item -Force -ErrorAction SilentlyContinue

$code = @'
[System.Runtime.InteropServices.DllImport("shell32.dll")]
public static extern void SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2);
'@
$shell = Add-Type -MemberDefinition $code -Name WinShell -Namespace Win32 -PassThru
$shell::SHChangeNotify(0x08000000, 0x0000, [IntPtr]::Zero, [IntPtr]::Zero)

if(test-path (join-path $root "lnxsetup.ps1")) {
	if("--preserve-linux-files" -notin $args -and (-not $plf)) {
		rm (join-path $root "lnxsetup.ps1")
	}
}

$launcherLabel = if ($useps1) { "emberShell.bat + emberShell.ps1" } else { "emberShell.bat" }
$termLabel = if ($hasWT) { "Windows Terminal" } else { "standalone window (no wt)" }
Write-Host "emberShell setup complete." -ForegroundColor Green
Write-Host "  Shell:    $psExe" -ForegroundColor DarkCyan
Write-Host "  Terminal: $termLabel" -ForegroundColor DarkCyan
Write-Host "  Launcher: $launcherLabel" -ForegroundColor DarkCyan
Write-Host "  Root:     $root" -ForegroundColor DarkCyan
Read-Host "Press enter to close"