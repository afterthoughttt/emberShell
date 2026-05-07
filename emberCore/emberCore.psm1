$emberRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)

$configPath = Join-Path $emberRoot "emberCore\emberConfig.json"
$shellPath  = Join-Path $emberRoot "emberCore\emberShell.json"

function set-config {
    param([string]$key, $value)
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    if ($null -eq $config.$key) {
        throw "Invalid key `"$key`" passed"
    }
    $existingType = $config.$key.GetType().Name
    $newType = $value.GetType().Name
    if ($existingType -ne $newType) {
        throw "Type mismatch: `"$key`" expects $existingType, got $newType"
    }
    $config.$key = $value
    $config | ConvertTo-Json | Set-Content $configPath -Encoding utf8
}

function prompt {
    "eSh $($PWD.Path)> "
}

function emberShell([switch]$version, [switch]$fork, [switch]$dev, [switch]$vername, [switch]$shname) {
	$shell = Get-Content $shellPath -Raw | ConvertFrom-Json
	if($shname){
		write-host $shell.shell_name
	}
	if($version){
		write-host $shell.shell_version
	}
	if($vername){
		write-host $shell.sv_name
	}
	if($dev){
		write-host "by" $shell.dev_name
	}
	if($fork){
		if($shell.fork -eq $true){
			write-host "is a fork"
		}else{
			write-host "not a fork"
		}
	}
}