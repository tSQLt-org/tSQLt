/*
   Copyright 2011 tSQLt

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
GO

CREATE PROC tSQLtPrivate_test.[test TableToText works for one DATETIMEOFFSET column #table]
AS
BEGIN
    CREATE TABLE #DoesExist(
      T DATETIMEOFFSET
    );
    INSERT INTO #DoesExist (T)VALUES(CAST('2001-10-13 12:34:56.7891234 +13:24' AS DATETIMEOFFSET));

    DECLARE @result NVARCHAR(MAX);
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
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
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
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
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
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
    SET @result = tSQLt.Private::TableToString('#DoesExist', '', NULL);
   
    EXEC tSQLt.AssertEqualsString '|T         |
+----------+
|2001-10-13|', @result;
END;
GO
