USE tempdb;
EXECUTE AS LOGIN='SA';
GO
IF(db_id('Practica1_ParticlesInRectangle') IS NOT NULL)
EXEC('
ALTER DATABASE Practica1_ParticlesInRectangle SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
USE Practica1_ParticlesInRectangle;
ALTER DATABASE Practica1_ParticlesInRectangle SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
USE master;
DROP DATABASE Practica1_ParticlesInRectangle;
');

CREATE DATABASE Practica1_ParticlesInRectangle;
ALTER DATABASE Practica1_ParticlesInRectangle SET TRUSTWORTHY ON;
GO
USE Practica1_ParticlesInRectangle;
GO
------------------------------------------------------------------------------------
CREATE SCHEMA Practice;
GO

IF OBJECT_ID('Practice.Particle') IS NOT NULL DROP TABLE Practice.Particle;
GO
CREATE TABLE Practice.Particle(
  Id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Point_Id PRIMARY KEY,
  X DECIMAL(10,2) NOT NULL,
  Y DECIMAL(10,2) NOT NULL,
  Value NVARCHAR(MAX) NOT NULL
);
GO
------------------------------------------------------------------------------------
GO
USE tempdb;
REVERT;
GO

USE Practica1_ParticlesInRectangle;