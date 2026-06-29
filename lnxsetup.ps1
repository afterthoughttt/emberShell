## LNXeSh Installer ##

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($IsWindows) {
	write-host "This Installer is Intended for Linux. you should not run it on Windows." -fo r
	write-host "Launching setup.ps1..."
	. (join-path $root "setup.ps1")
} elseif ($PSVersionTable.PSVersion.Major -lt 6) {
	write-host "This Installer is Intended for Linux. you should not run it on Windows." -fo r
	write-host "Launching setup.ps1..."
	. (join-path $root "setup.ps1")
}

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
	write-host "This Installer is Intended for Linux.`nIt May run on MacOS, but it is untested."
	$cont = confirm "Continue anyways?" "y" "N" 0
	if (!$cont) {
		return
	}
} # PR if this is an issue to you!

$pmngr = $null

if(get-command apt -ErrorAction SilentlyContinue) {
	$pmngr = "apt"
} elseif (get-command pacman -ErrorAction SilentlyContinue) {
	$pmngr = "pacman"
} elseif (get-command apk -ErrorAction SilentlyContinue) {
	$pmngr = "apk"
} elseif (get-command dnf -ErrorAction SilentlyContinue) {
	$pmngr = "dnf"
} elseif (get-command zypper -ErrorAction SilentlyContinue) {
	$pmngr = "zypper"
} elseif (get-command yay -ErrorAction SilentlyContinue) {
	$pmngr = "yay"
} elseif (gcm xbps-install -ea si) {
	$pmngr = "xbps"
}else {
	write-host "Couldn't find a supported Package Manager." -ForegroundColor Red # this will probably bork it for mac
	write-host "Press Enter to Exit"
	read-host
	exit 2
}

function cpkg($package) { # this is a MINIMAL cpkg wrapper. do not rely on this in eSh
	if ($pmngr -eq "apt") {
		if ($useSudo) {
			sudo apt install -y $package
		} else {
			apt install -y $package
		}
	} elseif ($pmngr -eq "pacman") {
		if ($useSudo) {
			sudo pacman -S --noconfirm $package
		} else {
			pacman -S --noconfirm $package
		}
	} elseif ($pmngr -eq "dnf") {
		if ($useSudo) {
			sudo dnf install -y $package
		} else {
			dnf install -y $package
		}
	} elseif ($pmngr -eq "apk") {
		if ($useSudo) {
			sudo apk add --no-cache $package
		} else {
			apk add --no-cache $package
		}
	} elseif ($pmngr -eq "zypper") {
		if ($useSudo) {
			sudo zypper --non-interactive install $package
		} else {
			zypper --non-interactive install $package
		}
	} elseif ($pmngr -eq "yay") {
		if ($useSudo) {
			sudo yay -S --noconfirm $package
		} else {
			yay -S --noconfirm $package
		}
	} elseif ($pmngr -eq "xbps") {
		if ($useSudo) {
			sudo xbps-install -S $package
		} else {
			xbps-install -S $package
		}
	}
}

$instPkgs = $(confirm "Do you want to Install Packages through setup?" "Y" "n" $true)
if ($instPkgs) {
	if ([int](& id -u) -eq 0) {
		$useSudo = $false
	} elseif (get-command sudo -ErrorAction SilentlyContinue) {
		$useSudo = $(confirm "Allow Sudo Installs?" "Y" "n" $true)
		if (-not $useSudo) {
			write-host "Package Installs are likely to fail." -ForegroundColor Red
			write-host "Press Enter to Exit. (Code:1)"
			read-host
			exit 1
		}
	} else {
		$instSudo = $(confirm "Sudo is not installed, and you are not root. Install and Use Sudo?" "Y" "n" $true)
		if ($instSudo) {
			cpkg "sudo"
			if (-not (get-command sudo -ErrorAction SilentlyContinue)) {
				write-host "Failed to Install Sudo." -ForegroundColor Red
				write-host "Press Enter to Exit. (Code:2)"
				read-host
				exit 1
			}
			$useSudo = $true
		} else {
			write-host "Package Installs are likely to fail." -ForegroundColor Red
			write-host "Press Enter to Exit. (Code:1)"
			read-host
			exit 1
		}
	}
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

function crm($path, [switch]$recurse) {
	if ($recurse) {
		if (test-path (join-path $root "$path") -ErrorAction SilentlyContinue) {
			Remove-Item (join-path $root "$path") -Recurse -Force
			write-output "Deleted emberShell/$path"
		} else {
			write-output "Couldn't find emberShell/$path; Skipping..."
		}
	} else {
		if (test-path (join-path $root "$path") -ErrorAction SilentlyContinue) {
			Remove-Item (join-path $root "$path") -Force
			write-output "Deleted emberShell/$path"
		} else {
			write-output "Couldn't find emberShell/$path; Skipping..."
		}
	}
}

if ($instPkgs) {
	if (-not (get-command lscpu -ErrorAction SilentlyContinue) -or -not (get-command lsblk -ErrorAction SilentlyContinue)) {
		$instUL = confirm "Install util-linux?" "Y" "n" $true
		if ($instUL) {
			cpkg "util-linux"
		}
	}
	if (-not (get-command lspci -ErrorAction SilentlyContinue)) {
		$instPU = confirm "Install pciutils?" "Y" "n" $true
		if ($instPU) {
			cpkg "pciutils"
		}
	}
	if (-not (get-command nproc -ErrorAction SilentlyContinue)) {
		$instCU = confirm "Install coreutils?" "Y" "n" $true
		if ($instCU) {
			cpkg "coreutils"
		}
	}
	if (-not (get-command dmidecode -ErrorAction SilentlyContinue)) {
		$instDD = confirm "Install dmidecode?" "Y" "n" $true
		if ($instDD) {
			cpkg "dmidecode"
		}
	}
}
Get-ChildItem $root -Recurse -Include "desktop.ini","Thumbs.db" | Remove-Item -Force
write-host "Deleted Windows Litter"
$delWF = confirm "Delete Redundant files?" "Y" "n" $true
if ($delWF) {
	crm "setup.ps1"
	crm "emberShell.bat"
	crm "test.esh"
	crm ".gitignore"
	crm ".gitattributes"
	crm "emberRes/eshIcon/icon_old.png"
	crm "emberRes/eshIcon/esh_old.ico"
	crm "emberRes/eshIcon/esh.ico"
}
$delDoc = confirm "Delete Documentation?" "y" "N" $false
if ($delDoc) {
	crm "README.txt"
	crm "Documentation" -recurse
	# crm "emberCore/idocs" -recurse # DO NOT!!! THIS WILL MAKE eSh CRASH!!
}

$corePath    = Join-Path $root "emberCore/emberCore.psm1"
$profilePath = Join-Path $root "emberCore/emberProfile.ps1"
$iconPath    = Join-Path $root "emberRes/eshIcon/icon.png"
$innerCmd    = "Import-Module '$corePath'; . '$profilePath'"

$knownTerminals = @(
	@{ cmd = "kitty";          args = "pwsh" },
	@{ cmd = "alacritty";      args = "-e pwsh" },
	@{ cmd = "foot";           args = "pwsh" },
	@{ cmd = "wezterm";        args = "start -- pwsh" },
	@{ cmd = "gnome-terminal"; args = "-- pwsh" },
	@{ cmd = "konsole";        args = "-e pwsh" },
	@{ cmd = "xfce4-terminal"; args = "-e pwsh" },
	@{ cmd = "lxterminal";     args = "-e pwsh" },
	@{ cmd = "tilix";          args = "-e pwsh" },
	@{ cmd = "terminator";     args = "-e pwsh" },
	@{ cmd = "xterm";          args = "-e pwsh" },
	@{ cmd = "rxvt";           args = "-e pwsh" },
	@{ cmd = "urxvt";          args = "-e pwsh" }
)

$detectedTerminal = $null
$detectedArgs     = $null

foreach ($t in $knownTerminals) {
	if (Get-Command $t.cmd -ErrorAction SilentlyContinue) {
		$detectedTerminal = $t.cmd
		$detectedArgs     = $t.args
		break
	}
}

if (-not $detectedTerminal -and $env:TERM_PROGRAM) {
	$detectedTerminal = $env:TERM_PROGRAM.ToLower()
	$detectedArgs     = "pwsh"
}

if ($detectedTerminal) {
	Write-Host "Detected terminal: $detectedTerminal" -ForegroundColor Cyan
} else {
	Write-Host "No known terminal detected. Falling back to xterm." -ForegroundColor Yellow
	$detectedTerminal = "xterm"
	$detectedArgs     = "-e pwsh"
}

$launcherPath = Join-Path $root "emberShell.sh"
$shContent    = "sh`npwsh -NoExit -ExecutionPolicy Bypass -Command `"$innerCmd`""

[System.IO.File]::WriteAllText($launcherPath, $shContent, [System.Text.Encoding]::UTF8)
& chmod +x $launcherPath
Write-Host "Launcher written: $launcherPath" -ForegroundColor Cyan

$desktopDir  = Join-Path $env:HOME ".local/share/applications"
$desktopPath = Join-Path $desktopDir "embershell.desktop"

if (-not (Test-Path $desktopDir)) {
	New-Item -ItemType Directory -Path $desktopDir -Force | Out-Null
}

$desktopExec    = "$detectedTerminal $detectedArgs -NoExit -ExecutionPolicy Bypass -Command `"$innerCmd`""
$desktopContent = @"
[Desktop Entry]
Version=1.0
Type=Application
Name=emberShell
Comment=emberShell - pwsh environment
Exec=$desktopExec
Icon=$iconPath
Terminal=false
Categories=System;TerminalEmulator;
"@

[System.IO.File]::WriteAllText($desktopPath, $desktopContent, [System.Text.Encoding]::UTF8)
Write-Host ".desktop entry written: $desktopPath" -ForegroundColor Cyan

$mimeDir  = Join-Path $env:HOME ".local/share/mime/packages"
$mimePath = Join-Path $mimeDir "embershell.xml"

if (-not (Test-Path $mimeDir)) {
	New-Item -ItemType Directory -Path $mimeDir -Force | Out-Null
}

$mimeContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-embershell-script">
    <comment>emberShell Script</comment>
    <glob pattern="*.esh"/>
  </mime-type>
  <mime-type type="application/x-embershell-extension">
    <comment>emberShell Extension</comment>
    <glob pattern="*.esx"/>
  </mime-type>
</mime-info>
"@

[System.IO.File]::WriteAllText($mimePath, $mimeContent, [System.Text.Encoding]::UTF8)
& update-mime-database (Join-Path $env:HOME ".local/share/mime") 2>$null
& xdg-mime default embershell.desktop application/x-embershell-script 2>$null
& xdg-mime default embershell.desktop application/x-embershell-extension 2>$null
Write-Host "MIME types registered (.esh, .esx)" -ForegroundColor Cyan

$pathLine = "`nexport PATH=`"`$PATH:$root`""

$rcFiles = @(
	(Join-Path $env:HOME ".profile"),
	(Join-Path $env:HOME ".bashrc"),
	(Join-Path $env:HOME ".zshrc"),
	(Join-Path $env:HOME ".kshrc")
)

foreach ($rc in $rcFiles) {
	if (Test-Path $rc) {
		$content = Get-Content $rc -Raw
		if ($content -notlike "*$root*") {
			Add-Content -Path $rc -Value $pathLine
			Write-Host "  PATH added to: $rc" -ForegroundColor DarkCyan
		} else {
			Write-Host "  Already in PATH: $rc" -ForegroundColor DarkGray
		}
	}
}

Write-Host ""
Write-Host "emberShell setup complete." -ForegroundColor Green
Write-Host "  Terminal: $detectedTerminal" -ForegroundColor DarkCyan
Write-Host "  Root:     $root" -ForegroundColor DarkCyan
Write-Host "  Launcher: $launcherPath" -ForegroundColor DarkCyan
Write-Host "  Desktop:  $desktopPath" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "Note: PATH changes take effect in new shell sessions." -ForegroundColor Yellow
Read-Host "Press Enter to close"