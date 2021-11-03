IF OBJECT_ID('tSQLt.Private_GetDropItemCmd') IS NOT NULL DROP FUNCTION tSQLt.Private_GetDropItemCmd;
GO
---Build+
GO
CREATE FUNCTION tSQLt.Private_GetDropItemCmd
(
/*SnipParamStart: CreateDropClassStatement.ps1*/
  @FullName NVARCHAR(MAX),
  @ItemType NVARCHAR(MAX)
/*SnipParamEnd: CreateDropClassStatement.ps1*/
)
RETURNS TABLE
AS
RETURN
/*SnipStart: CreateDropClassStatement.ps1*/
SELECT
    'DROP ' +
    CASE @ItemType 
      WHEN 'IF' THEN 'FUNCTION'
      WHEN 'TF' THEN 'FUNCTION'
      WHEN 'FN' THEN 'FUNCTION'
      WHEN 'FT' THEN 'FUNCTION'
      WHEN 'P' THEN 'PROCEDURE'
      WHEN 'PC' THEN 'PROCEDURE'
      WHEN 'SN' THEN 'SYNONYM'
      WHEN 'U' THEN 'TABLE'
      WHEN 'V' THEN 'VIEW'
      WHEN 'type' THEN 'TYPE'
      WHEN 'xml_schema_collection' THEN 'XML SCHEMA COLLECTION'
      WHEN 'schema' THEN 'SCHEMA'
     END+
     ' ' + 
     @FullName + 
     ';' AS cmd
/*SnipEnd: CreateDropClassStatement.ps1*/
GO
---Build-
/*
Object type:
  AF = Aggregate function (CLR)
-  C = CHECK constraint
-  D = DEFAULT (constraint or stand-alone)
-  F = FOREIGN KEY constraint
+  FN = SQL scalar function
  FS = Assembly (CLR) scalar-function
+  FT = Assembly (CLR) table-valued function
+  IF = SQL inline table-valued function
  IT = Internal table
+  P = SQL Stored Procedure
+  PC = Assembly (CLR) stored-procedure
-  PG = Plan guide
-  PK = PRIMARY KEY constraint
?  R = Rule (old-style, stand-alone)
  RF = Replication-filter-procedure
-  S = System base table
  SN = Synonym
  SO = Sequence object
+  U = Table (user-defined)
+  V = View
-  EC = Edge constraint

Applies to: SQL Server 2012 (11.x) and later.
  SQ = Service queue
 - TA = Assembly (CLR) DML trigger
 + TF = SQL table-valued-function
 - TR = SQL DML trigger
  TT = Table type
 - UQ = UNIQUE constraint
 ? X = Extended stored procedure

Applies to: SQL Server 2014 (12.x) and later, Azure SQL Database, Azure Synapse Analytics, Analytics Platform System (PDW).
 ? ST = STATS_TREE

Applies to: SQL Server 2016 (13.x) and later, Azure SQL Database, Azure Synapse Analytics, Analytics Platform System (PDW).
  ET = External Table

Also think about schema bound objects (an exercise in sorting?? because they need to be dropped in the correct order so that you don't drop parent objects before the child objects)
*/
