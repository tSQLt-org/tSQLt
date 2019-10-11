SELECT 
    O.type_desc,
    QUOTENAME(S.name)+'.'+QUOTENAME(O.name) AS name,
    PP.parameters,
    CC.columns
  FROM sys.objects AS O
  JOIN sys.schemas AS S
    ON S.schema_id = O.schema_id
 CROSS APPLY
 (
   SELECT SUBSTRING
   (
     (
       SELECT ','+CHAR(13)+CHAR(10)+CASE WHEN P.parameter_id = 0 THEN '{RETURN}' ELSE P.name END+' '+ISNULL(PGFTN.TypeName,'') 
         FROM sys.parameters AS P
        OUTER APPLY tSQLt.Private_GetFullTypeName(P.user_type_id,P.max_length,P.precision,P.scale,NULL) AS PGFTN
        WHERE P.object_id = O.object_id
        ORDER BY P.parameter_id
          FOR XML PATH(''),TYPE
     ).value('.','VARCHAR(MAX)'),
     4,
     -1-POWER(-2,31)
   ) parameters
 )PP
 CROSS APPLY
 (
   SELECT SUBSTRING
   (
     (
       SELECT ','+CHAR(13)+CHAR(10)+C.name+' '+ISNULL(PGFTN.TypeName,'') 
         FROM sys.columns AS C
        OUTER APPLY tSQLt.Private_GetFullTypeName(C.user_type_id,C.max_length,C.precision,C.scale,C.collation_name) AS PGFTN
        WHERE C.object_id = O.object_id
        ORDER BY C.column_id
          FOR XML PATH(''),TYPE
     ).value('.','VARCHAR(MAX)'),
     4,
     -1-POWER(-2,31)
   ) columns
 )CC
 WHERE O.is_ms_shipped = 0
   AND S.name = 'tSQLt'
   AND O.type IN('TT','FN','IF','U','FS','V','P','TF','PC','FT')
 ORDER BY CASE WHEN O.name LIKE 'Private[_]%' THEN 1 ELSE 0 END,O.type_desc,name


SELECT SCHEMA_NAME(T.schema_id),* FROM sys.types AS T
--SELECT * FROM sys.columns AS C

--SELECT type,O.type_desc,COUNT(1) FROM sys.objects AS O GROUP BY O.type ,O.type_desc

--SELECT -1-POWER(-2,31)

--SELECT CAST(',  ' AS VARBINARY(MAX))
