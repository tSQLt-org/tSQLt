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
EXEC tSQLt.NewTestClass 'Private_RenameObjectToUniqueNameTests';
GO
CREATE PROCEDURE Private_RenameObjectToUniqueNameTests.[test RenameObjectToUniqueName calls Private_MarkObjectBeforeRename to mark old object]
AS
BEGIN
   CREATE TABLE Private_RenameObjectToUniqueNameTests.aTestObject(i INT);
   
   EXEC tSQLt.SpyProcedure 'tSQLt.Private_MarkObjectBeforeRename';
   
   DECLARE @NewName NVARCHAR(MAX);
   EXEC tSQLt.Private_RenameObjectToUniqueName @SchemaName = 'Private_RenameObjectToUniqueNameTests', @ObjectName = 'aTestObject', @NewName = @NewName OUTPUT;
   
   SELECT SchemaName, OriginalName
     INTO #Actual
     FROM tSQLt.Private_MarkObjectBeforeRename_SpyProcedureLog;
     
   SELECT 'Private_RenameObjectToUniqueNameTests' AS SchemaName, 'aTestObject' AS OriginalName
     INTO #Expected;
     
   EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE Private_RenameObjectToUniqueNameTests.AssertThatMarkRenamedObjectCreatesCorrectExtendedProperty
 @OriginalName NVARCHAR(MAX)
AS
BEGIN
   EXEC tSQLt.FakeTable 'tSQLt.Private_RenamedObjectLog';
   
   EXEC tSQLt.Private_MarkObjectBeforeRename @SchemaName = 'Private_RenameObjectToUniqueNameTests', @OriginalName = @OriginalName;
   
   SELECT ObjectId, OriginalName
     INTO #Actual
     FROM tSQLt.Private_RenamedObjectLog;
     
   SELECT TOP(0) * 
    INTO #Expected
    FROM #Actual;
   
   DECLARE @ObjectId INT;
   SELECT @ObjectId = OBJECT_ID('Private_RenameObjectToUniqueNameTests.' + @OriginalName);
   
   INSERT INTO #Expected (ObjectId, OriginalName) VALUES (@ObjectId, @OriginalName);
     
   EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROCEDURE Private_RenameObjectToUniqueNameTests.[test Private_MarkRenamedObject marks renamed table with an extended property tSQLt.RenamedObject_OriginalName]
AS
BEGIN
   CREATE TABLE Private_RenameObjectToUniqueNameTests.TheOriginalName(i INT);
   EXEC Private_RenameObjectToUniqueNameTests.AssertThatMarkRenamedObjectCreatesCorrectExtendedProperty 'TheOriginalName';
END;
GO

CREATE PROCEDURE Private_RenameObjectToUniqueNameTests.[test Private_MarkRenamedObject marks renamed procedure]
AS
BEGIN
   EXEC('CREATE PROCEDURE Private_RenameObjectToUniqueNameTests.TheOriginalName AS RETURN 0;');

   EXEC Private_RenameObjectToUniqueNameTests.AssertThatMarkRenamedObjectCreatesCorrectExtendedProperty 'TheOriginalName';
END;
GO

CREATE PROCEDURE Private_RenameObjectToUniqueNameTests.[test Private_MarkRenamedObject records rename order]
AS
BEGIN
   CREATE TABLE Private_RenameObjectToUniqueNameTests.TheOriginalTable(i INT);
   EXEC('CREATE PROCEDURE Private_RenameObjectToUniqueNameTests.TheOriginalProc AS RETURN 0;');

   EXEC tSQLt.FakeTable 'tSQLt.Private_RenamedObjectLog', @Identity = 1;
   
   EXEC tSQLt.Private_MarkObjectBeforeRename @SchemaName = 'Private_RenameObjectToUniqueNameTests', @OriginalName = 'TheOriginalTable';
   EXEC tSQLt.Private_MarkObjectBeforeRename @SchemaName = 'Private_RenameObjectToUniqueNameTests', @OriginalName = 'TheOriginalProc';
   
   SELECT Id, OriginalName
     INTO #Actual
     FROM tSQLt.Private_RenamedObjectLog;
     
   SELECT TOP(0) Id + NULL AS Id, OriginalName
    INTO #Expected
    FROM #Actual;
      
   INSERT INTO #Expected (Id, OriginalName) VALUES (1, 'TheOriginalTable');
   INSERT INTO #Expected (Id, OriginalName) VALUES (2, 'TheOriginalProc');
     
   EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
