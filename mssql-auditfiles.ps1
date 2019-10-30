<#
 # Return Microsoft SQL Server Audit Files
 #
 # (c) 2019-01-18 António Pós-de-Mina
 #>

'<<<local:sep(9)>>>'

(Get-Host).UI.RawUI.BufferSize = New-Object -TypeName System.Management.Automation.Host.Size(150,9999)


Get-WmiObject win32_service -Filter 'Name like "MSSQL%"' | Where-Object { $_.State -eq 'Running' -and $_.PathName -like '*sqlservr*' } |  ForEach-Object {

    $SQLInstanceName = 'MSSQLSERVER'
    if ($_.Name -like '*$*') {
        $SQLInstanceName = $_.Name.split('$')[1]
    }
    #if($true) { return }
    $SQLInstanceContextConnection = New-Object -TypeName System.Data.SqlClient.SqlConnection "Data Source=.\$($SQLInstanceName);Integrated Security=True;Co
nnection Timeout=3"
        
    try {
        $SQLInstanceContextConnection.Open()

        $Command = $SQLInstanceContextConnection.CreateCommand()
        try {
            $Command.CommandText =
@'
SELECT @@SERVERNAME as Instancia, name, max_rollover_files, log_file_path
FROM sys.server_file_audits
WHERE max_rollover_files < 2147483647
'@

            $Reader = $Command.ExecuteReader()
            try {
                $Reader |
                    % {
                        $AuditSufix = $_['name'].Trim()
                        [int]$MaxRolloverFiles = $_['max_rollover_files']
                        $LogPath = $_['log_file_path']

                        [int]$files = (ls -Path "$($LogPath)\$($AuditSufix)*.sqlaudit" | measure).Count

                        $state = 0
                        if ($files -gt $MaxRolloverFiles * 1.2) {
                            $state = 1
                        }
                        "$state`tMSSQL.AuditFiles.$($SQLInstanceName).$($LogPath -replace '\\', '/')$($AuditSufix)`tFiles=$files`tFound $files files of max
 $MaxRolloverFiles files"
                    }
            } catch {
            } finally {
                if ($Reader) { $Reader.Dispose() }
            }
        } catch {
        } finally {
            if ($Command) { $Command.Dispose() }
        }
    } catch {
    } finally {
        if ($_.Connection) { $_.Connection.Dispose() }
    }
}