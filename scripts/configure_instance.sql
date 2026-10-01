-- Dedicated diagnostic instance only: constrain parallelism and memory use.
EXEC sys.sp_configure 'show advanced options',1;
RECONFIGURE;
EXEC sys.sp_configure 'max degree of parallelism',1;
EXEC sys.sp_configure 'max server memory (MB)',512;
RECONFIGURE;
SELECT name,value_in_use FROM sys.configurations WHERE name IN ('max degree of parallelism','max server memory (MB)');
