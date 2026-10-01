DBCC CHECKDB (N'WWI_Portfolio_Diagnostic') WITH TABLOCK, ALL_ERRORMSGS, MAXDOP=1;
SELECT name,type_desc,size*8.0/1024 AS allocated_mb,FILEPROPERTY(name,'SpaceUsed')*8.0/1024 AS used_mb FROM sys.database_files;
SELECT COUNT_BIG(*) AS invoices FROM Sales.Invoices;
