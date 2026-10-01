SELECT @@VERSION AS engine_version;
RESTORE HEADERONLY FROM DISK = N'{{PROJECT_ROOT_SQL}}\data\raw\WideWorldImporters-Standard.bak';
RESTORE FILELISTONLY FROM DISK = N'{{PROJECT_ROOT_SQL}}\data\raw\WideWorldImporters-Standard.bak';
RESTORE VERIFYONLY FROM DISK = N'{{PROJECT_ROOT_SQL}}\data\raw\WideWorldImporters-Standard.bak';
