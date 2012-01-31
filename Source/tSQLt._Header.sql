---Build+
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
DECLARE @Msg NVARCHAR(MAX);SELECT @Msg = 'Compiled at '+CONVERT(NVARCHAR,GETDATE(),121);RAISERROR(@Msg,0,1);
GO

IF TYPE_ID('tSQLt.Private') IS NOT NULL DROP TYPE tSQLt.Private;
IF TYPE_ID('tSQLtPrivate') IS NOT NULL DROP TYPE tSQLtPrivate;
GO
IF OBJECT_ID('tSQLt.DropClass') IS NOT NULL
    EXEC tSQLt.DropClass tSQLt;
GO

IF EXISTS (SELECT 1 FROM sys.assemblies WHERE name = 'tSQLtCLR')
    DROP ASSEMBLY tSQLtCLR;
GO

CREATE SCHEMA tSQLt;
GO
SET QUOTED_IDENTIFIER ON;
GO
---Build-