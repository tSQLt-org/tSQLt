---Build+
CREATE TABLE dbo.TestTable
    (
      c1 INT NULL ,
      c2 BIGINT NULL ,
      c3 VARCHAR(MAX) NULL
    );
GO
CREATE VIEW dbo.TestView
AS
    SELECT  *
    FROM    dbo.TestTable;;
GO
CREATE PROCEDURE dbo.NotATable
AS
    RETURN;
GO
CREATE SCHEMA TestSchema;
GO
CREATE TYPE TestSchema.UDT FROM NVARCHAR(20);
GO
CREATE TABLE TestSchema.tbl(i TestSchema.UDT)
GO
CREATE TYPE TestSchema.UDTi FROM INT;
GO
CREATE TABLE TestSchema.tbli(i TestSchema.UDTi)
GO
