/*
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
*/
EXEC tSQLt.NewTestClass 'tSQLt_test_ResultSetFilter_2008';
GO

CREATE PROCEDURE tSQLt_test_ResultSetFilter_2008.AssertResultSetFilterCanHandleDatatype
  @Value NVARCHAR(MAX),
  @Datatype NVARCHAR(MAX)
AS
BEGIN
    DECLARE @ExpectedStmt NVARCHAR(MAX),
            @ActualStmt NVARCHAR(MAX);

    DECLARE @ActualValue NVARCHAR(MAX);
    SET @ActualValue = REPLACE(@Value, '''', '''''');
    
    SELECT @ExpectedStmt = 'SELECT CAST(' + @Value + ' AS ' + @Datatype + ') AS val;';
    SELECT @ActualStmt = 'EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(' + @ActualValue + ' AS ' + @Datatype + ') AS val;''';

    EXEC tSQLt.AssertResultSetsHaveSameMetaData @ExpectedStmt, @ActualStmt;

END
GO

CREATE PROC tSQLt_test_ResultSetFilter_2008.[test ResultSetFilter can handle each 2008 datatype]
AS
BEGIN
    EXEC tSQLt_test_ResultSetFilter_2008.AssertResultSetFilterCanHandleDatatype '''2011-09-27 12:23:47.846753797''', 'DATETIME2';
    EXEC tSQLt_test_ResultSetFilter_2008.AssertResultSetFilterCanHandleDatatype '''2011-09-27 12:23:47.846753797''', 'DATETIME2(3)';
    EXEC tSQLt_test_ResultSetFilter_2008.AssertResultSetFilterCanHandleDatatype '''2011-09-27 12:23:47.846753797 +01:15''', 'DATETIMEOFFSET';
    EXEC tSQLt_test_ResultSetFilter_2008.AssertResultSetFilterCanHandleDatatype '''2011-09-27 12:23:47.846753797 +01:15''', 'DATETIMEOFFSET(3)';
    EXEC tSQLt_test_ResultSetFilter_2008.AssertResultSetFilterCanHandleDatatype '''2011-09-27 12:23:47.846753797''', 'DATE';
    EXEC tSQLt_test_ResultSetFilter_2008.AssertResultSetFilterCanHandleDatatype '''2011-09-27 12:23:47.846753797''', 'TIME';

    EXEC tSQLt_test_ResultSetFilter_2008.AssertResultSetFilterCanHandleDatatype 'geometry::STGeomFromText(''LINESTRING (100 100, 20 180, 180 180)'', 0)', 'geometry';
    EXEC tSQLt_test_ResultSetFilter_2008.AssertResultSetFilterCanHandleDatatype 'geography::STGeomFromText(''LINESTRING(-122.360 47.656, -122.343 47.656)'', 4326)', 'geography';
    EXEC tSQLt_test_ResultSetFilter_2008.AssertResultSetFilterCanHandleDatatype 'hierarchyid::Parse(''/1/'')', 'hierarchyid';

END
GO

