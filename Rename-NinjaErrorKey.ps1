#find Ninja Key
$path = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
$parentkey = Get-ChildItem -Path $Path | ? {$_.Name -match "NinjaRMM*"}
#Find the Version
$version = Get-ItemPropertyValue -Path "Registry::$parentkey" -Name DisplayVersion
$NewName = -join("NinjaRMMAgent"," ",$version)
#Rename version
Rename-Item "Registry::$parentkey" -NewName $NewName
