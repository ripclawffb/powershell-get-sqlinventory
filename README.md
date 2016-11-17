---
external help file: Get-SQLInventory-help.xml
online version: 
schema: 2.0.0
---

# Get-SQLInventory

## SYNOPSIS
Checks remote registry for SQL Server Edition and Version.

## SYNTAX

```
Get-SQLInventory [-ComputerName] <String>
```

## DESCRIPTION
Checks remote computer for SQL Server Edition, Version and hardware.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-SQLInventory -ComputerName mymssqlsvr
```

### -------------------------- EXAMPLE 2 --------------------------
```
$list = cat .\sqlsvrs.txt
```

PS C:\\\> $list | % { Get-SQLInventory $_ | select ServerName,Edition }

### -------------------------- EXAMPLE 3 --------------------------
```
$Servers = Get-ADComputer -Filter {OperatingSystem -like "Windows*"} | Select-Object -ExpandProperty Name
```

$Inventory = @()
ForEach($Server in $Servers){
    Write-Host "Checking $Server ..."
    $Inventory += Get-SQLInventory -ComputerName $Server
}

$Inventory

## PARAMETERS

### -ComputerName
Computer to inventory for SQL and hardware information.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### System.String,System.Int32

## OUTPUTS

### System.Management.Automation.PSCustomObject

## NOTES
Does not query SQL for any information.
Administrator access is required to the remote computer.

## RELATED LINKS

[about_functions_advanced]()

