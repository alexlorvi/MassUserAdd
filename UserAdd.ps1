if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

$file = "$PSScriptRoot\list.txt"


Function Create-Folders {
  param ([parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string] $User)
  
  $local:BasePath = "D:\Users\"
  New-Item -Path (-join($BasePath,$User)) -ItemType Directory
  New-Item -Path (-join($BasePath,$User,"\Відкриті")) -ItemType Directory
  New-Item -Path (-join($BasePath,$User,"\Для службового користування")) -ItemType Directory
  New-Item -Path (-join($BasePath,$User,"\Таємні")) -ItemType Directory

  icacls (-join($BasePath,$User)) /inheritance:r
  icacls (-join($BasePath,$User)) /grant "*S-1-5-32-544:(OI)(CI)F" /grant (-join($User,":(OI)(CI)F")) /T
  icacls (-join($BasePath,$User)) /setowner $User /T   
}



if (Test-Path -Path $file) {
  $CreateUserList = (Get-Content -path $file) | ForEach-Object -Process {($_).Trim()}
  $CreateUserList = $CreateUserList | select -Unique | where {$_ -ne ''}
  if ($CreateUserList.count -gt 0) {
    foreach ($User in $CreateUserList) {
      $UserName,$UserPassword = $User -split ' ' -replace '^\s*|\s*$'
      net user $UserName $UserPassword /add
      Create-Folders -User $UserName
    }
  }
} else {
  Write-Host "File $file not exist"
  $NewUser = Get-Credential
  New-LocalUser $NewUser.UserName -Password $NewUser.Password
  Create-Folders -User $NewUser.UserName
}
