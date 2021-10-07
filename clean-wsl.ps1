function Add-Log {
    [CmdletBinding()]
    param (
        [String]$Txt,
        [EventLogEntryType]$LogType,
        [int]$EventId
    )

    Write-EventLog -LogName "ShutdownWslVHDptimize" -Message $Txt -EventId $EventId -EntryType $LogType -Source "CleanWsl.ps1"
    
}

function Config-Log {    
    #$timestamp = Get-Date -Format "yyyy-MM-dd_HH:mm"

    New-EventLog -Source "CleanWsl.ps1" -LogName "ShutdownWslVHDptimize"
}

function Get-WSLPaths {
    $path_prefix = "$env:LOCALAPPDATA\Packages"
    $distros = ([String]((wsl -l -q) -replace "`0", "") -split "  ")
    $distros = @($distros | Where-Object { $_ -ne $distros[-1] })

    $path = @()

    $distros.foreach( {
        $mystr=""
        if($_.Contains('-')) {
            foreach ($ch in $_.ToCharArray()) {
                if($ch -ne '-') {
                    $mystr+=$ch 
                } else {
                    break
                }
            }
        } else {
            $mystr=$_
        }
        $folder_name = Get-ChildItem $path_prefix | Select-String $mystr
            if ($null -ne $folder_name) {
                $path += "$path_prefix\$folder_name"
            }  
        })
    
    Write-Host "Found $($path.Length) distro"
    $path
}

function Get-AllWslPath {
    $DockerArr=(ls $env:LOCALAPPDATA\Docker\*\*.vhdx -Recurse)
    $SystemArr=(ls $env:LOCALAPPDATA\Packages\*\*.vhdx -Recurse)
    $tmp=$SystemArr+$DockerArr

    $arr=@()
    $tmp.foreach({
        $arr+=$_.FullName
    })
    $arr
}
Write-Host "Shutding down wsl..."
wsl --shutdown 

$wsl_folder = Get-AllWslPath

$wsl_folder.foreach( {
        $path = $_
        if(([System.IO.File]::Exists($path))){ 
        Write-Host "Optimizing: $path" 
        Optimize-VHD $path -Mode Full
        }
    })
