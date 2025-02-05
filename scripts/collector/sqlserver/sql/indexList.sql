/*
Copyright 2023 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

SET NOCOUNT ON;
SET LANGUAGE us_english;
DECLARE @PKEY AS VARCHAR(256)
SELECT @PKEY = N'$(pkey)';
DECLARE @dbname VARCHAR(50)
DECLARE db_cursor CURSOR FOR 
SELECT name 
FROM MASTER.dbo.sysdatabases 
WHERE name NOT IN ('master','model','msdb','tempdb')

IF OBJECT_ID('tempdb..#indexList') IS NOT NULL  
   DROP TABLE #objectList;

CREATE TABLE #indexList(
   database_name nvarchar(255),
   schema_name nvarchar(255),
   table_name nvarchar(255),
   index_name nvarchar(255),
   index_type nvarchar(255),
   is_primary_key nvarchar(10),
   is_unique nvarchar(10),
   fill_factor nvarchar(10),
   allow_page_locks nvarchar(10),
   has_filter nvarchar(10),
   data_compression nvarchar(10),
   data_compression_desc nvarchar(255),
   is_partitioned nvarchar(255),
   count_key_ordinal nvarchar(10),
   count_partition_ordinal nvarchar(10),
   count_is_included_column nvarchar(10),
   total_space_mb nvarchar(255)
   );

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @dbname  

WHILE @@FETCH_STATUS = 0  
BEGIN
	exec ('
      use [' + @dbname + '];
      INSERT INTO #indexList
      SELECT
         DB_NAME() as database_name
         ,s.name schema_name
         ,t.name  table_name 
         ,i.name  index_name
         ,i.type_desc index_type
         ,i.is_primary_key
         ,i.is_unique
         ,i.fill_factor
         ,i.allow_page_locks
         ,i.has_filter
         ,p.data_compression
         ,p.data_compression_desc
         ,ISNULL (ps.name, ''Not Partitioned'') AS partition_scheme
         ,ISNULL (SUM(ic.key_ordinal),0) AS count_key_ordinal
         ,ISNULL (SUM(ic.partition_ordinal),0) AS count_partition_ordinal
         ,ISNULL (COUNT(ic.is_included_column),0) as count_is_included_column
         ,CONVERT(nvarchar, ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2)) AS total_space_mb
      FROM sys.indexes i
      JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
      JOIN sys.tables t ON i.object_id = t.object_id
      JOIN sys.schemas s ON s.schema_id = t.schema_id
      JOIN sys.partitions AS p ON p.OBJECT_ID = i.OBJECT_ID AND p.index_id = i.index_id
      JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
      LEFT JOIN sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
      GROUP BY 
         s.name 
         ,t.name   
         ,i.name  
         ,i.type_desc 
         ,i.is_primary_key
         ,i.is_unique
         ,i.fill_factor
         ,i.allow_page_locks
         ,i.has_filter
         ,p.data_compression
         ,p.data_compression_desc
	      ,ISNULL (ps.name, ''Not Partitioned'')');
    FETCH NEXT FROM db_cursor INTO @dbname 
END 

CLOSE db_cursor  
DEALLOCATE db_cursor

SELECT @PKEY as PKEY, a.* from #indexList a;

DROP TABLE #indexList;