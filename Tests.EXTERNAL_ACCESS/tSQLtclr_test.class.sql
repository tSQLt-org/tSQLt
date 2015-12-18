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
EXEC tSQLt.NewTestClass 'tSQLtclr_tests_EA';
GO



CREATE PROC tSQLtclr_tests_EA.[test NewConnection executes a command in a new process]
AS
BEGIN
    EXEC tSQLt.NewConnection 'IF OBJECT_ID(''tSQLtclr_tests_EA.[SpidTable for test NewConnection executes a command in a new process]'') IS NOT NULL DROP TABLE tSQLtclr_tests_EA.[SpidTable for test NewConnection executes a command in a new process];';

    EXEC tSQLt.NewConnection 'SELECT @@SPID spid INTO tSQLtclr_tests_EA.[SpidTable for test NewConnection executes a command in a new process];';
    
    EXEC tSQLt.AssertObjectExists 'tSQLtclr_tests_EA.[SpidTable for test NewConnection executes a command in a new process]';
    
    DECLARE @otherSpid INT;
    SELECT @otherSpid = spid
      FROM tSQLtclr_tests_EA.[SpidTable for test NewConnection executes a command in a new process];

    IF ISNULL(@otherSpid, -1) = @@SPID
    BEGIN
        EXEC tSQLt.Fail 'Expected otherSpid to be different than @@SPID.';
    END;
    
    EXEC tSQLt.NewConnection 'IF OBJECT_ID(''tSQLtclr_tests_EA.[SpidTable for test NewConnection executes a command in a new process]'') IS NOT NULL DROP TABLE tSQLtclr_tests_EA.[SpidTable for test NewConnection executes a command in a new process];';
END;
GO
