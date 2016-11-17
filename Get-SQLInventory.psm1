Function Get-SQLInventory {
    <#
        .SYNOPSIS
            Checks remote registry for SQL Server Edition and Version.

        .DESCRIPTION
            Checks remote computer for SQL Server Edition, Version and hardware.

        .PARAMETER  ComputerName
            Computer to inventory for SQL and hardware information.

        .EXAMPLE
            PS C:\> Get-SQLInventory -ComputerName mymssqlsvr 

        .EXAMPLE
            PS C:\> $list = cat .\sqlsvrs.txt
            PS C:\> $list | % { Get-SQLInventory $_ | select ServerName,Edition }

        .EXAMPLE
            $Servers = Get-ADComputer -Filter {OperatingSystem -like "Windows*"} | Select-Object -ExpandProperty Name

            $Inventory = @()
            ForEach($Server in $Servers){
                Write-Host "Checking $Server ..."
                $Inventory += Get-SQLInventory -ComputerName $Server
            }

            $Inventory

        .INPUTS
            System.String,System.Int32

        .OUTPUTS
            System.Management.Automation.PSCustomObject

        .NOTES
            Does not query SQL for any information. Administrator access is required to the remote computer.

        .LINK
            about_functions_advanced

    #>
    [CmdletBinding()]
    param(
        # a computer name
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ComputerName
    )

    # Test to see if the remote is up
    If (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
        # Concatenate all IPs into a string
        $IP = [System.Net.Dns]::GetHostAddresses($ComputerName) -join ' '
    
        # Get processors information            
        $CPU=Get-WmiObject -ComputerName $ComputerName -class Win32_Processor

        #Get computer model information
        $OS_Info=Get-WmiObject -ComputerName $ComputerName -class Win32_ComputerSystem

        #Get memory information
        $Memory = (Get-WMIObject -Class Win32_PhysicalMemory -ComputerName $ComputerName | Measure-Object -Property capacity -Sum | ForEach-Object{[Math]::Round(($_.sum / 1GB),2)})
            
     
        #Reset number of cores and use count for the CPUs counting
        $CPUs = 0
        $Cores = 0
           
        ForEach($Processor in $CPU){
            # Increment cpu count
            $CPUs = $CPUs + 1   
           
            # Count the total number of cores         
            $Cores = $Cores + $Processor.NumberOfCores
        }

        # Create custom object to hold discovered properties
        $Sql_Inventory = New-Object PSObject
        $Sql_Inventory | Add-Member -MemberType NoteProperty -Name ServerName -Value $ComputerName
        $Sql_Inventory | Add-Member -MemberType NoteProperty -Name IP -Value $IP
        $Sql_Inventory | Add-Member -MemberType NoteProperty -Name Model -Value $OS_Info.Model
        $Sql_Inventory | Add-Member -MemberType NoteProperty -Name CPUNumber -Value $CPUs
        $Sql_Inventory | Add-Member -MemberType NoteProperty -Name TotalCores -Value $Cores
        $Sql_Inventory | Add-Member -MemberType NoteProperty -Name MemoryGB -Value $Memory

        # Registry key to look in for SQL information
        $Base = "SOFTWARE\"
        $Key = "$($Base)\Microsoft\Microsoft SQL Server\Instance Names\SQL"
        $Type = [Microsoft.Win32.RegistryHive]::LocalMachine
        $RegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Type, $ComputerName)
        $SqlKey = $RegKey.OpenSubKey($Key)

        Try {
            # Verify if any results are returned, if not, look in the 32bit registry hive
            $SQLKey.GetValueNames() | Out-Null
        } Catch { 
            # If this failed, it's in the wrong registry node
            $Base = "SOFTWARE\WOW6432Node\"
            $Key = "$($Base)\Microsoft\Microsoft SQL Server\Instance Names\SQL"
            $RegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Type, $ComputerName)
            $SqlKey = $RegKey.OpenSubKey($Key)
        }

        Try{
            # Add discovered instances as a concatenated list of string
            $Sql_Inventory | Add-Member -MemberType NoteProperty -Name Instance -Value ($SqlKey.GetValueNames() -join ", ")

            # Parse each value in the reg_multi InstalledInstances 
            ForEach($Instance in $SqlKey.GetValueNames()){
                # Read the instance name
                $InstName = $SqlKey.GetValue("$instance")

                # Sub in instance name
                $InstKey = $regKey.OpenSubkey("$($base)\Microsoft\Microsoft SQL Server\$instName\Setup")

                # Add discovered SQL info to the psobj
                $Sql_Inventory | Add-Member -MemberType NoteProperty -Name Edition -Value $instKey.GetValue("Edition") -Force # read Ed value
                $Sql_Inventory | Add-Member -MemberType NoteProperty -Name Version -Value $instKey.GetValue("Version") -Force # read Ver value

                # return an object, useful for many things
                Return $Sql_Inventory
            }
        } Catch {
            # If no instances are detected, then this is not a SQL Server
            Write-Verbose "Server $($ComputerName) is not a SQL server." 
        }
    } Else {
        # If the connection test fails
        Write-Verbose "Server $($ComputerName) is unavailable..." 
    }
}
