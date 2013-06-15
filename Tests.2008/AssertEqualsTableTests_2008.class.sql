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
EXEC tSQLt.NewTestClass 'AssertEqualsTableTests_2008';
GO
CREATE PROCEDURE AssertEqualsTableTests_2008.[test can handle 2008 date data types]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'DATE', '''2012-01-01'',''2012-06-19'',''2012-10-25''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'TIME', '''10:10:10'',''11:11:11'',''12:12:12''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'DATETIMEOFFSET', '''2012-01-01 10:10:10.101010 +10:10'',''2012-06-19 11:11:11.111111 +11:11'',''2012-10-25 12:12:12.121212 -12:12''';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'DATETIME2', '''2012-01-01 10:10:10.101010'',''2012-06-19 11:11:11.111111'',''2012-10-25 12:12:12.121212''';
END;
GO
CREATE PROCEDURE AssertEqualsTableTests_2008.[test can handle hierarchyid data type]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can handle a datatype] 'HIERARCHYID', '''/10/'',''/11/'',''/12/''';
END;
GO

CREATE PROCEDURE AssertEqualsTableTests_2008.[test all unsupported 2008 data types]
AS
BEGIN
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can NOT handle a datatype] 'GEOMETRY', 'geometry::STPointFromText(''POINT (10 10)'', 0),geometry::STPointFromText(''POINT (11 11)'', 0),geometry::STPointFromText(''POINT (12 12)'', 0)';
  EXEC AssertEqualsTableTests.[Assert that AssertEqualsTable can NOT handle a datatype] 'GEOGRAPHY', 'geography::STGeomFromText(''LINESTRING(-10.10 10.10, -50.10 50.10)'', 4326),geography::STGeomFromText(''LINESTRING(-11.11 11.11, -50.11 50.11)'', 4326),geography::STGeomFromText(''LINESTRING(-12.12 12.12, -50.12 50.12)'', 4326)';
END;
GO

