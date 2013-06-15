EXEC tSQLt.NewTestClass 'Private_SqlVariantFormatterTests_2008';
GO
CREATE PROC Private_SqlVariantFormatterTests_2008.[test formats new 2008 data types]
AS
BEGIN
  CREATE TABLE #Input(
    [DATE] DATE,
    [DATETIME2] DATETIME2,
    [DATETIMEOFFSET] DATETIMEOFFSET,
    [TIME] TIME
  );
  INSERT INTO #Input
  SELECT
    '2013-04-05' AS [DATE],
    '2013-04-05T06:07:08.9876543' AS [DATETIME2],
    '2013-04-05T06:07:08.9876543+02:01' AS [DATETIMEOFFSET],
    '06:07:08.9876543'AS [TIME];

  CREATE TABLE #Actual(
    [DATE] NVARCHAR(MAX),
    [DATETIME2] NVARCHAR(MAX),
    [DATETIMEOFFSET] NVARCHAR(MAX),
    [TIME] NVARCHAR(MAX)
  );
  INSERT INTO #Actual
  SELECT
    tSQLt.Private_SqlVariantFormatter([DATE]) AS [DATE],
    tSQLt.Private_SqlVariantFormatter([DATETIME2]) AS [DATETIME2],
    tSQLt.Private_SqlVariantFormatter([DATETIMEOFFSET]) AS [DATETIMEOFFSET],
    tSQLt.Private_SqlVariantFormatter([TIME]) AS [TIME]
  FROM #Input;

  SELECT TOP(0) * INTO #Expected FROM #Actual;
  INSERT INTO #Expected
  SELECT
    '2013-04-05' AS [DATE],
    '2013-04-05T06:07:08.9876543' AS [DATETIME2],
    '2013-04-05T06:07:08.9876543+02:01' AS [DATETIMEOFFSET],
    '06:07:08.9876543' AS [TIME];

  EXEC tSQLt.AssertEqualsTable '#Expected', '#Actual';
END;
GO
