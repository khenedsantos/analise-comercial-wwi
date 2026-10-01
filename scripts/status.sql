SELECT session_id,status,command,wait_type,wait_time,blocking_session_id,percent_complete,total_elapsed_time FROM sys.dm_exec_requests WHERE session_id<>@@SPID AND session_id>50;
SELECT total_physical_memory_kb,available_physical_memory_kb,system_memory_state_desc FROM sys.dm_os_sys_memory;
SELECT session_id,requested_memory_kb,required_memory_kb,granted_memory_kb,wait_time_ms,dop FROM sys.dm_exec_query_memory_grants;
SELECT r.session_id,SUBSTRING(t.text,r.statement_start_offset/2+1,(CASE WHEN r.statement_end_offset=-1 THEN DATALENGTH(t.text) ELSE r.statement_end_offset END-r.statement_start_offset)/2+1) AS current_statement FROM sys.dm_exec_requests r CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t WHERE r.session_id<>@@SPID AND r.session_id>50 AND r.command<>'TASK MANAGER';
