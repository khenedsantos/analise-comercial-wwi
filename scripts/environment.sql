SELECT @@VERSION AS version,SERVERPROPERTY('Edition') AS edition,SERVERPROPERTY('ProductVersion') AS product_version;
SELECT name,state_desc,compatibility_level,recovery_model_desc FROM sys.databases WHERE name='WWI_Portfolio_Diagnostic';
SELECT name,value_in_use FROM sys.configurations WHERE name IN ('max degree of parallelism','max server memory (MB)');
SELECT SYSDATETIMEOFFSET() AS captured_at;
