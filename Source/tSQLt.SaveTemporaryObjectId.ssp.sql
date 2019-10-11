IF OBJECT_ID('tSQLt.SaveTemporaryObjectId') IS NOT NULL DROP PROCEDURE tSQLt.SaveTemporaryObjectId;
GO
---Build+
CREATE PROCEDURE tSQLt.SaveTemporaryObjectId
  @TempObjectId INT
  ,@OrgObjectId INT
AS
BEGIN
  IF NOT EXISTS (SELECT * FROM tSQLt.TemporaryObject WHERE TempObjectId = @TempObjectId)
  BEGIN
    INSERT INTO tSQLt.TemporaryObject
    (
        TempObjectId
        ,OrgObjectId
    )
    VALUES
    (
        @TempObjectId
        ,@OrgObjectId
    );
  END
END
---Build-
GO