$emberRoot = Split-Path -Parent $PSScriptRoot
$Host.UI.RawUI.WindowTitle = "emberShell"
$config = Get-Content (Join-Path $emberRoot "emberCore\emberConfig.json") -Raw | ConvertFrom-Json
$shell  = Get-Content (Join-Path $emberRoot "emberCore\emberShell.json")  -Raw | ConvertFrom-Json
$ESVersionTable = @{
	ESVersion = "$($shell.shell_version)"
	ESEdition = "$($shell.sv_name)"
	clibVersion = "$($shell.clib_version)"
}
if ($config.show_esh_Version) {
	$esc = [char]0x1b
	# this redacts the shell lol /// write-output "${esc}[38;2;231;136;214m${esc}[48;2;231;136;214m"
    Write-Host "$($shell.shell_name) $($shell.shell_version)" -ForegroundColor DarkGray
}

if ($config.show_pwsh_Version) {
    Write-Host "PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor DarkGray
}

if ($config.show_clib_Version) {
	if ($config.clib_compat) {
		Write-Host "clib compat $($shell.clib_version)" -ForegroundColor DarkGray
	} else {
		Write-Host "clib $($shell.clib_version)" -ForegroundColor DarkGray
	}
}

if ($config.start_dir) {
    $dir = [Environment]::ExpandEnvironmentVariables($config.start_dir)
    if (Test-Path $dir) {
        Set-Location $dir
    } else {
        Write-Host "start_dir '$dir' does not exist." -ForegroundColor Red
    }
}

if ($config.aliaspack) { # opt-in aliaspack
	# set-alias cpkg winget # replaced by cpkg native
	set-alias alias set-alias
	set-alias gcmd get-command
	<# :3
	set-alias pwease sudo
	set-alias dewete rm
	#>
}

<#
valid args:
install; inst
remove;  rm
update;  upd
search;  s
info;    i
source;  src
refresh; r
#>
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
} elseif (get-command winget -ErrorAction SilentlyContinue) {
	$pmngr = "winget"
} else {
	$pmngr = "n/a"
}

function cpkg($action, $package) {
	if ($package) {
		if ($pmngr -eq "apt") {
			if($action -in @("install","inst")) {
				apt install $package
			} elseif($action -in @("remove","rm")) {
				apt remove $package
			} elseif($action -in @("update","upd")) {
				apt upgrade $package
			} elseif($action -in @("search","s")) {
				apt search $package
			} elseif($action -in @("info","i")) {
				apt show $package
			} elseif($action -in @("source","src")) {
				apt source $package
			}
		} elseif ($pmngr -eq "pacman") {
			if($action -in @("install","inst")) {
				pacman -S $package
			} elseif($action -in @("remove","rm")) {
				pacman -R $package
			} elseif($action -in @("update","upd")) {
				pacman -S $package
			} elseif($action -in @("search","s")) {
				pacman -Ss $package
			} elseif($action -in @("info","i")) {
				pacman -Si $package
			} elseif($action -in @("source","src")) {
				pacman -Si $package
			}
		} elseif ($pmngr -eq "apk") {
			if($action -in @("install","inst")) {
				apk add $package
			} elseif($action -in @("remove","rm")) {
				apk del $package
			} elseif($action -in @("search","s")) {
				apk search $package
			} elseif($action -in @("info","i")) {
				apk info $package
			} elseif($action -in @("source","src")) {
				apk fetch $package
			}
		} elseif ($pmngr -eq "dnf") {
			if($action -in @("install","inst")) {
				dnf install $package
			} elseif($action -in @("remove","rm")) {
				dnf remove $package
			} elseif($action -in @("update","upd")) {
				dnf update $package
			} elseif($action -in @("search","s")) {
				dnf search $package
			} elseif($action -in @("info","i")) {
				dnf info $package
			} elseif($action -in @("source","src")) {
				dnf download --source $package
			}
		} elseif ($pmngr -eq "zypper") {
			if($action -in @("install","inst")) {
				zypper install $package
			} elseif($action -in @("remove","rm")) {
				zypper remove $package
			} elseif($action -in @("update","upd")) {
				zypper update $package
			} elseif($action -in @("search","s")) {
				zypper search $package
			} elseif($action -in @("info","i")) {
				zypper info $package
			} elseif($action -in @("source","src")) {
				zypper source-install $package
			}
		} elseif ($pmngr -eq "yay") {
			if($action -in @("install","inst")) {
				yay -S $package
			} elseif($action -in @("remove","rm")) {
				yay -R $package
			} elseif($action -in @("update","upd")) {
				yay -S $package
			} elseif($action -in @("search","s")) {
				yay -Ss $package
			} elseif($action -in @("info","i")) {
				yay -Si $package
			} elseif($action -in @("source","src")) {
				yay -G $package
			}
		} elseif ($pmngr -eq "winget") {
			if($action -in @("install","inst")) {
				winget install $package
			} elseif($action -in @("remove","rm")) {
				winget uninstall $package
			} elseif($action -in @("update","upd")) {
				winget upgrade $package
			} elseif($action -in @("search","s")) {
				winget search $package
			} elseif($action -in @("info","i")) {
				winget show $package
			}
		}
	} else {
		if($pmngr -eq "apt") {
			if($action -in @("refresh","r")) {
				apt update
			}
		} elseif($pmngr -eq "apk") {
			if($action -in @("update","upd")) {
				apk upgrade
			} elseif($action -in @("refresh","r")) {
				apk update
			}
		} elseif($pmngr -eq "pacman") {
			if($action -in @("update","upd")) {
				pacman -Syu
			}
		} elseif($pmngr -eq "dnf") {
			if($action -in @("refresh","r")) {
				dnf makecache
			} elseif($action -in @("update","upd")) {
				dnf update
			}
		} elseif($pmngr -eq "zypper") {
			if($action -in @("refresh","r")) {
				zypper refresh
			}
		} elseif($pmngr -eq "yay") {
			if($action -in @("update","upd")) {
				yay -Syu
			}
		} elseif($pmngr -eq "winget") {
			if($action -in @("source","src")) {
				winget source list
			} elseif($action -in @("refresh","r")) {
				winget source update
			}
		}
	}
}


function esh {
    param([string]$file)
    if (!(Test-Path $file) -and (Test-Path "$file.esh")) {
        $file = "$file.esh"
    }
    $path = Resolve-Path $file -ErrorAction Stop
    $global:eShScriptRoot = Split-Path -Parent $path
    $temp = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), ".psm1")
    Copy-Item $path $temp
    Import-Module $temp -Force -Global
    Remove-Item $temp
}

function Read-EsxPaths {
    $pathsFile = Join-Path $emberRoot "emberCore\path.ls"
    $paths = [ordered]@{}

    if (Test-Path $pathsFile) {
        Get-Content $pathsFile | ForEach-Object {
            if ($_ -match '^"([^"]+)"\s+(.+)$') {
                $name = $matches[1]
                $raw  = $matches[2].Trim()

                if ($raw -match '^[A-Za-z]:[/\\]' -or $raw -match '^[/\\]{2}' -or $raw -match '^/') {
                    $paths[$name] = $raw
                } else {
                    $paths[$name] = Join-Path $emberRoot $raw
                }
            }
        }
    }

    if (-not $paths.Contains("main")) {
        Add-Content $pathsFile "`"main`" modules"
        $paths["main"] = Join-Path $emberRoot "modules"
    }

    return $paths
}

function esx {
    param(
        [string]$file,
        [string]$fromPath = "main"
    )
    $paths = Read-EsxPaths

    if (-not $paths.Contains($fromPath)) {
        Write-Host "esx: unknown path '$fromPath'"
        return
    }

    $base      = $paths[$fromPath]
    $candidate = Join-Path $base $file

    $resolved = $null
    if (Test-Path $candidate) {
        $resolved = $candidate
    } elseif (Test-Path "$candidate.esx") {
        $resolved = "$candidate.esx"
    }

    if (-not $resolved) {
        Write-Host "esx: module '$file' not found in path '$fromPath' ($base)"
        return
    }

    $path = Resolve-Path $resolved -ErrorAction Stop
    $global:eShScriptRoot = Split-Path -Parent $path
    $temp = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), ".psm1")
    Copy-Item $path $temp
    Import-Module $temp -Force -Global
    Remove-Item $temp
}

function set-xtpath {
    param([string]$name, [string]$path)

    if ($name -eq "main") {
        Write-Host "set-xtpath: 'main' is reserved"
        return
    }

    $pathsFile = Join-Path $emberRoot "emberCore\path.ls"
    $paths = Read-EsxPaths

    if ($paths.Contains($name)) {
        Write-Host "set-xtpath: '$name' already exists, overwriting"
        $lines = Get-Content $pathsFile | Where-Object {
            $_ -notmatch "^`"$name`""
        }
        Set-Content $pathsFile $lines
    }

    $content = Get-Content $pathsFile -Raw
    if ($content -and -not $content.EndsWith("`n")) {
        Add-Content $pathsFile ""
    }
    Add-Content $pathsFile "`"$name`" $path"
    Write-Host "set-xtpath: added '$name' -> $path"
}

if ($config.auto_esx_clib) {
	if ($config.clib_compat) {
		esx clibCompat
	} else {
		esx clib
	}
}

if($config.lids) { # not recommended on macos     // "Linux Identity Spoof"
	# Remove-Alias -Name cd -Force -Scope Global // works without spam forcing
    esx lids
	if($IsWindows) {
		Remove-Alias -Name cd -Force -Scope Global
	}
}
if (-not $global:clib_panic_addon) {
	function Invoke-Panic {
		param([string]$Message = "A fatal error has occurred.")
		[Console]::BackgroundColor = "DarkBlue"
		[Console]::ForegroundColor = "White"
		[Console]::Clear()
		Write-Host ""
		Write-Host ""
		Write-Host "  emberShell encountered a fatal error:"
		Write-Host ""
		Write-Host "  $Message"
		Write-Host ""
		Write-Host "  Press Enter to exit"
		[Console]::CursorVisible = $false
		function global:prompt {
			"PS $pwd>"
		}
		read-host
		clear
		exit
	}
	esx paper panic -erroraction silentlycontinue
}

$emberRice = Get-Content (Join-Path $global:emberRoot "emberCore\ember.rice") -Raw | ConvertFrom-Json
$emberRice.PSObject.Properties | ForEach-Object {
    esx $_.Name $_.Value -ErrorAction SilentlyContinue
}