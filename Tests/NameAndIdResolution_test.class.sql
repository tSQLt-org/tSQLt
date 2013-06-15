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
EXEC tSQLt.NewTestClass 'NameAndIdResolutionTests'
GO
CREATE PROC NameAndIdResolutionTests.[test schema_id of schema name with spaces returns null if quoted with square brackets]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests my schema];');
	DECLARE @actual INT;
	SELECT @actual = SCHEMA_ID('[NameAndIdResolutionTests my schema]');
	EXEC tSQLt.AssertEquals NULL, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test schema_id of schema name with spaces returns null if quoted with double quotes]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests my schema];');
	DECLARE @actual INT;
	SELECT @actual = SCHEMA_ID('"NameAndIdResolutionTests my schema"');
	EXEC tSQLt.AssertEquals NULL, @actual;
END;
GO


CREATE PROC NameAndIdResolutionTests.[test object_id of object name with spaces returns not null if quoted with square brackets]
AS
BEGIN
	EXEC ('CREATE TABLE [NameAndIdResolutionTests].[my table] (i int);');
	DECLARE @actual INT;
	SELECT @actual = OBJECT_ID('[NameAndIdResolutionTests].[my table]');
	
	IF @actual IS NULL
		EXEC tSQLt.Fail 'Expected OBJECT_ID of quoted name to not return null';
END;
GO

CREATE PROC NameAndIdResolutionTests.[test object_id of object name with spaces returns not null if quoted with double quotes]
AS
BEGIN
	EXEC ('CREATE TABLE [NameAndIdResolutionTests].[my table] (i int);');
	DECLARE @actual INT;
	SELECT @actual = OBJECT_ID('"NameAndIdResolutionTests"."my table"');
	
	IF @actual IS NULL
		EXEC tSQLt.Fail 'Expected OBJECT_ID of quoted name to not return null';
END;
GO

CREATE PROC NameAndIdResolutionTests.[test object_id of object and schema name with spaces returns not null if quoted with brackets]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests my schema];');
	EXEC ('CREATE TABLE [NameAndIdResolutionTests my schema].[my table] (i int);');
	DECLARE @actual INT;
	SELECT @actual = OBJECT_ID('[NameAndIdResolutionTests my schema].[my table]');
	
	IF @actual IS NULL
		EXEC tSQLt.Fail 'Expected OBJECT_ID of quoted name to not return null';
END;
GO

CREATE PROC NameAndIdResolutionTests.[test object_id of object and schema name with spaces returns not null if not quoted]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests my schema];');
	EXEC ('CREATE TABLE [NameAndIdResolutionTests my schema].[my table] (i int);');
	DECLARE @actual INT;
	SELECT @actual = OBJECT_ID('NameAndIdResolutionTests my schema.my table');
	
	IF @actual IS NULL
		EXEC tSQLt.Fail 'Expected OBJECT_ID of quoted name to not return null';
END;
GO

CREATE PROC NameAndIdResolutionTests.[test object_id of object and schema name with spaces returns not null if quoted with double quotes]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests my schema];');
	EXEC ('CREATE TABLE [NameAndIdResolutionTests my schema].[my table] (i int);');
	DECLARE @actual INT;
	SELECT @actual = OBJECT_ID('"NameAndIdResolutionTests my schema"."my table"');
	
	IF @actual IS NULL
		EXEC tSQLt.Fail 'Expected OBJECT_ID of quoted name to not return null';
END;
GO
CREATE PROC NameAndIdResolutionTests.[test schema_id of schema name with spaces returns not null if not quoted]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests my schema];');
	DECLARE @actual INT;
	SELECT @actual = SCHEMA_ID('NameAndIdResolutionTests my schema');

	IF @actual IS NULL
		EXEC tSQLt.Fail 'Expected SCHEMA_ID of not quoted name to not return null';
END;
GO

-----------------------------

GO
CREATE PROC NameAndIdResolutionTests.[test schema_id of schema name with spaces and dots returns null if quoted with square brackets]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests m.y sche.ma];');
	DECLARE @actual INT;
	SELECT @actual = SCHEMA_ID('[NameAndIdResolutionTests m.y sche.ma]');
	EXEC tSQLt.AssertEquals NULL, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test schema_id of schema name with spaces and dots returns null if quoted with double quotes]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests m.y sche.ma];');
	DECLARE @actual INT;
	SELECT @actual = SCHEMA_ID('"NameAndIdResolutionTests m.y sche.ma"');
	EXEC tSQLt.AssertEquals NULL, @actual;
END;
GO


CREATE PROC NameAndIdResolutionTests.[test object_id of object name with spaces and dots returns not null if quoted with square brackets]
AS
BEGIN
	EXEC ('CREATE TABLE [NameAndIdResolutionTests].[m.y tab.le] (i int);');
	DECLARE @actual INT;
	SELECT @actual = OBJECT_ID('[NameAndIdResolutionTests].[m.y tab.le]');
	
	IF @actual IS NULL
		EXEC tSQLt.Fail 'Expected OBJECT_ID of quoted name to not return null';
END;
GO

CREATE PROC NameAndIdResolutionTests.[test object_id of object name with spaces and dots returns not null if quoted with double quotes]
AS
BEGIN
	EXEC ('CREATE TABLE [NameAndIdResolutionTests].[m.y tab.le] (i int);');
	DECLARE @actual INT;
	SELECT @actual = OBJECT_ID('"NameAndIdResolutionTests"."m.y tab.le"');
	
	IF @actual IS NULL
		EXEC tSQLt.Fail 'Expected OBJECT_ID of quoted name to not return null';
END;
GO
CREATE PROC NameAndIdResolutionTests.[test schema_id of schema name with spaces and dots returns not null if not quoted]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests m.y sche.ma];');
	DECLARE @actual INT;
	SELECT @actual = SCHEMA_ID('NameAndIdResolutionTests m.y sche.ma');

	IF @actual IS NULL
		EXEC tSQLt.Fail 'Expected SCHEMA_ID of not quoted name to not return null';
END;
GO

CREATE PROC NameAndIdResolutionTests.[test object_id of object and schema name with spaces and dots returns not null if quoted with brackets]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests m.y sche.ma];');
	EXEC ('CREATE TABLE [NameAndIdResolutionTests m.y sche.ma].[m.y tab.le] (i int);');
	DECLARE @actual INT;
	SELECT @actual = OBJECT_ID('[NameAndIdResolutionTests m.y sche.ma].[m.y tab.le]');
	
	IF @actual IS NULL
		EXEC tSQLt.Fail 'Expected OBJECT_ID of quoted name to not return null';
END;
GO

CREATE PROC NameAndIdResolutionTests.[test object_id of object and schema name with spaces and dots returns not null if not quoted]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests m.y sche.ma];');
	EXEC ('CREATE TABLE [NameAndIdResolutionTests m.y sche.ma].[m.y tab.le] (i int);');
	DECLARE @actual INT;
	SELECT @actual = OBJECT_ID('NameAndIdResolutionTests m.y sche.ma.m.y tab.le');
	
	EXEC tSQLt.AssertEquals NULL, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test object_id of object and schema name with spaces and dots returns not null if quoted with double quotes]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests m.y sche.ma];');
	EXEC ('CREATE TABLE [NameAndIdResolutionTests m.y sche.ma].[m.y tab.le] (i int);');
	DECLARE @actual INT;
	SELECT @actual = OBJECT_ID('"NameAndIdResolutionTests m.y sche.ma"."m.y tab.le"');
	
	IF @actual IS NULL
		EXEC tSQLt.Fail 'Expected OBJECT_ID of quoted name to not return null';
END;
GO
-----------------------------------------------------
GO

CREATE PROC NameAndIdResolutionTests.[test tSQLt.Private_GetSchemaId of schema name that does not exist returns null]
AS
BEGIN
	DECLARE @actual INT;
	SELECT @actual = tSQLt.Private_GetSchemaId('NameAndIdResolutionTests my schema');

	EXEC tSQLt.AssertEquals NULL, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test tSQLt.Private_GetSchemaId of simple schema name returns id of schema]
AS
BEGIN
	DECLARE @actual INT;
	DECLARE @expected INT;
	SELECT @expected = SCHEMA_ID('NameAndIdResolutionTests');
	SELECT @actual = tSQLt.Private_GetSchemaId('NameAndIdResolutionTests');

	EXEC tSQLt.AssertEquals @expected, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test tSQLt.Private_GetSchemaId of simple bracket quoted schema name returns id of schema]
AS
BEGIN
	DECLARE @actual INT;
	DECLARE @expected INT;
	SELECT @expected = SCHEMA_ID('NameAndIdResolutionTests');
	SELECT @actual = tSQLt.Private_GetSchemaId('[NameAndIdResolutionTests]');

	EXEC tSQLt.AssertEquals @expected, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test tSQLt.Private_GetSchemaId returns id of schema with brackets in name if bracketed and unbracketed schema exists]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[NameAndIdResolutionTests]]];');

	DECLARE @actual INT;
	DECLARE @expected INT;
	SELECT @expected = (SELECT schema_id FROM sys.schemas WHERE name='[NameAndIdResolutionTests]');
	SELECT @actual = tSQLt.Private_GetSchemaId('[NameAndIdResolutionTests]');

	EXEC tSQLt.AssertEquals @expected, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test tSQLt.Private_GetSchemaId returns id of schema without brackets in name if bracketed and unbracketed schema exists]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[NameAndIdResolutionTests]]];');

	DECLARE @actual INT;
	DECLARE @expected INT;
	SELECT @expected = (SELECT schema_id FROM sys.schemas WHERE name='NameAndIdResolutionTests');
	SELECT @actual = tSQLt.Private_GetSchemaId('NameAndIdResolutionTests');

	EXEC tSQLt.AssertEquals @expected, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test tSQLt.Private_GetSchemaId returns id of schema without brackets in name if only unbracketed schema exists]
AS
BEGIN
	DECLARE @actual INT;
	DECLARE @expected INT;
	SELECT @expected = (SELECT schema_id FROM sys.schemas WHERE name='NameAndIdResolutionTests');
	SELECT @actual = tSQLt.Private_GetSchemaId('[NameAndIdResolutionTests]');

	EXEC tSQLt.AssertEquals @expected, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test tSQLt.Private_GetSchemaId returns id of schema when quoted with double quotes]
AS
BEGIN
	DECLARE @actual INT;
	DECLARE @expected INT;
	SELECT @expected = (SELECT schema_id FROM sys.schemas WHERE name='NameAndIdResolutionTests');
	SELECT @actual = tSQLt.Private_GetSchemaId('"NameAndIdResolutionTests"');

	EXEC tSQLt.AssertEquals @expected, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test tSQLt.Private_GetSchemaId returns id of double quoted schema when similar schema names exist]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[NameAndIdResolutionTests]]];');
	EXEC ('CREATE SCHEMA ["NameAndIdResolutionTests"];');

	DECLARE @actual INT;
	DECLARE @expected INT;
	SELECT @expected = (SELECT schema_id FROM sys.schemas WHERE name='"NameAndIdResolutionTests"');
	SELECT @actual = tSQLt.Private_GetSchemaId('"NameAndIdResolutionTests"');

	EXEC tSQLt.AssertEquals @expected, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test tSQLt.Private_GetSchemaId returns id of bracket quoted schema when similar schema names exist]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[NameAndIdResolutionTests]]];');
	EXEC ('CREATE SCHEMA ["NameAndIdResolutionTests"];');

	DECLARE @actual INT;
	DECLARE @expected INT;
	SELECT @expected = (SELECT schema_id FROM sys.schemas WHERE name='[NameAndIdResolutionTests]');
	SELECT @actual = tSQLt.Private_GetSchemaId('[NameAndIdResolutionTests]');

	EXEC tSQLt.AssertEquals @expected, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test tSQLt.Private_GetSchemaId returns id of unquoted schema when similar schema names exist]
AS
BEGIN
	EXEC ('CREATE SCHEMA [[NameAndIdResolutionTests]]];');
	EXEC ('CREATE SCHEMA ["NameAndIdResolutionTests"];');

	DECLARE @actual INT;
	DECLARE @expected INT;
	SELECT @expected = (SELECT schema_id FROM sys.schemas WHERE name='NameAndIdResolutionTests');
	SELECT @actual = tSQLt.Private_GetSchemaId('NameAndIdResolutionTests');

	EXEC tSQLt.AssertEquals @expected, @actual;
END;
GO

CREATE PROC NameAndIdResolutionTests.[test tSQLt.Private_GetSchemaId of schema name with spaces returns not null if not quoted]
AS
BEGIN
	EXEC ('CREATE SCHEMA [NameAndIdResolutionTests my.schema];');
	DECLARE @actual INT;
	DECLARE @expected INT;
	SELECT @expected = (SELECT schema_id FROM sys.schemas WHERE name='NameAndIdResolutionTests my.schema');
	SELECT @actual = tSQLt.Private_GetSchemaId('NameAndIdResolutionTests my.schema');

	EXEC tSQLt.AssertEquals @expected, @actual;
END;
GO

