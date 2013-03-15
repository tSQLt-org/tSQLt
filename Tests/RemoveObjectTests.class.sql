/*--LICENSE--

   Copyright 2012 tSQLt

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

--LICENSE--*/
IF(@@TRANCOUNT>0)ROLLBACK;
GO
EXEC tSQLt.NewTestClass 'RemoveObjectTests';
GO
CREATE PROCEDURE RemoveObjectTests.[test RemoveObject removes a table]
AS
BEGIN
   CREATE TABLE RemoveObjectTests.aTestObject(i INT);

   DECLARE @NewName NVARCHAR(MAX);
   EXEC tSQLt.RemoveObject @ObjectName = 'RemoveObjectTests.aTestObject', @NewName = @NewName OUTPUT;

   IF EXISTS(SELECT 1 FROM sys.objects WHERE name = 'aTestObject')
   BEGIN
     EXEC tSQLt.Fail 'table object should have been removed';
   END;
END;
GO

CREATE PROCEDURE RemoveObjectTests.[test RemoveObject removes a procedure]
AS
BEGIN
   EXEC('CREATE PROCEDURE RemoveObjectTests.aTestObject AS BEGIN RETURN 0; END;');

   DECLARE @NewName NVARCHAR(MAX);
   EXEC tSQLt.RemoveObject @ObjectName = 'RemoveObjectTests.aTestObject', @NewName = @NewName OUTPUT;

   IF EXISTS(SELECT 1 FROM sys.objects WHERE name = 'aTestObject')
   BEGIN
     EXEC tSQLt.Fail 'procedure object should have been removed';
   END;
END;
GO

CREATE PROCEDURE RemoveObjectTests.[test RemoveObject removes a view]
AS
BEGIN
   EXEC ('CREATE VIEW RemoveObjectTests.aTestObject AS SELECT 1 AS X');

   DECLARE @NewName NVARCHAR(MAX);
   EXEC tSQLt.RemoveObject @ObjectName = 'RemoveObjectTests.aTestObject', @NewName = @NewName OUTPUT;

   IF EXISTS(SELECT 1 FROM sys.objects WHERE name = 'aTestObject')
   BEGIN
     EXEC tSQLt.Fail 'view object should have been removed';
   END;
END;
GO

CREATE PROCEDURE RemoveObjectTests.[test RemoveObject raises approporate error if object doesn't exists']
AS
BEGIN
   DECLARE @ErrorMessage NVARCHAR(MAX);
   SET @ErrorMessage = '<NoError>';
   
   BEGIN TRY
     EXEC tSQLt.RemoveObject @ObjectName = 'RemoveObjectTests.aNonExistentTestObject';
   END TRY
   BEGIN CATCH
     SET @ErrorMessage = ERROR_MESSAGE();
   END CATCH
   
   EXEC tSQLt.AssertLike '%RemoveObjectTests.aNonExistentTestObject does not exist!%',@ErrorMessage;  
END;
GO