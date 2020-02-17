IF OBJECT_ID('tSQLt.TemporaryObject') IS NOT NULL DROP TABLE tSQLt.TemporaryObject;
---Build+
CREATE TABLE tSQLt.TemporaryObject
(
    TempObjectId INT
    ,OrgObjectId INT
);
---Build-