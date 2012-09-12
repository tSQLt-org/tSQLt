GO
CREATE PROCEDURE tSQLt_testutil.Private_Drop_tSQLtTestUtilCLR_objects
AS
BEGIN
  IF TYPE_ID('tSQLt_testutil.DataTypeNoEqual') IS NOT NULL DROP TYPE tSQLt_testutil.DataTypeNoEqual;
  IF TYPE_ID('tSQLt_testutil.DataTypeWithEqual') IS NOT NULL DROP TYPE tSQLt_testutil.DataTypeWithEqual;
  IF TYPE_ID('tSQLt_testutil.DataTypeByteOrdered') IS NOT NULL DROP TYPE tSQLt_testutil.DataTypeByteOrdered;
  IF EXISTS (SELECT 1 FROM sys.assemblies WHERE name = 'tSQLtTestUtilCLR')DROP ASSEMBLY tSQLtTestUtilCLR;
END
GO
CREATE TYPE tSQLt_testutil.DataTypeNoEqual EXTERNAL NAME tSQLtTestUtilCLR.[tSQLtTestUtilCLR.DataTypeNoEqual];
CREATE TYPE tSQLt_testutil.DataTypeWithEqual EXTERNAL NAME tSQLtTestUtilCLR.[tSQLtTestUtilCLR.DataTypeWithEqual];
CREATE TYPE tSQLt_testutil.DataTypeByteOrdered EXTERNAL NAME tSQLtTestUtilCLR.[tSQLtTestUtilCLR.DataTypeByteOrdered];
GO
