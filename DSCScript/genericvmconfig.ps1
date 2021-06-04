$Config = @{
    AllNodes = @(
        @{ NodeName = 'localhost' }
    )
}

Configuration JoinDomain
{
    Param(
        [String[]]$Node = 'localhost',
        [String]$Domain = 'company.local',
        [pscredential]$Credential,
        [String]$joinOU
        )
    Import-DscResource -ModuleName xDSCDomainjoin
    
    Node $Node
    {
        xDSCDomainjoin JoinDomain
        {
        Domain = $Domain 
        Credential = $Credential  # Credential to join to domain
        JoinOU = $joinOU
        }
    }
}

Configuration ConfigureDrives
{
    Param([String[]]$Node = 'localhost')
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    Node $Node
    {

        Script Initialize_Disk {
            SetScript  =
            {
                # Start logging the actions 
                Start-Transcript -Path C:\Temp\Diskinitlog.txt -Append -Force
         
                # Move CD-ROM drive to Z:
                # Get-WmiObject -Class Win32_volume -Filter 'DriveType=5' | Select-Object -First 1 | Set-WmiInstance -Arguments @{DriveLetter='Z:'}
                # Set the parameters 
                $disks = Get-Disk | Where-Object partitionstyle -eq 'raw' | Sort-Object number
                $letters = 71..72 + 74..75 + 77..86 + 88..89 | ForEach-Object { [char]$_ }
                $count = 0
                $label = "Data"
         
                "Formatting disks.."
                foreach ($disk in $disks) {
                    $driveLetter = $letters[$count].ToString()
                    if ($disk.number -eq "2") {
                        Initialize-Disk -Number 2 -PartitionStyle MBR -PassThru 
                        $drivePaths = @(
                
                            [pscustomobject]@{DriveLetter = 'F'; Path = 'F:\'; Volume = 'Data'; Drivesize = 250GB }
                            [pscustomobject]@{DriveLetter = 'W'; Path = 'W:\'; Volume = 'Work'; Drivesize = 250GB }
                            [pscustomobject]@{DriveLetter = 'I'; Path = 'I:\'; Volume = 'IIS'; Drivesize = 100GB }
                            [pscustomobject]@{DriveLetter = 'L'; Path = 'L:\'; Volume = 'Logs'; Drivesize = 10GB }
                            
                        )
                        foreach ($path in $drivePaths) {
                            if (Test-Path ($path.Path)) {
                                Write-Host "Paths Exists"
                            }
                            Else {
                               
                                New-Partition -DiskNumber 2 -Size $path.Drivesize -DriveLetter $path.DriveLetter | Format-Volume -NewFileSystemLabel $path.Volume -Confirm:$false -Force
                            }
                        }
                    }
                    else {

                        $disk |
                        Initialize-Disk -PartitionStyle MBR -PassThru |
                        New-Partition -UseMaximumSize -DriveLetter $driveLetter |
                        Format-Volume -FileSystem NTFS -NewFileSystemLabel "$label.$count" -Confirm:$false -Force
                        "$label.$count"
                        $count++
                    }
                    
                }
 
                Stop-Transcript
            }
           
            TestScript =
            {
                try {
                    Write-Verbose "Testing if any Raw disks are left"
                    $Validate = Get-Disk | Where-Object partitionstyle -eq 'raw'
                }
                catch {
                    $ErrorMessage = $_.Exception.Message
                    $ErrorMessage
                }
         
                If (!($Validate -eq $null)) {
                    Write-Verbose "Disks are not initialized"     
                    return $False 
                }
                Else {
                    Write-Verbose "Disks are initialized"
                    Return $True
                        
                }
            }
            GetScript  = { @{ Result = Get-Disk | Where-Object partitionstyle -eq 'raw' } }
                        
        }
    }
}

Configuration DeployTentacle
{
        
    Param(
        [String[]]$Node = 'localhost',
        [string]$OctopusAPIKey,
        [string[]]$OctopusRoles,
        [string[]]$OctopusEnvironments,
        [string]$OctopusServerUrl,
        [string]$DefaultApplicationDirectory,
        [string]$TentacleHomeDirectory,
        [string]$TentacleInstanceName = "Default"
    )

    Import-DscResource -ModuleName 'OctopusDSC'
    Node $Node
    {
        cTentacleAgent OctopusTentacle {
            Name                        = $TentacleInstanceName
            DisplayName                 = $env:COMPUTERNAME
            Ensure                      = "Present"
            State                       = "Started"
            ApiKey                      = $OctopusAPIKey
            OctopusServerUrl            = $OctopusServerUrl
            Environments                = $OctopusEnvironments
            Roles                       = $OctopusRoles
            CommunicationMode           = "Poll"
            DefaultApplicationDirectory = "c:\octopus"
            TentacleHomeDirectory       = "c:\octopus\tentaclehome"
            
        }
    }
}


Configuration AllServers
{
    
    Param(
        [String[]]$Node = 'localhost',
        [string]$OctopusAPIKey,
        [string[]]$OctopusRoles,
        [string[]]$OctopusEnvironments,
        [string]$OctopusServerUrl,
        [pscredential]$credential,
        [string]$joinOU
    )

    ConfigureDrives Drives {
        Node = $Node
    }
    
    DeployTentacle OctopusTentacle {
        Node                = $Node
        OctopusAPIKey       = $OctopusAPIKey
        OctopusRoles        = $OctopusRoles
        OctopusEnvironments = $OctopusEnvironments
        OctopusServerUrl    = $OctopusServerUrl       

    }
    JoinDomain JDomain {
        Credential = $credential
        JoinOU     = $joinOU
    } 

}

Configuration AllWorkstations
{
    Param(
        [String[]]$Node = 'localhost',
        [string]$OctopusAPIKey,
        [string[]]$OctopusRoles,
        [string[]]$OctopusEnvironments,
        [string]$OctopusServerUrl
    )
    DeployTentacle OctopusTentacle {
        Node                = $Node
        OctopusAPIKey       = $OctopusAPIKey
        OctopusRoles        = $OctopusRoles
        OctopusEnvironments = $OctopusEnvironments
        OctopusServerUrl    = $OctopusServerUrl 
    }

}