GO
CREATE PROCEDURE tSQLt_testutil.Private_Drop_tSQLtTestUtilCLR_objects
AS
BEGIN
  IF TYPE_ID('tSQLt_testutil.DataTypeNoEqual') IS NOT NULL DROP TYPE tSQLt_testutil.DataTypeNoEqual;
  IF TYPE_ID('tSQLt_testutil.DataTypeWithEqual') IS NOT NULL DROP TYPE tSQLt_testutil.DataTypeWithEqual;
  IF TYPE_ID('tSQLt_testutil.DataTypeByteOrdered') IS NOT NULL DROP TYPE tSQLt_testutil.DataTypeByteOrdered;
  IF OBJECT_ID('tSQLt_testutil.AClrSvf') IS NOT NULL DROP FUNCTION tSQLt_testutil.AClrSvf;
  IF OBJECT_ID('tSQLt_testutil.AClrTvf') IS NOT NULL DROP FUNCTION tSQLt_testutil.AClrTvf;
  IF OBJECT_ID('tSQLt_testutil.AnEmptyClrTvf') IS NOT NULL DROP FUNCTION tSQLt_testutil.AnEmptyClrTvf;
  IF EXISTS (SELECT 1 FROM sys.assemblies WHERE name = 'tSQLtTestUtilCLR')DROP ASSEMBLY tSQLtTestUtilCLR;
END
GO
CREATE TYPE tSQLt_testutil.DataTypeNoEqual EXTERNAL NAME tSQLtTestUtilCLR.[tSQLtTestUtilCLR.DataTypeNoEqual];
CREATE TYPE tSQLt_testutil.DataTypeWithEqual EXTERNAL NAME tSQLtTestUtilCLR.[tSQLtTestUtilCLR.DataTypeWithEqual];
CREATE TYPE tSQLt_testutil.DataTypeByteOrdered EXTERNAL NAME tSQLtTestUtilCLR.[tSQLtTestUtilCLR.DataTypeByteOrdered];
GO
CREATE FUNCTION tSQLt_testutil.AClrSvf(@p1 NVARCHAR(MAX), @p2 NVARCHAR(MAX))RETURNS NVARCHAR(MAX) 
       AS EXTERNAL NAME tSQLtTestUtilCLR.[tSQLtTestUtilCLR.ClrFunctions].AClrSvf;
GO
CREATE FUNCTION tSQLt_testutil.AClrTvf(@p1 NVARCHAR(MAX), @p2 NVARCHAR(MAX))RETURNS TABLE(id INT, val NVARCHAR(MAX))
       AS EXTERNAL NAME tSQLtTestUtilCLR.[tSQLtTestUtilCLR.ClrFunctions].AClrTvf;
GO
CREATE FUNCTION tSQLt_testutil.AnEmptyClrTvf(@p1 NVARCHAR(MAX), @p2 NVARCHAR(MAX))RETURNS TABLE(id INT, val NVARCHAR(MAX))
       AS EXTERNAL NAME tSQLtTestUtilCLR.[tSQLtTestUtilCLR.ClrFunctions].AnEmptyClrTvf;
GO
