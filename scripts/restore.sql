IF DB_ID(N'WWI_Portfolio_Diagnostic') IS NOT NULL
    THROW 50001, 'Database already exists: restore refused to avoid overwriting.', 1;
RESTORE DATABASE [WWI_Portfolio_Diagnostic]
FROM DISK = N'{{PROJECT_ROOT_SQL}}\data\raw\WideWorldImporters-Standard.bak'
WITH MOVE N'WWI_Primary' TO N'{{PROJECT_ROOT_SQL}}\data\sqlserver\WWI_Primary.mdf',
     MOVE N'WWI_UserData' TO N'{{PROJECT_ROOT_SQL}}\data\sqlserver\WWI_UserData.ndf',
     MOVE N'WWI_Log' TO N'{{PROJECT_ROOT_SQL}}\data\sqlserver\WWI_Log.ldf',
     RECOVERY, STATS=10;
SELECT name,state_desc,compatibility_level,recovery_model_desc FROM sys.databases WHERE name=N'WWI_Portfolio_Diagnostic';
