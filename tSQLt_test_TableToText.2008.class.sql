CREATE PROC tSQLtPrivate_test.[test TableToText works for one DATETIMEOFFSET column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T DATETIMEOFFSET
    );
    INSERT INTO #DoesExist (T)VALUES(CAST('2001-10-13 12:34:56.7891234 +13:24' AS DATETIMEOFFSET));

    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLtPrivate::TableToString('#DoesExist', '');
   
    EXEC tSQLt.AssertEqualsString '|T                                 |
+----------------------------------+
|2001-10-13 12:34:56.7891234 +13:24|', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one DATETIME2 column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T DATETIME2
    );
    INSERT INTO #DoesExist (T)VALUES(CAST('2001-10-13T12:34:56.7891234' AS DATETIME2));

    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLtPrivate::TableToString('#DoesExist', '');
   
    EXEC tSQLt.AssertEqualsString '|T                          |
+---------------------------+
|2001-10-13 12:34:56.7891234|', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one TIME column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T TIME
    );
    INSERT INTO #DoesExist (T)VALUES('2001-10-13T12:34:56.7871234');
    
    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLtPrivate::TableToString('#DoesExist', '');
   
    EXEC tSQLt.AssertEqualsString '|T               |
+----------------+
|12:34:56.7871234|', @result;
END;
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one DATE column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T DATE
    );
    INSERT INTO #DoesExist (T)VALUES('2001-10-13T12:34:56.787');
    
    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLtPrivate::TableToString('#DoesExist', '');
   
    EXEC tSQLt.AssertEqualsString '|T         |
+----------+
|2001-10-13|', @result;
END;
GO
