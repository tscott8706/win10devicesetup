#Requires -RunAsAdministrator

Set-ExecutionPolicy Bypass -Scope Process
$executingScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$installedProgramsScript = Join-Path $executingScriptDirectory "Get-RemoteProgram.ps1"

if (!(Test-Path $installedProgramsScript))
{
    echo "This script requires the Get-RemoteProgram.ps1 script to be located in the same directory as this script."
	echo "Get it from https://gallery.technet.microsoft.com/scriptcenter/Get-RemoteProgram-Get-list-de9fd2b4"
	exit
}

. $installedProgramsScript
$installed=Get-RemoteProgram
$optional_enabled_features=Get-WindowsOptionalFeature -Online | where state -eq enabled | ft -a

reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d "1"

foreach ($feature in "Containers", "Microsoft-Hyper-V", "Microsoft-Windows-Subsystem-Linux")
{
    if ($optional_enabled_features | Select-String -Pattern $feature)
    {
        Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -norestart
    }
    else
    {
        echo "$feature feature is already enabled: not re-enabling it."
    }
}

iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
refreshenv

$win_program_to_choco_program_list = ` 
    [System.Tuple]::Create("docker", "docker"),
    [System.Tuple]::Create("docker-compose", "docker-compose"),
    [System.Tuple]::Create("docker-for-windows", "docker-for-windows"),
    [System.Tuple]::Create("git", "git"),
    [System.Tuple]::Create("chrome", "googlechrome"),
    [System.Tuple]::Create("notepad\+\+", "notepadplusplus"),
    [System.Tuple]::Create("tortoisesvn", "tortoisesvn"),
    [System.Tuple]::Create("vlc", "vlc"),
    [System.Tuple]::Create("xming", "xming")

$programs_to_install = @()
foreach ($win_program_to_choco_program in $win_program_to_choco_program_list)
{
    $win=$win_program_to_choco_program.Item1
    $choco=$win_program_to_choco_program.Item2
    if ($installed | Select-String -Pattern $win)
    {
        echo "$win already installed: not reinstalling it."
    }
    else
    {
        $programs_to_install += $choco
    }
}

if ($programs_to_install.count -gt 0)
{
    echo "Installing the following program(s): $programs_to_install"
    choco install $programs_to_install -y
}
