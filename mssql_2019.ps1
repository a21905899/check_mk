[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [string]$ComputerName = '.',
    [switch]$Version = $true,
    [switch]$Counters = $true,
    [switch]$Jobs = $true,
    [switch]$TableSpaces = $true,
    [switch]$Backups = $True,
    [switch]$BackupStatus = $true,
    [switch]$CheckIntegrity = $true,
    [switch]$ReplicaTime = $true,
    [switch]$Mirroring = $true
)

function Get-PerformanceCounters($Context) {
    $Command = $Context.Connection.CreateCommand()
    try {
        $Command.CommandText = @'
select
        counter_name ,
        object_name ,
        instance_name ,
        cntr_value
    from
        sys.dm_os_performance_counters
    where
        object_name not like '%Deprecated%'
'@

        $Reader = $Command.ExecuteReader()
        try {
            $Reader |
                % {
                $ObjectName = $_['object_name'].Trim() -replace '[ $]', '_'
                $CounterName = $_['counter_name'].Trim().ToLower() -replace ' ', '_'
                $InstanceName = $_['instance_name'].Trim() -replace ' ', '_'
                if (-not $InstanceName) { $InstanceName = 'None' }
                $Value = $_['cntr_value']

                "$ObjectName $CounterName $InstanceName $Value"
            }
        }
        catch {
        }
        finally {
            if ($Reader) { $Reader.Dispose() }
        }
    }
    catch {
    }
    finally {
        if ($Command) { $Command.Dispose() }
    }
}

function Get-DatbaseNames($Context) {
    $Command = $Context.Connection.CreateCommand()
    try {
        $Command.CommandText = 'master.dbo.sp_databases'
        $Command.CommandType = 'StoredProcedure'
        $Reader = $Command.ExecuteReader()
        try {
            $Reader |
                % {
                [PSCustomObject]@{
                    DatabaseName        = $_[0];
                    EscapedDatabaseName = $_[0] -replace ' ', '_'
                }
            }
        }
        catch {
        }
        finally {
            if ($Reader) { $Reader.Dispose() }
        }
    }
    catch {
    }
    finally {
        if ($Command) { $Command.Dispose() }
    }
}

function Get-DatabaseAvailabilityState($Context) {
    $Command = $Context.Connection.CreateCommand()
    try {
        $Command.CommandText = @"
       SELECT d.name [DBName], d.state_desc [DBState]
         FROM master.sys.databases d left join
              master.sys.database_mirroring m ON m.database_id = d.database_id
       WHERE d.database_id > 4 
          AND m.mirroring_state_desc IS NULL
"@
        $Reader = $Command.ExecuteReader()
        try {
            $Reader |
                % {
                #"$($Database.EscapedDatabaseName) $($_[0]) $($_[1]) $($_[3])"
                #"$($Database) $($_[0]) $($_[1]) $($_[3])"
                "$($_[0]) $($Context.InstanceId) $($_[1])"
            }
        }
        catch {
        }
        finally {
            if ($Reader) { $Reader.Dispose() }
        }
    }
    catch {
    }
    finally {
        if ($Command) { $Command.Dispose() }
    }
}


function Get-DatbaseSpaceUsed($Context, $Database) {
    $Command = $Context.Connection.CreateCommand()
    try {
        $Command.CommandText = "[$($Database.DatabaseName)].dbo.sp_spaceused"
        $Command.CommandType = 'StoredProcedure'
        $Reader = $Command.ExecuteReader()
        try {
            $Reader |
                % {
                # ' Size of the current database in megabytes. database_size includes both data and log files.
                $dbSize = $_['database_size']
                # Space in the database that has not been reserved for database objects.
                $unallocated = $_['unallocated space']
            }
            $Reader.NextResult() | Out-Null
            $Reader |
                % {
                # Total amount of space allocated by objects in the database.
                $reserved = $_['reserved']
                # Total amount of space used by data.
                $data = $_['data']
                # Total amount of space used by indexes.
                $indexSize = $_['index_size']
                # Total amount of space reserved for objects in the database, but not yet used.
                $unused = $_['unused']
            }

            "$($Context.InstanceId) $($Database.EscapedDatabaseName) $dbSize $unallocated $reserved $data $indexSize $unused"
        }
        catch {
        }
        finally {
            if ($Reader) { $Reader.Dispose() }
        }
    }
    catch {
    }
    finally {
        if ($Command) { $Command.Dispose() }
    }
}

function Get-DatabaseBackups($Context, $Database) {
    $Command = $Context.Connection.CreateCommand()
    try {
        $Command.CommandText = @"
select
        convert(varchar, dateadd(s, datediff(s, '19700101', max(backup_finish_date)), '19700101'), 120) as last_backup_date
    from
        msdb.dbo.backupset
    where
        database_name = '$($Database.DatabaseName)'
"@
        $Reader = $Command.ExecuteReader()
        try {
            $Reader |
                % {
                "$($Context.InstanceId) $($Database.EscapedDatabaseName) $($_['last_backup_date'])"
            }
        }
        catch {
        }
        finally {
            if ($Reader) { $Reader.Dispose() }
        }
    }
    catch {
    }
    finally {
        if ($Command) { $Command.Dispose() }
    }
}

function Get-DiffIntegrity($Context, $Database) {
    $Command = $Context.Connection.CreateCommand()
    try {
        $Command.CommandText = @"
		declare @dbinfo table
		( [ParentObject] varchar(255),
			[Object] varchar(255),
			[Field] varchar(255),
			[Value] varchar(255)
		)
		insert into @dbinfo
		execute( 'DBCC DBINFO(''' + '$($Database.DatabaseName)' + ''') WITH TABLERESULTS' )
		select value, datediff(d, value, GETDATE()) as last_backup_date
		from @dbinfo where Field = 'dbi_dbccLastKnownGood'
"@
        $Reader = $Command.ExecuteReader()
        try {
            $Reader |
                % {
                "$($Context.InstanceId) $($Database.EscapedDatabaseName) $($_['last_backup_date'])"
            }
        }
        catch {
        }
        finally {
            if ($Reader) { $Reader.Dispose() }
        }
    }
    catch {
    }
    finally {
        if ($Command) { $Command.Dispose() }
    }
}

function Get-DatabaseMirroringState($Context) {
    $Command = $Context.Connection.CreateCommand()
    try {
        $Command.CommandText = @"
IF OBJECT_ID('msdb.[dbo].[dbm_monitor_data]') IS NOT NULL
SELECT d.name [DBName], d.state_desc [DBState]
            , DATEDIFF(second, mon.Time, GETUTCDATE()) [MirroringDelaySeconds]
         FROM master.sys.databases d 
        inner join (select database_id, max(time) [Time] from msdb.[dbo].[dbm_monitor_data] group by database_id) mon
                      on mon.database_id = d.database_id
                      left join master.sys.database_mirroring m ON m.database_id = d.database_id
"@
        $Reader = $Command.ExecuteReader()
        try {
            $Reader |
                % {
                "$($_[0]) $($Context.InstanceId) $($_['MirroringDelaySeconds'])"
            }
        }
        catch {
        }
        finally {
            if ($Reader) { $Reader.Dispose() }
        }
    }
    catch {
    }
    finally {
        if ($Command) { $Command.Dispose() }
    }
}

function Get-Estimated-Recovery-Time-seconds($Context, $Database) {
    $Command = $Context.Connection.CreateCommand()
    try {
        $Command.CommandText = @"
		IF CAST(SERVERPROPERTY('ProductVersion') AS varchar(50)) NOT LIKE '8%' AND CAST(SERVERPROPERTY('ProductVersion') AS varchar(50)) NOT LIKE '9%' AND CAST(SERVERPROPERTY('ProductVersion') AS varchar(50)) NOT LIKE '10%'
		BEGIN
SELECT replica_server_name
     , CAST(DB_NAME(database_id)as VARCHAR(40)) database_name
       , Convert(VARCHAR(20),last_commit_time,22) last_commit_time
     , CAST(CAST((DATEDIFF(s,last_commit_time,GetDate())) as varchar) as VARCHAR(30)) time_behind_primary
     , redo_queue_size
     , redo_rate
     , (redo_queue_size/redo_rate) [estimated_recovery_time_seconds]
     , CONVERT(VARCHAR(20),GETDATE(),22) [current_time]
  FROM sys.dm_hadr_database_replica_states drs
INNER JOIN sys.availability_replicas ar on drs.replica_id = ar.replica_id AND drs.group_id = ar.group_id
WHERE last_redone_time is not null
        END
"@
        $Reader = $Command.ExecuteReader()
        try {
            $Reader |
                % {
                "$($Context.InstanceId) $($Database.EscapedDatabaseName) $($_['estimated_recovery_time_seconds'])"
            }
        }
        catch {
        }
        finally {
            if ($Reader) { $Reader.Dispose() }
        }
    }
    catch {
    }
    finally {
        if ($Command) { $Command.Dispose() }
    }
}

function Get-DatabaseBackupStatus($Context, $Databases) {
    $Command = $Context.Connection.CreateCommand()
    try {
        $Command.CommandText = @"
/* Validacao dos BACKUPS PARA BDs
	FULL:
		1. Verificar que todos os Full Backups foram efectuados com um intervalo <= 7 dias em relação a GETDATE();
	
	DIFERENCIAL:
	2. Verificar que o ultimo backup diferencial foi efectuado de acordo com os seguintes intervalos em relação a GETDATE();
		2.1. Se o backup diferencial tiver sido feito com intervalo > 1 dia e <= 2 dias, então NÃO é considerado critico;
		2.2. Se o backup diferencial tiver sido feito com intervalo > 2 dias então É considerado critico;
		
	T_LOG:
	3. Verificar que foram efectuados backups de acordo com as seguintes regras:
		3.1. SE backup anterior ao ultimo bckLOG (L) for Diferencial (I) E é 2ª feira ENTÃO o intervalo tem que ser <= 260 minutos.
		3.2. SE backup anterior ao ultimo bckLOG (L) for Diferencial (I) E NÃO é 2ª feira ENTÃO o intervalo tem que ser <= 500 minutos.
		3.3. SE backup anterior ao ultimo bckLOG (L) for Log (L) ENTÃO o intervalo tem que ser <= 250 minutos.
*/

SET DATEFIRST 7 --Primeiro dia da semana é domingo

IF OBJECT_ID('tempdb..#BACKUPS') IS NOT NULL
	DROP TABLE #BACKUPS

CREATE TABLE #BACKUPS (database_id smallint, device_type tinyint, [type] varchar(5), backup_start_date datetime, RecoveryModel sql_variant)

--Lista de Backups feitos pelo NetBackup com um intervalo <= 7 dias em relação a hoje:
--SQL 2000 não tem campo is_copy_only
IF CAST(SERVERPROPERTY('ProductVersion') AS varchar(50)) NOT LIKE '8%'
BEGIN
	EXEC('
			INSERT INTO #BACKUPS (database_id, device_type, [type], backup_start_date, RecoveryModel)
			SELECT DB_ID(bcks.database_name) AS database_id, bckMF.device_type, bckS.type, bckS.backup_start_date, DATABASEPROPERTYEX(bcks.database_name, ''recovery'') as RecoveryModel
			FROM  msdb.dbo.backupset bckS INNER JOIN msdb.dbo.backupmediaset bckMS
			ON bckS.media_set_id = bckMS.media_set_id
			INNER JOIN msdb.dbo.backupmediafamily bckMF 
			ON bckMS.media_set_id = bckMF.media_set_id
			WHERE bckS.is_copy_only = 0
			AND DATEDIFF(DD, bckS.backup_start_date, GETDATE()) <= 7 
			AND bckMF.device_type = 7 --Virtual Device
		')	
END
ELSE
BEGIN
	EXEC('
		INSERT INTO #BACKUPS (database_id, device_type, [type], backup_start_date, RecoveryModel)
		SELECT DB_ID(bcks.database_name) AS database_id, bckMF.device_type, bckS.type, bckS.backup_start_date, DATABASEPROPERTYEX(bcks.database_name, ''recovery'') as RecoveryModel
		FROM  msdb.dbo.backupset bckS INNER JOIN msdb.dbo.backupmediaset bckMS
		ON bckS.media_set_id = bckMS.media_set_id
		INNER JOIN msdb.dbo.backupmediafamily bckMF 
		ON bckMS.media_set_id = bckMF.media_set_id
		WHERE DATEDIFF(DD, bckS.backup_start_date, GETDATE()) <= 7 
		AND bckMF.device_type = 7 --Virtual Device	
	')
END

--VALIDACAO DE FULLBACKUPS:
IF OBJECT_ID('tempdb..#FULL_BACKUPS') IS NOT NULL
	DROP TABLE #FULL_BACKUPS

--Lista dos ultimos FullBackups efectuados por BD:
SELECT database_id, MAX(backup_start_date) AS backup_start_date
INTO #FULL_BACKUPS
FROM #BACKUPS
WHERE type = 'D'
GROUP BY database_id	


--VALIDACAO DE BACKUPS DIFERENCIAIS:
IF OBJECT_ID('tempdb..#DIF_BACKUPS') IS NOT NULL
	DROP TABLE #DIF_BACKUPS

--Lista dos ultimos backups diferenciais efectuados por BD, a partir das BDs que têm os Full OK:
--	SE intervalo <= 1 dias em relação GETDATE() ENTAO BCK_STATUS = 1 <=> OK
--	SE intervalo > 1 e <= 2 em relação a GETDATE() ENTAO BCK_STATUS = 2 <=> OK Parcial
--	ELSE NOT OK  
SELECT database_id, MAX(backup_start_date) AS backup_start_date, CASE WHEN DATEDIFF(DD, MAX(backup_start_date), GETDATE()) <= 1 THEN 1 ELSE 2 END AS BCK_STATUS
INTO #DIF_BACKUPS
FROM #BACKUPS
WHERE type = 'I'
AND DATEDIFF(DD, backup_start_date, GETDATE()) <= 2
AND database_id IN (SELECT database_id FROM #FULL_BACKUPS)
GROUP BY database_id


--VALIDACAO DE BACKUPS T_LOGS:
IF OBJECT_ID('tempdb..#VALID_LOG_BACKUPS') IS NOT NULL
	DROP TABLE #LAST_BACKUP, #VALID_LOG_BACKUPS

--Tabela que guarda os VALID_LOG_BACKUPS:
--BCK_STATUS = 1 <=> OK
--BCK_STATUS = 2 <=> OK Parcial
--ELSE NOT OK
CREATE TABLE #VALID_LOG_BACKUPS (database_id int, BCK_STATUS int)


--SE backup anterior ao ultimo bckLOG (L) for Diferencial (I) E é 2ª feira ENTÃO o intervalo tem que ser <= 260 minutos.
--SE backup anterior ao ultimo bckLOG (L) for Diferencial (I) E NÃO é 2ª feira ENTÃO o intervalo tem que ser <= 500 minutos.
--SE backup anterior ao ultimo bckLOG (L) for Log (L) ENTÃO o intervalo tem que ser <= 250 minutos.

--Criar uma tabela com os ultimos BCKs realizados a cada BD, cujo RM é diferente de SIMPLE:
SELECT database_id, [type] as UltimoBCK_type, backup_start_date as UltimoBCK_StartDate
INTO #LAST_BACKUP
FROM #BACKUPS B_OUT
WHERE RecoveryModel <> 'SIMPLE'
AND backup_start_date = (SELECT MAX(B.backup_start_date) FROM #BACKUPS B WHERE B.database_id = B_OUT.database_id)

--Aplicar agora as regras:
INSERT INTO #VALID_LOG_BACKUPS (database_id, BCK_STATUS)
SELECT	database_id, 
		CASE 
			--Full ao domingo:
			WHEN UltimoBCK_type = 'D' AND DATEDIFF(MI,UltimoBCK_StartDate, GETDATE()) < 1700 THEN 1
			--Diferencial e Log à segunda-feira:
			WHEN UltimoBCK_type = 'I' AND DATEPART(weekday, UltimoBCK_StartDate) = 2 AND DATEDIFF(MI,UltimoBCK_StartDate,GETDATE()) <= 260 THEN 1
			--Diferencial e Log fora de segunda-feira:
			WHEN UltimoBCK_type = 'I' AND DATEPART(weekday, UltimoBCK_StartDate) <> 2 AND DATEDIFF(MI,UltimoBCK_StartDate,GETDATE()) <= 500 THEN 1
			--Log e Log:
			WHEN  UltimoBCK_type = 'L' AND DATEDIFF(MI,UltimoBCK_StartDate, GETDATE()) <= 250 THEN 1
			--Log e Log com o ultimo falhado e o penultimo ok
			WHEN UltimoBCK_type = 'L' AND DATEDIFF(MI,UltimoBCK_StartDate, GETDATE()) > 250 AND DATEDIFF(MI,UltimoBCK_StartDate, GETDATE()) <= 500 THEN 2
		END AS BCK_STATUS
		 
FROM #LAST_BACKUP

 
--AlwaysOn: 
IF OBJECT_ID('tempdb..#ALWAYSON_REPLICA_ROLE_DESC') IS NOT NULL
	DROP TABLE #ALWAYSON_REPLICA_ROLE_DESC

CREATE TABLE #ALWAYSON_REPLICA_ROLE_DESC (database_id int, name sysname, RoleDesc nvarchar(100)) 
	
IF CAST(SERVERPROPERTY('ProductVersion') AS varchar(50)) LIKE '11.%'
BEGIN

	INSERT INTO #ALWAYSON_REPLICA_ROLE_DESC (database_id, name, RoleDesc)
	SELECT d.dbid, d.name, ISNULL(ars.role_desc, 'PRIMARY') as RoleDesc
	FROM (master.dbo.sysdatabases d
	LEFT JOIN (sys.dm_hadr_database_replica_states DRS 
	INNER JOIN sys.dm_hadr_availability_replica_states ARS 
	ON DRS.group_id = ARS.group_id AND DRS.replica_id = ARS.replica_id)
	ON d.dbid = DRS.database_id)
	WHERE (ARS.is_local = 1) OR (DRS.database_id IS NULL)
END
ELSE
BEGIN
	INSERT INTO #ALWAYSON_REPLICA_ROLE_DESC (database_id, name, RoleDesc)
	SELECT d.dbid, d.name, 'PRIMARY' as RoleDesc
	FROM master.dbo.sysdatabases d	
END


--Devolucao de Resultado:
IF OBJECT_ID('tempdb..#FINAL') IS NOT NULL
	DROP TABLE #FINAL


CREATE TABLE #FINAL (database_id int, name sysname, RecoveryModelDesc nvarchar(100), BCK_STATUS_FULL int NULL, BCK_STATUS_DIF int NULL, BCK_STATUS_LOG int NULL, RoleDesc nvarchar(100) NULL, BackupsToDisk bit NULL)

--Nota: a tempdb e a DBA_GIIT não são consideradas
INSERT INTO #FINAL (database_id, name, RecoveryModelDesc)
SELECT dbid, name, CAST(DATABASEPROPERTYEX(d.name, 'recovery') AS nvarchar(120))
FROM master.dbo.sysdatabases d
WHERE name NOT IN ('tempdb', 'DBA_GIIT')


--Juntar os estados dos BCKs:
UPDATE #FINAL SET BCK_STATUS_FULL = 1
FROM #FINAL INNER JOIN #FULL_BACKUPS
ON #FINAL.database_id = #FULL_BACKUPS.database_id


UPDATE #FINAL SET BCK_STATUS_DIF = #DIF_BACKUPS.BCK_STATUS
FROM #FINAL INNER JOIN #DIF_BACKUPS
ON #FINAL.database_id = #DIF_BACKUPS.database_id

UPDATE #FINAL SET BCK_STATUS_LOG = #VALID_LOG_BACKUPS.BCK_STATUS
FROM #FINAL INNER JOIN #VALID_LOG_BACKUPS
ON #FINAL.database_id = #VALID_LOG_BACKUPS.database_id


--Juntar a componente de ALWAYSON:
UPDATE #FINAL SET RoleDesc = #ALWAYSON_REPLICA_ROLE_DESC.RoleDesc
FROM #FINAL INNER JOIN #ALWAYSON_REPLICA_ROLE_DESC
ON #FINAL.database_id = #ALWAYSON_REPLICA_ROLE_DESC.database_id


--Juntar Verificacao de backups (Nao COPY_ONLY) para disco que comprometam a sequencia de backups (apenas para > SQL 2000):
IF CAST(SERVERPROPERTY('ProductVersion') AS varchar(50)) NOT LIKE '8%'
BEGIN
	EXEC( '
			UPDATE #FINAL SET BackupsToDisk = T_BCK_TO_DISK.BCK_TO_DISK
			FROM #FINAL INNER JOIN 
			(
				SELECT DISTINCT DB_ID(bcks.database_name) AS database_id, 1 AS BCK_TO_DISK
				FROM  msdb.dbo.backupset bckS INNER JOIN msdb.dbo.backupmediaset bckMS
				ON bckS.media_set_id = bckMS.media_set_id
				INNER JOIN msdb.dbo.backupmediafamily bckMF 
				ON bckMS.media_set_id = bckMF.media_set_id
				WHERE bckS.is_copy_only = 0
				AND DATEDIFF(DD, bckS.backup_start_date, GETDATE()) <= 7 
				AND bckMF.device_type = 2 --Disk
				AND bcks.backup_start_date > (SELECT MAX(backup_start_date) FROM #FULL_BACKUPS FB WHERE DB_ID(bcks.database_name) = FB.database_id)
			) T_BCK_TO_DISK
			ON #FINAL.database_id = T_BCK_TO_DISK.database_id
		')
END


--Query de Resultado:
SELECT BaseDados, 
CASE 
	WHEN BCK_STATUS_FULL = '' AND BCK_STATUS_DIF = '' AND BCK_STATUS_LOG = '' AND BCK_TO_DISK = '' THEN 'OK'
	WHEN BCK_STATUS_FULL = 'NA' AND BCK_STATUS_DIF = 'NA' AND BCK_STATUS_LOG = 'NA' THEN 'NA'
	ELSE BCK_STATUS_FULL + '  ' + BCK_STATUS_DIF + '  ' + BCK_STATUS_LOG + '  ' + BCK_TO_DISK
END AS EstadoBCKs

FROM
(
SELECT name AS BaseDados, RecoveryModelDesc,
--FULL:
CASE 
	WHEN (RoleDesc = 'PRIMARY') AND (ISNULL(BCK_STATUS_FULL, 0) <> 1) THEN 'FALTA_BCK_FULL'
	WHEN (RoleDesc = 'SECONDARY') THEN 'NA'
	ELSE ''
END AS BCK_STATUS_FULL,

--DIFs:
CASE
	WHEN (RoleDesc = 'PRIMARY') AND (BCK_STATUS_DIF = 1 OR name = 'master') THEN ''
	WHEN (RoleDesc = 'PRIMARY') AND (ISNULL(BCK_STATUS_DIF, 0) NOT IN (1,2) AND name <> 'master') THEN 'FALTAM_BCKs_DIFERENCIAIS'
	WHEN (RoleDesc = 'SECONDARY') THEN 'NA'
	ELSE ''
END AS BCK_STATUS_DIF,

--LOGS:
CASE 
	WHEN (RoleDesc = 'PRIMARY') AND ((BCK_STATUS_LOG = 1) OR (RecoveryModelDesc = 'SIMPLE') OR (name IN ('master', 'model', 'msdb'))) THEN ''
	WHEN (RoleDesc = 'PRIMARY') AND (ISNULL(BCK_STATUS_LOG, 0) NOT IN (1,2) AND RecoveryModelDesc <> 'SIMPLE' AND name NOT IN ('master', 'model', 'msdb')) THEN 'FALTAM_BCKs_T_LOG'
	WHEN (RoleDesc = 'SECONDARY') THEN 'NA'
	ELSE ''
END AS BCK_STATUS_LOG,

--BCKs TO DISK:
CASE
	WHEN ISNULL(BackupsToDisk, 0) = 1 THEN 'BCKs_REALIZADOS_PARA_DISCO'
	ELSE ''
END AS BCK_TO_DISK	

FROM #FINAL
) RESULTADO_FINAL
"@
        $Reader = $Command.ExecuteReader()
        try {
            $Reader |
                % {
                $Row = $_
                $EscapedDatabaseName = ($Databases | ? { $_.DatabaseName -eq $Row[0] }).EscapedDatabaseName
                if ($EscapedDatabaseName) {
                    "$($Context.InstanceId) $EscapedDatabaseName $($Row[1])"
                }
            }
        }
        catch {
        }
        finally {
            if ($Reader) { $Reader.Dispose() }
        }
    }
    catch {
    }
    finally {
        if ($Command) { $Command.Dispose() }
    }
}

function Get-SynchronizationHealth($Context, $Database) {
    $Command = $Context.Connection.CreateCommand()
    try {
        $Command.CommandText = 
        @"
SELECT DISTINCT
    rcs.database_name,
    ar.replica_server_name,
    drs.synchronization_state_desc,
    drs.synchronization_health_desc,
    CASE rcs.is_failover_ready
        WHEN 0 THEN 'Data Loss'
        WHEN 1 THEN 'No Data Loss'
        ELSE ''
    END AS FailoverReady
FROM
    sys.dm_hadr_database_replica_states drs INNER JOIN sys.availability_replicas ar on drs.replica_id = ar.replica_id AND drs.group_id = ar.group_id
    INNER JOIN sys.dm_hadr_database_replica_cluster_states rcs ON drs.replica_id = rcs.replica_id
ORDER BY
    replica_server_name
"@
        $Reader = $Command.ExecuteReader()
        try {
            $Reader | % {
                "$($Database.EscapedDatabaseName) $($_[0]) $($_[1]) $($_[3])"
            }
        }
        catch {
        }
        finally {
            if ($Reader) { $Reader.Dispose() }
        }
    }
    catch {
    }
    finally {
        if ($Command) { $Command.Dispose() }
    }
}

function Get-JobStatus($Context) {
    $Command = $Context.Connection.CreateCommand()
    try {
        $Command.CommandText = @'
select
        j.[name] as [JobName] ,
        case h.run_status
          when 0 then 'Failed'
          when 1 then 'Succeeded'
          when 2 then 'Retry'
          when 3 then 'Canceled'
          when 4 then 'In progress'
        end as run_status ,
        h.run_date as LastRunDate ,
        h.run_time as LastRunTime
    from
        msdb.dbo.sysjobhistory h
        inner join msdb.dbo.sysjobs j
            on h.job_id = j.job_id
    where
        j.enabled = 1
        and h.instance_id in (select
                                    max(h.instance_id)
                                from
                                    msdb.dbo.sysjobhistory h
                                group by
                                    (h.job_id))
'@
        $Reader = $Command.ExecuteReader()
        try {
            $Reader |
                % {
                "$($Context.InstanceId) $($_['JobName'])`t$($_['run_status'])`t$($_['LastRunDate'])`t$($_['LastRunTime'])"
            }
        }
        catch {
        }
        finally {
            if ($Reader) { $Reader.Dispose() }
        }
    }
    catch {
    }
    finally {
        if ($Command) { $Command.Dispose() }
    }
}

function Get-SynchronizationHealth($Context, $Database) {
    $Command = $Context.Connection.CreateCommand()
    try {
        $Command.CommandText = @"
SELECT DISTINCT 
rcs.database_name,
ar.replica_server_name,
       drs.synchronization_state_desc,
drs.synchronization_health_desc,
CASE rcs.is_failover_ready
WHEN 0 THEN 'Data Loss'
WHEN 1 THEN 'No Data Loss'
ELSE ''
END AS FailoverReady
FROM
sys.dm_hadr_database_replica_states drs INNER JOIN sys.availability_replicas ar on drs.replica_id = ar.replica_id AND drs.group_id = ar.group_id
INNER JOIN sys.dm_hadr_database_replica_cluster_states rcs ON drs.replica_id = rcs.replica_id
ORDER BY
replica_server_name

"@
        $Reader = $Command.ExecuteReader()
        try {
            $Reader |
                % {
                "$($Database.EscapedDatabaseName) $($_[0]) $($_[1]) $($_[3])"
            }
        }
        finally {
            if ($Reader) { $Reader.Dispose() }
        }
    }
    finally {
        if ($Command) { $Command.Dispose() }
    }
}

(Get-Host).UI.RawUI.BufferSize = New-Object -TypeName System.Management.Automation.Host.Size(150, 9999)

# Dummy empty output. 
# Contains timeout error if this scripts runtime exceeds the timeout
#'<<<mssql_versions>>>'

$Contexts = Get-WmiObject -ComputerName $ComputerName -Namespace root -Class __NAMESPACE -Property Name, __NAMESPACE |
    ? { $_.Name -eq 'Microsoft' } |
    % { Get-WmiObject -ComputerName $ComputerName -Namespace "$($_.__NAMESPACE)\$($_.Name)" -Class __NAMESPACE -Property Name, __NAMESPACE } |
    ? { $_.Name -eq 'SqlServer' } |
    % { Get-WmiObject -ComputerName $ComputerName -Namespace "$($_.__NAMESPACE)\$($_.Name)" -Class __NAMESPACE -Property Name, __NAMESPACE } |
    ? { $_.Name -like 'ComputerManagement*' } |
    % {
    Get-WmiObject -ComputerName $ComputerName -Namespace "$($_.__NAMESPACE)\$($_.Name)" -Class SqlServiceAdvancedProperty -Filter 'SQLServiceType = 1 AND PropertyName = "VERSION"' |
        % {
        $Context = [PSCustomObject]@{
            InstanceId          = $_.ServiceName -replace '\$', '_';
            ServiceName         = $_.ServiceName;
            InstanceName        = $null;
            DatabaseName        = $null;
            EscapedDatabaseName = $null;
            Connection          = $null;
            ComputerName        = $ComputerName;
            Version             = $_.PropertyStrValue
        }
        $Context.InstanceName = $(if ($_.ServiceName -eq 'MSSQLSERVER') { $null } else { ($_.ServiceName -split '\$' | select -Last 1) })

        $Context
    }
}

if ($Version) {
    $Contexts |
        % {
        '<<<mssql_versions>>>'
        "$($_.InstanceId)  $($_.Version)"
    }
}

$Contexts |
    % {
        
    $Context = $_
    Get-WmiObject -ComputerName $Context.ComputerName -Class Win32_Service -Filter "Name = '$($Context.ServiceName)' and State = 'Running'" |
        % {
        $Context.Connection = New-Object -TypeName System.Data.SqlClient.SqlConnection "Data Source=$($Context.ComputerName)$(if($Context.InstanceName){"\$($Context.InstanceName)"});Integrated Security=True"
        try {
            $Context.Connection.Open()

            if ($Counters) {
                '<<<mssql_counters>>>'
                Get-PerformanceCounters -Context $Context
            }

            if ($Jobs) {
                '<<<mssql_jobs:sep(9)>>>'
                Get-JobStatus -Context $Context
            }

            '<<<mssql_DatabaseAvailabilityState>>>'
            Get-DatabaseAvailabilityState -Context $Context 

            '<<<mssql_DatabaseMirroringState>>>'
            Get-DatabaseMirroringState -Context $Context
			
            $Databases = Get-DatbaseNames -Context $Context

            if ($Counters) {
                '<<<mssql_tablespaces>>>'
                $Databases |
                    % {
                    Get-DatbaseSpaceUsed -Context $Context -Database $_
                }
            }

            if ($Backups) {
                '<<<mssql_backup>>>'
                $Databases | ? { $_.DatabaseName -ne 'tempdb' } |
                    % {
                    Get-DatabaseBackups -Context $Context -Database $_
                }
            }
				
            if ($CheckIntegrity) {
                '<<<mssql_diff_integrity>>>'
                Get-DiffIntegrity -Context $Context -Database $_
            }

            if ($ReplicaTime) {
                '<<<mssql_replica_time>>>'
                Get-Estimated-Recovery-Time-seconds -Context $Context -Databases $Databases
            }
            if ($BackupStatus) {
                '<<<mssql_backupstatus>>>'
                Get-DatabaseBackupStatus -Context $Context -Databases $Databases
            }

            if ($Databases) {
                if ($Context.InstanceID -ne 'MSSQLSERVER') {
                    '<<<mssql_SynchronizationHealth>>>'
                    Get-SynchronizationHealth -Context $Context -Databases $Databases $_
                }
            }
        }
        catch {
        }
        finally {
            if ($_.Connection) { $_.Connection.Dispose() }
        }
    }
}
