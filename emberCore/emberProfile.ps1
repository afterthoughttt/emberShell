$emberRoot = Split-Path -Parent $PSScriptRoot

$config = Get-Content (Join-Path $emberRoot "emberCore\emberConfig.json") -Raw | ConvertFrom-Json
$shell  = Get-Content (Join-Path $emberRoot "emberCore\emberShell.json")  -Raw | ConvertFrom-Json

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
	set-alias cpkg winget
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

function esx {
    param([string]$file)
    if (!(Test-Path $file) -and !(Test-Path "$file.esx")) {
        $file = Join-Path $emberRoot "modules\$file"
    }
    if (!(Test-Path $file) -and (Test-Path "$file.esx")) {
        $file = "$file.esx"
    }
    $path = Resolve-Path $file -ErrorAction Stop
    $global:eShScriptRoot = Split-Path -Parent $path
    $temp = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), ".psm1")
    Copy-Item $path $temp
    Import-Module $temp -Force -Global
    Remove-Item $temp
}

if ($config.auto_esx_clib) {
	if ($config.clib_compat) {
		esx clibCompat
	} else {
		esx clib
	}
}

if($config.lids) { # not recommended on linux or macos // "Linux Identity Spoof"
	# Remove-Alias -Name cd -Force -Scope Global // works without spam forcing
    esx lids
	Remove-Alias -Name cd -Force -Scope Global
}