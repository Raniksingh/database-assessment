﻿# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
<#
.SYNOPSIS
    .
.DESCRIPTION
    Executes the necessary scripts to collect data from SQL Server and Perfmon to be uploaded to Google Database Migration Assistant for review.

    If user and password are supplied, that will be used to execute the script.  Otherwise default credentials hardcoded in the script will be used
.PARAMETER user
    Collection username (optional)
.PARAMETER pass
    Collection username password (optional)
.EXAMPLE
    To use a specific username / password combination:
        C:\InstanceReview.ps1 -user [collection username] -pass [collection username password]
    
    or
    
    To use default credentials:
        C:\InstanceReview.ps1
.NOTES
    https://googlecloudplatform.github.io/database-assessment/
#>
Param(
[string]$user = "userfordma",
[string]$pass = "P@ssword135"
)

$objs = Import-Csv -Delimiter "," sqlsrv.csv
$foldername = ""
foreach($item in $objs) {
    $sqlsrv = $item.InstanceName
	Write-Output "Retrieving Metadata Information from $sqlsrv"
	if ($sqlsrv -like "*MSSQLSERVER*") {
		$obj = sqlcmd -H $sqlsrv -i sql\foldername.sql -U $user -P $pass -W -m 1 -u | findstr /v /c:"---"
	} else {
		$obj = sqlcmd -S $sqlsrv -i sql\foldername.sql -U $user -P $pass -W -m 1 -u | findstr /v /c:"---"
	}

    $splitobj = $obj[1].Split('')
    $values = $splitobj | ForEach-Object { if($_.Trim() -ne '') { $_ } }

    $dbversion = $values[0].Replace('.','')
    $machinename = $values[1]
    $dbname = $values[2]
    $instancename = $values[3]
    $current_ts = $values[4]
    $pkey = $values[5]

    $op_version = "4.3.5"

    $foldername = 'opdb' + '_' + 'mssql' + '_' + 'PerfCounter' + '__' + $dbversion + '_' + $op_version + '_' + $machinename + '_' + $dbname + '_' + $instancename + '_' + $current_ts

    $folderLength = ($PSScriptRoot + '\' + $foldername).Length
    if ($folderLength -le 260) {
        Write-Output "Creating directory $foldername"
        $null = New-Item -Name $foldername -ItemType Directory
    } else {
        Write-Output "Folder length exceeds 260 characters.  Run collection tool from a"
        Write-Output "Folder being created is: $PSScriptRoot\$foldername"
        Exit
    }

    $compFileName = 'opdb' + '__' + 'CompInstalled' + '__' + $dbversion + '_' + $op_version + '_' + $machinename + '_' + $dbname + '_' + $instancename + '_' + $current_ts + '.csv'
    $srvFileName = 'opdb' + '__' + 'ServerProps' + '__' + $dbversion + '_' + $op_version  + '_' + $machinename + '_' + $dbname + '_' + $instancename + '_' + $current_ts + '.csv'
    $blockingFeatures = 'opdb' + '__' + 'BlockFeatures' + '__' + $dbversion + '_' + $op_version  + '_' + $machinename + '_' + $dbname + '_' + $instancename + '_' + $current_ts + '.csv'
    $linkedServers = 'opdb' + '__' + 'LinkedSrvrs' + '__' + $dbversion + '_' + $op_version  + '_' + $machinename + '_' + $dbname + '_' + $instancename + '_' + $current_ts + '.csv'
    $dbsizes = 'opdb' + '__' + 'DbSizes' + '__' + $dbversion + '_' + $op_version  + '_' + $machinename + '_' + $dbname + '_' + $instancename + '_' + $current_ts + '.csv'
    $dbClusterNodes = 'opdb' + '__' + 'DbClusterNodes' + '__' + $dbversion + '_' + $op_version  + '_' + $machinename + '_' + $dbname + '_' + $instancename + '_' + $current_ts + '.csv'
    $objectList = 'opdb' + '__' + 'ObjectList' + '__' + $dbversion + '_' + $op_version  + '_' + $machinename + '_' + $dbname + '_' + $instancename + '_' + $current_ts + '.csv'
    $tableList = 'opdb' + '__' + 'TableList' + '__' + $dbversion + '_' + $op_version  + '_' + $machinename + '_' + $dbname + '_' + $instancename + '_' + $current_ts + '.csv'
    $indexList = 'opdb' + '__' + 'IndexList' + '__' + $dbversion + '_' + $op_version  + '_' + $machinename + '_' + $dbname + '_' + $instancename + '_' + $current_ts + '.csv'
    $columnDatatypes = 'opdb' + '__' + 'ColumnDatatypes' + '__' + $dbversion + '_' + $op_version  + '_' + $machinename + '_' + $dbname + '_' + $instancename + '_' + $current_ts + '.csv'
    $userConnectionList = 'opdb' + '__' + 'UserConnections' + '__' + $dbversion + '_' + $op_version  + '_' + $machinename + '_' + $dbname + '_' + $instancename + '_' + $current_ts + '.csv'
    $perfMonOutput = 'opdb' + '__' + 'PerfMonData' + '__' + $dbversion + '_' + $op_version  + '_' + $machinename + '_' + $dbname + '_' + $instancename + '_' + $current_ts + '.csv'
    $dbccTraceFlg = 'opdb' + '__' + 'DbccTrace' + '__' + $dbversion + '_' + $op_version  + '_' + $machinename + '_' + $dbname + '_' + $instancename + '_' + $current_ts + '.csv'
    $diskVolumeInfo = 'opdb' + '__' + 'DiskVolInfo' + '__' + $dbversion + '_' + $op_version  + '_' + $machinename + '_' + $dbname + '_' + $instancename + '_' + $current_ts + '.csv'

	if ($instancename -eq "MSSQLSERVER") {
		Write-Output "Retriving SQL Server Installed Components..."
		sqlcmd -S $machinename -i sql\componentsInstalled.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$compFileName
		Write-Output "Retriving SQL Server Properties..."
		sqlcmd -S $machinename -i sql\serverProperties.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$srvFileName
		Write-Output "Retriving SQL Server Features..."
		sqlcmd -S $machinename -i sql\features.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$blockingFeatures
		Write-Output "Retriving SQL Server Linked Servers..."
		sqlcmd -S $machinename -i sql\linkedServers.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$linkedServers
		Write-Output "Retriving SQL Server Database Sizes..."
		sqlcmd -S $machinename -i sql\dbSizes.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$dbsizes
		Write-Output "Retriving SQL Server Cluster Nodes..."
		sqlcmd -S $machinename -i sql\dbClusterNodes.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$dbClusterNodes
		Write-Output "Retriving SQL Server Object Info..."
		sqlcmd -S $machinename -i sql\objectList.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$objectList
		sqlcmd -S $machinename -i sql\tableList.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$tableList
		sqlcmd -S $machinename -i sql\indexList.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$indexList
		sqlcmd -S $machinename -i sql\columnDatatypes.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$columnDatatypes
		sqlcmd -S $machinename -i sql\userConnectionInfo.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$userConnectionList
		sqlcmd -S $machinename -i sql\dbccTraceFlags.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$dbccTraceFlg
		sqlcmd -S $machinename -i sql\diskVolumeInfo.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$diskVolumeInfo
	} else {
		Write-Output "Retriving SQL Server Installed Components..."
		sqlcmd -S $sqlsrv -i sql\componentsInstalled.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$compFileName
		Write-Output "Retriving SQL Server Properties..."
		sqlcmd -S $sqlsrv -i sql\serverProperties.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$srvFileName
		Write-Output "Retriving SQL Server Features..."
		sqlcmd -S $sqlsrv -i sql\features.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$blockingFeatures
		Write-Output "Retriving SQL Server Linked Servers..."
		sqlcmd -S $sqlsrv -i sql\linkedServers.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$linkedServers
		Write-Output "Retriving SQL Server Database Sizes..."
		sqlcmd -S $sqlsrv -i sql\dbSizes.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$dbsizes
		Write-Output "Retriving SQL Server Cluster Nodes..."
		sqlcmd -S $sqlsrv -i sql\dbClusterNodes.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$dbClusterNodes
		Write-Output "Retriving SQL Server Object Info..."
		sqlcmd -S $sqlsrv -i sql\objectList.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$objectList
		sqlcmd -S $sqlsrv -i sql\tableList.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$tableList
		sqlcmd -S $sqlsrv -i sql\indexList.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$indexList
		sqlcmd -S $sqlsrv -i sql\columnDatatypes.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$columnDatatypes
		sqlcmd -S $sqlsrv -i sql\userConnectionInfo.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$userConnectionList
		sqlcmd -S $sqlsrv -i sql\dbccTraceFlags.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$dbccTraceFlg
		sqlcmd -S $sqlsrv -i sql\diskVolumeInfo.sql -U $user -P $pass -W -m 1 -u -v pkey=$pkey -s"|" | findstr /v /c:"---" > $foldername\$diskVolumeInfo
	}

    Write-Output "Retrieving OS Disk Cluster Information.."
    if (Test-Path -Path $env:TEMP\tempDisk.csv) {
        Remove-Item -Path $env:TEMP\tempDisk.csv
    }
    
    Add-Content -Path $env:TEMP\tempDisk.csv -Value "PKEY|volume_mount_point|file_system_type|logical_volume_name|total_size_gb|available_size_gb|space_free_pct|cluster_block_size" -Encoding utf8
    
    foreach($drive in (Import-Csv -Delimiter '|' -Path $foldername\*DiskVolInfo*.csv | Select-Object -Property volume_mount_point).volume_mount_point) {
        $blocksize = (Get-CimInstance -ClassName Win32_Volume | Select-Object Name, Label, BlockSize, FileSystem | `
        Where-Object {($_.Name -Contains $drive) -and ($_.FileSystem -in 'NTFS')} | Select-Object -Property BlockSize).BlockSize
        Get-Content -Path  $foldername\*DiskVolInfo*.csv | ForEach-Object {			
            if ($_ -match ([regex]::Escape($drive))) {
                if ([int]$blocksize -gt 0)
                {
                    $blockValue = $_ + '|' +$blocksize
                    Add-Content -Path $env:TEMP\tempDisk.csv -Value $blockValue -Encoding utf8
                }
                else
                {
                    $blockValue = $_ + '|null'
                    Add-Content -Path $env:TEMP\tempDisk.csv -Value $blockValue -Encoding utf8
                }
            }
        } 
    }
    
    foreach($file in Get-ChildItem -Path $foldername\*DiskVolInfo*.csv) {
        $outputFileName=$file.name
        Get-Content -Path $env:TEMP\tempDisk.csv | Set-Content -Encoding utf8 -Path $foldername\$outputFileName
    }

	if ($instancename -eq "MSSQLSERVER") {
		.\dma_sqlserver_perfmon_dataset.ps1 -operation collect -perfmonOutDir $foldername -perfmonOutFile $perfMonOutput -pkey $pkey
	} else {
		.\dma_sqlserver_perfmon_dataset.ps1 -operation collect -mssqlInstanceName $instancename -perfmonOutDir $foldername -perfmonOutFile $perfMonOutput -pkey $pkey
	}

    Write-Output "Remove special characters from extracted Files.."
    foreach($file in Get-ChildItem -Path $foldername\*.csv) {
        (Get-Content $file -Raw).Replace("`r`n","`n") | Set-Content $file -Encoding utf8 -Force
    }
    $zippedopfolder = $foldername + '.zip'
	Write-Output "Zipping Output to $zippedopfolder"
    Compress-Archive -Path $foldername\*.csv -DestinationPath $zippedopfolder
    if (Test-Path -Path $zippedopfolder) {
		Write-Output "Removing directory $foldername"
        Remove-Item -Path $foldername -Recurse -Force
    }
    if (Test-Path -Path $env:TEMP\tempDisk.csv) {
        Write-Output "Clean up Temp File area"
        Remove-Item -Path $env:TEMP\tempDisk.csv
    }

    Write-Output ""
    Write-Output ""
    Write-Output "Return file $PSScriptRoot\$zippedopfolder"
    Write-Output "to Google to complete assessment"
}