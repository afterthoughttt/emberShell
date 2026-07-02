$emberRoot = Split-Path -Parent $PSScriptRoot
$Host.UI.RawUI.WindowTitle = "emberShell"
$config = Get-Content (Join-Path $emberRoot "emberCore\emberConfig.json") -Raw | ConvertFrom-Json
$shell  = Get-Content (Join-Path $emberRoot "emberCore\emberShell.json")  -Raw | ConvertFrom-Json
$psver = "7.7.0-preview.2"
$psver = $psver.Split('-')[0]  # returns "7.7.0"
if (test-path /etc/os-release) {
	$name = (cat /etc/os-release | ? { $_ -match "^NAME=" }).Split('=')[1].Trim('"')
	#$ver  = (cat /etc/os-release | ? { $_ -match "^VERSION=" }).Split('=')[1].Trim('"')
	if ($name -and $ver) {
		$osdat = "$name" #$ver "
	} elseif ($name) {
		$osdat = $name
	} <#elseif ($ver) {
		$osdat = $ver
	}#>
}

if ($shell.shell_version -match "-Nightly") {
	$eshver = "$($shell.shell_version)"
} else {
	$eshver = [System.Version]"$($shell.shell_version)"
}

if ($shell.clib_version -match "-Nightly") {
	$clver = "$($shell.clib_version)"
} else {
	$clver = [System.Version]"$($shell.clib_version)"
}

$ESVersionTable = [ordered]@{
	ESVersion   = "$($eshver)"
	ESEdition   = "$($shell.sv_name)"
	GitCommitId = "$($eshver)"
	ESParent    = "PowerShell $psver-$($PSVersionTable.PSEdition)" # change this when porting to other shells/langs
	OS          = "$osdat"
	clibVersion = "$($clver)"
}
sv -n ESVersionTable -o r  # make eSh ver table immutable // this may cause issues if undone
if ($config.watermark) {
	write-host "█████████████`n██      ███    ██ ██`n██████ █████████`n██          ██████`n██           ███ ██ ██`n██████████████" -fo darkgray
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
	if ($config.clib_compat -or !$PSVersionTable.PSEdition -or $PSVersionTable.PSEdition -eq "Desktop") {
		Write-Host "clibCompat $($shell.clib_version)" -ForegroundColor DarkGray
	} else {
		Write-Host "clib $($shell.clib_version)" -ForegroundColor DarkGray
	}
}

<#if ($config.start_dir) {
    $dir = [Environment]::ExpandEnvironmentVariables($config.start_dir)
    if (Test-Path $dir) {
        Set-Location $dir
    } else {
        Write-Host "start_dir '$dir' does not exist." -ForegroundColor Red
    }
} #> # deprecated

if ($config.aliaspack) { # opt-in aliaspack
	# set-alias cpkg winget # replaced by cpkg native
	set-alias alias set-alias
	set-alias gcmd get-command
	<# :3
	set-alias pwease sudo
	set-alias dewete rm
	#>
}

if ($config.aliaspack) {
	function mk($path) {
		if ($path.EndsWith('/') -or $path.EndsWith('\')) {
			New-Item -ItemType Directory -Path $path.TrimEnd('/\')
		} else {
			New-Item -ItemType File -Path $path
		}
	}
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

function legacpkg($action, $package) {
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
    $tempDir = [System.IO.Path]::GetTempPath()
    $tempName = [System.IO.Path]::GetFileNameWithoutExtension($path) + ".ps1"
    $temp = Join-Path $tempDir $tempName
    Copy-Item $path $temp -Force
    try {
        . $temp
    } finally {
        Remove-Item $temp -Force -ErrorAction SilentlyContinue
    }
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
        [string]$fromPath = "main",
		[switch]$silent
    )
    $paths = Read-EsxPaths

    if (-not $paths.Contains($fromPath)) {
		if (!$silent) {
			Write-Host "esx: unknown path '$fromPath'"
		}
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
		if (!$silent) {
			Write-Host "esx: module '$file' not found in path '$fromPath' ($base)"
		}
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
	if ($config.clib_compat -or !$PSVersionTable.PSEdition -or $PSVersionTable.PSEdition -eq "Desktop") {
		esx clibCompat
	} else {
		esx clib
	}
}

if($config.lids) { # not recommended on macos   <-- but y?  // "Linux Identity Spoof"
	# Remove-Alias -Name cd -Force -Scope Global           // works without spam forcing
    esx lids
	if($IsWindows) {
		Remove-Alias -Name cd -Force -Scope Global
	}
}
if (-not $global:clib_panic_addon) {
	function Invoke-Panic {
		param([string]$Message = "A fatal error has occurred.")
		$Host.UI.RawUI.WindowTitle = "SHELL PANIC!"
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
	esx paper panic -silent # this is kinda stupid, fix this in 1.8, PAPER belongs in ember.rice
}
if (!(test-path (Join-Path $global:emberRoot "emberCore\ember.rice"))) {
	"{
		
	}" > (Join-Path $global:emberRoot "emberCore\ember.rice")
}
$emberRice = Get-Content (Join-Path $global:emberRoot "emberCore\ember.rice") -Raw | ConvertFrom-Json
$emberRice.PSObject.Properties | ForEach-Object {
    esx $_.Name $_.Value -ErrorAction SilentlyContinue
}

function idoc($name) {
	if (!$name) {
		if (test-path (join-path $emberRoot "emberCore/idocs/gui.esh")) {
			esh (join-path $emberRoot "emberCore/idocs/gui")
		} else {
			invoke-panic "idocs/gui is missing please manually navigate idocs." # this should not happen unless you use a debloater.
		}
	}
	elseif (test-path (join-path $emberRoot "emberCore/idocs")) {
		if (test-path (join-path $emberRoot "emberCore/idocs/$name`.esh")) {
			esh (join-path $emberRoot "emberCore/idocs/$name")
		} else {
			invoke-panic "Attempt to call Invalid idoc." # this should not happen unless you make a typo or use a debloater.
		}
	}
}