IF EXISTS ( SELECT  1
            FROM    sys.databases
            WHERE   name = 'tSQLt_RemoteSynonymsTestDatabase' )
    BEGIN

        EXEC dbo.sp_changedbowner @loginame = N'tSQLt.Build';
    END;