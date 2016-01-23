IF OBJECT_ID('tSQLt.Private_NewTestClassList') IS NOT NULL DROP TABLE tSQLt.Private_NewTestClassList;
---Build+
CREATE TABLE tSQLt.Private_NewTestClassList (
  ClassName NVARCHAR(450) PRIMARY KEY CLUSTERED
);
---Build-
