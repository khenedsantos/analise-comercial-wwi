-- Cancel only this project's active integrity check so it can be retried serially.
DECLARE @sid int;
SELECT @sid=r.session_id FROM sys.dm_exec_requests r JOIN sys.dm_exec_sessions s ON r.session_id=s.session_id
WHERE r.database_id=DB_ID('WWI_Portfolio_Diagnostic') AND r.wait_type='RESOURCE_SEMAPHORE' AND s.program_name='WWI Stage2 Audit';
IF @sid IS NOT NULL EXEC('KILL '+@sid);
