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
DECLARE @Msg VARCHAR(MAX);SELECT @Msg = 'Compiled at '+CONVERT(VARCHAR,GETDATE(),121);RAISERROR(@Msg,0,1);
GO
EXEC tSQLt.NewTestClass 'tSQLt_test_ResultSetFilter_2008';
GO

CREATE PROC tSQLt_test_ResultSetFilter_2008.[test ResultSetFilter handles geometry]
AS
BEGIN
    CREATE TABLE #TmpA (v1 geometry);
    INSERT INTO #TmpA
    EXEC tSQLt.ResultSetFilter 1, 'SELECT geometry::STGeomFromText(''LINESTRING (100 100, 20 180, 180 180)'', 0)';
    
    SELECT v1.ToString() v1 INTO #Actual FROM #TmpA;
    
    CREATE TABLE #TmpE (v1 geometry);
    INSERT INTO #TmpE
    SELECT geometry::STGeomFromText('LINESTRING (100 100, 20 180, 180 180)', 0);
    
    SELECT v1.ToString() v1 INTO #Expected FROM #TmpE;
    
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

CREATE PROC tSQLt_test_ResultSetFilter_2008.[test ResultSetFilter handles geography]
AS
BEGIN
    CREATE TABLE #TmpA (v1 geography);
    INSERT INTO #TmpA
    EXEC tSQLt.ResultSetFilter 1, 'SELECT geography::STGeomFromText(''LINESTRING(-122.360 47.656, -122.343 47.656)'', 4326)';
    
    SELECT v1.ToString() v1 INTO #Actual FROM #TmpA;
    
    CREATE TABLE #TmpE (v1 geography);
    INSERT INTO #TmpE
    SELECT geography::STGeomFromText('LINESTRING(-122.360 47.656, -122.343 47.656)', 4326);
    
    SELECT v1.ToString() v1 INTO #Expected FROM #TmpE;
    
    EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO

