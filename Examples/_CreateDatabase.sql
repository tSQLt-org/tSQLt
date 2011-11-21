USE tempdb;

IF(db_id('tSQLt_Example1') IS NOT NULL)
EXEC('
ALTER DATABASE tSQLt_Example1 SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
USE tSQLt_Example1;
ALTER DATABASE tSQLt_Example1 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
USE tempdb;
DROP DATABASE tSQLt_Example1;
');

CREATE DATABASE tSQLt_Example1;
ALTER DATABASE tSQLt_Example1 SET TRUSTWORTHY ON;
GO
USE tSQLt_Example1;
GO


------------------------------------------------------------------------------------
CREATE SCHEMA Accelerator;
GO

IF OBJECT_ID('Accelerator.Particle') IS NOT NULL DROP TABLE Practice.Particle;
GO
CREATE TABLE Accelerator.Particle(
  Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Point_Id PRIMARY KEY,
  X DECIMAL(10,2) NOT NULL,
  Y DECIMAL(10,2) NOT NULL,
  Value NVARCHAR(MAX) NOT NULL
);
GO
