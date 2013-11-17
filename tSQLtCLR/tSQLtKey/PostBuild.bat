CD %1
..\..\Build\CreateAssemblyGenerator.exe tSQLtKey dbo %2 SAFE >tSQLtKey.sql
copy tSQLtKey.sql ..\..\Build\