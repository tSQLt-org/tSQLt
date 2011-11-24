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
SET NOCOUNT ON;

CREATE TABLE #datatypes (example VARCHAR(MAX), datatype VARCHAR(MAX));
GO

INSERT INTO #datatypes (example, datatype) VALUES ('9874290873048203843', 'BIGINT')
INSERT INTO #datatypes (example, datatype) VALUES ('0x432643', 'BINARY(15)')
INSERT INTO #datatypes (example, datatype) VALUES ('1', 'BIT')
INSERT INTO #datatypes (example, datatype) VALUES ('ABCDEF', 'CHAR(15)')
INSERT INTO #datatypes (example, datatype) VALUES ('12/27/2010 11:54:12.003', 'DATETIME')
INSERT INTO #datatypes (example, datatype) VALUES ('234.567', 'DECIMAL(7,4)')
INSERT INTO #datatypes (example, datatype) VALUES ('12345.6789', 'FLOAT')
INSERT INTO #datatypes (example, datatype) VALUES ('XYZ', 'IMAGE')
INSERT INTO #datatypes (example, datatype) VALUES ('13', 'INT')
INSERT INTO #datatypes (example, datatype) VALUES ('12.95', 'MONEY')
INSERT INTO #datatypes (example, datatype) VALUES ('ABCDEF', 'NCHAR(15)')
INSERT INTO #datatypes (example, datatype) VALUES ('ABCDEF', 'NTEXT')
INSERT INTO #datatypes (example, datatype) VALUES ('345.67', 'NUMERIC(7,4)')
INSERT INTO #datatypes (example, datatype) VALUES ('ABCDEF', 'NVARCHAR(15)')
INSERT INTO #datatypes (example, datatype) VALUES ('ABCDEF', 'NVARCHAR(MAX)')
INSERT INTO #datatypes (example, datatype) VALUES ('12345.6789', 'REAL')
INSERT INTO #datatypes (example, datatype) VALUES ('12/27/2010 09:35', 'SMALLDATETIME')
INSERT INTO #datatypes (example, datatype) VALUES ('13', 'SMALLINT')
INSERT INTO #datatypes (example, datatype) VALUES ('13.95', 'SMALLMONEY')
INSERT INTO #datatypes (example, datatype) VALUES ('ABCDEF', 'SQL_VARIANT')
INSERT INTO #datatypes (example, datatype) VALUES ('ABCDEF', 'SYSNAME')
INSERT INTO #datatypes (example, datatype) VALUES ('ABCDEF', 'TEXT')
INSERT INTO #datatypes (example, datatype) VALUES ('0x1234', 'TIMESTAMP')
INSERT INTO #datatypes (example, datatype) VALUES ('7', 'TINYINT')
INSERT INTO #datatypes (example, datatype) VALUES ('F12AF25F-E043-4475-ADD1-96B8BBC6F16E', 'UNIQUEIDENTIFIER')
INSERT INTO #datatypes (example, datatype) VALUES ('ABCDEF', 'VARBINARY(15)')
INSERT INTO #datatypes (example, datatype) VALUES ('ABCDEF', 'VARBINARY(MAX)')
INSERT INTO #datatypes (example, datatype) VALUES ('ABCDEF', 'VARCHAR(15)')
INSERT INTO #datatypes (example, datatype) VALUES ('ABCDEF', 'VARCHAR(MAX)')
INSERT INTO #datatypes (example, datatype) VALUES ('<xml>hi</xml>', 'XML')


DECLARE @example VARCHAR(MAX), @datatype VARCHAR(MAX);
DECLARE recs CURSOR LOCAL FAST_FORWARD FOR 
SELECT example, datatype
FROM #datatypes
ORDER BY datatype;

OPEN recs
FETCH NEXT FROM recs INTO @example, @datatype;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'CREATE PROCEDURE tSQLtclr_test.[test ResultSetFilter returns ' + @datatype + ' values from one result set]';
    PRINT 'AS';
    PRINT 'BEGIN';
    PRINT '    BEGIN TRY';
    PRINT '        EXEC tSQLt.ResultSetFilter 1, ''SELECT CAST(''''' + @example + ''''' AS ' + @datatype + ') AS val;''';
    PRINT '    END TRY';
    PRINT '    BEGIN CATCH';
    PRINT '        DECLARE @msg NVARCHAR(MAX); SELECT @msg = ERROR_MESSAGE();';
    PRINT '        EXEC tSQLt.Fail ''' + @datatype + ' values caused exception in ResultsetFilter'', @msg;';
    PRINT '    END CATCH';
    PRINT 'END;';
    PRINT 'GO';
    PRINT '';
    
    FETCH NEXT FROM recs INTO @example, @datatype;
END;

CLOSE recs
DEALLOCATE recs
GO

DROP TABLE #datatypes;