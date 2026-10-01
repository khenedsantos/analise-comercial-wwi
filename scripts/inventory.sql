SET NOCOUNT ON;
SELECT 'inventory' AS section,SCHEMA_NAME(t.schema_id) AS schema_name,t.name,t.temporal_type_desc,
 SUM(p.rows) AS rows FROM sys.tables t JOIN sys.partitions p ON t.object_id=p.object_id AND p.index_id IN (0,1)
 GROUP BY t.schema_id,t.name,t.temporal_type_desc ORDER BY 2,3;
SELECT 'columns' AS section,SCHEMA_NAME(t.schema_id) AS schema_name,t.name AS table_name,c.column_id,c.name AS column_name,
 ty.name AS data_type,c.max_length,c.precision,c.scale,c.is_nullable,CONVERT(nvarchar(max),ep.value) AS description
FROM sys.tables t JOIN sys.columns c ON t.object_id=c.object_id JOIN sys.types ty ON c.user_type_id=ty.user_type_id
LEFT JOIN sys.extended_properties ep ON ep.major_id=c.object_id AND ep.minor_id=c.column_id AND ep.name='Description'
WHERE SCHEMA_NAME(t.schema_id) IN ('Sales','Warehouse','Application') AND t.temporal_type<>1
ORDER BY 2,3,4;
SELECT 'foreign_keys' AS section,f.name,OBJECT_SCHEMA_NAME(f.parent_object_id) AS parent_schema,OBJECT_NAME(f.parent_object_id) AS parent_table,
 COL_NAME(fc.parent_object_id,fc.parent_column_id) AS parent_column,OBJECT_SCHEMA_NAME(f.referenced_object_id) AS referenced_schema,
 OBJECT_NAME(f.referenced_object_id) AS referenced_table,COL_NAME(fc.referenced_object_id,fc.referenced_column_id) AS referenced_column,f.is_disabled,f.is_not_trusted
FROM sys.foreign_keys f JOIN sys.foreign_key_columns fc ON f.object_id=fc.constraint_object_id ORDER BY 3,4,5;
SELECT 'modules' AS section,OBJECT_SCHEMA_NAME(m.object_id) AS schema_name,OBJECT_NAME(m.object_id) AS object_name,m.definition
FROM sys.sql_modules m WHERE m.definition LIKE '%LineProfit%' OR m.definition LIKE '%IsCreditNote%';
SELECT 'pk' AS section,SCHEMA_NAME(t.schema_id) AS schema_name,t.name AS table_name,i.name AS constraint_name,c.name AS key_column
FROM sys.tables t JOIN sys.indexes i ON t.object_id=i.object_id AND i.is_primary_key=1
JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id
JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
WHERE t.temporal_type<>1 ORDER BY 2,3,ic.key_ordinal;
