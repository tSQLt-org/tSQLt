USE tempdb;

IF(db_id('tSQLt_Example') IS NOT NULL)
EXEC('
ALTER DATABASE tSQLt_Example SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
USE tSQLt_Example;
ALTER DATABASE tSQLt_Example SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
USE tempdb;
DROP DATABASE tSQLt_Example;
');

CREATE DATABASE tSQLt_Example WITH TRUSTWORTHY ON;
GO
USE tSQLt_Example;
GO


------------------------------------------------------------------------------------
CREATE SCHEMA Accelerator;
GO

IF OBJECT_ID('Accelerator.Particle') IS NOT NULL DROP TABLE Accelerator.Particle;
GO
CREATE TABLE Accelerator.Particle(
  Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Point_Id PRIMARY KEY,
  X DECIMAL(10,2) NOT NULL,
  Y DECIMAL(10,2) NOT NULL,
  Value NVARCHAR(MAX) NOT NULL,
  ColorId INT NOT NULL
);
GO

IF OBJECT_ID('Accelerator.Color') IS NOT NULL DROP TABLE Practice.Color;
GO
CREATE TABLE Accelerator.Color(
  Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Color_Id PRIMARY KEY,
  ColorName NVARCHAR(MAX) NOT NULL
);
GO