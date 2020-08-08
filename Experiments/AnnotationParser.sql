IF OBJECT_ID('dbo.rotiueortiuo') IS NOT NULL DROP PROCEDURE dbo.rotiueortiuo;
GO

GO
/* create proc dbo.rotiueortiuo on 20200722
/* Annotations/**/
RETURN
--*//*
RETURN
   --[@tSQLt:sdfsdfsd]()
RETURN
*/
CREATE/*23423
/*sdfkljh*//**/
-sdfkljh*/PROCEDURE 

dbo.rotiueortiuo
AS
RETURN 1;
GO
DECLARE @D NVARCHAR(MAX) = (SELECT definition FROM sys.sql_modules AS SM WHERE SM.object_id = OBJECT_ID('dbo.rotiueortiuo'));


SELECT
    *
  FROM(
    SELECT
        LTRIM(RTRIM(CASE WHEN LEFT(Z.S,1) = NCHAR(10) THEN SUBSTRING(Z.S,2,LEN(Z.S)-1) ELSE Z.S END)) SS
      FROM(
        SELECT 
           SUBSTRING(Y.X,Y.no,LEAD(Y.no)OVER(ORDER BY Y.no)-Y.no-1) S
          FROM(
            SELECT 
              *
            FROM (VALUES(LEFT(@D,CHARINDEX('CREATE',@D))))X(X)
            CROSS APPLY tSQLt.F_Num(LEN(X.X)+2) AS FN WHERE SUBSTRING(NCHAR(13)+X.X+NCHAR(13),FN.no,1)=NCHAR(13)
          )Y
      )Z
  )ZZ
 WHERE ZZ.SS LIKE '%--[[]@tSQLt:%](%)%'
--  SELECT FN.no,CHAR(no),CAST(CHAR(no) AS BINARY(1)) FROM tSQLt.F_Num(255) AS FN

            SELECT 
              *,
              SUBSTRING('/**/'+X.X+'/**/',FN.no,LEAD(FN.no)OVER(ORDER BY FN.no)-FN.no)
            FROM (VALUES(@D))X(X)
            CROSS APPLY tSQLt.F_Num(LEN(X.X)+2) AS FN WHERE SUBSTRING('/**/'+X.X+'/**/',FN.no,2)IN('/*','*/','--',CHAR(13)+CHAR(10))
