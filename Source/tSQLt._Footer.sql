---Build+
GO
SET NOCOUNT ON;
DECLARE @ver NVARCHAR(MAX); 
DECLARE @match INT; 
SELECT @ver = '| tSQLt Version: ' + I.Version,
       @match = CASE WHEN I.Version = I.ClrVersion THEN 1 ELSE 0 END
  FROM tSQLt.Info() AS I;
SET @ver = @ver+SPACE(42-LEN(@ver))+'|';
 
RAISERROR('',0,1)WITH NOWAIT;
RAISERROR('+-----------------------------------------+',0,1)WITH NOWAIT;
RAISERROR('|                                         |',0,1)WITH NOWAIT;
RAISERROR('| Thank you for using tSQLt.              |',0,1)WITH NOWAIT;
RAISERROR('|                                         |',0,1)WITH NOWAIT;
RAISERROR(@ver,0,1)WITH NOWAIT;
IF(@match = 0)
BEGIN
  RAISERROR('|                                         |',0,1)WITH NOWAIT;
  RAISERROR('| ERROR: mismatching CLR Version.         |',0,1)WITH NOWAIT;
  RAISERROR('| Please download a new version of tSQLt. |',0,1)WITH NOWAIT;
END
RAISERROR('|                                         |',0,1)WITH NOWAIT;
RAISERROR('+-----------------------------------------+',0,1)WITH NOWAIT;
