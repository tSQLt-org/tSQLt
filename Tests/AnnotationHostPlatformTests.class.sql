EXEC tSQLt.NewTestClass 'AnnotationHostPlatformTests';
GO
CREATE FUNCTION AnnotationHostPlatformTests.[SomePlatform]()
RETURNS TABLE
AS
RETURN SELECT NULL AS ProductVersion, NULL AS Edition, 'SomePlatform' AS HostPlatform;
GO
CREATE FUNCTION AnnotationHostPlatformTests.[Platform13]()
RETURNS TABLE
AS
RETURN SELECT NULL AS ProductVersion, NULL AS Edition, 'Platform13' AS HostPlatform;
GO
CREATE PROCEDURE AnnotationHostPlatformTests.[test allows test to execute if actual host platform is equal to the provided one]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:RunOnlyOnHostPlatform](''SomePlatform'')
CREATE PROCEDURE MyInnerTests.[test should execute] AS RAISERROR(''test executed'',16,10);
  ');

  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'AnnotationHostPlatformTests.[SomePlatform]';

  
  EXEC tSQLt_testutil.AssertTestErrors
       @TestName = 'MyInnerTests.[test should execute]',
       @ExpectedMessage = 'test executed%';
END;
GO
CREATE PROCEDURE AnnotationHostPlatformTests.[test doesn't allow test to execute if actual host platform is not equal to the provided one]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:RunOnlyOnHostPlatform](''AnotherPlatform'')
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');

  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'AnnotationHostPlatformTests.[SomePlatform]';

  
  EXEC tSQLt_testutil.AssertTestSkipped
       @TestName = 'MyInnerTests.[test should not execute]';
END;
GO
CREATE PROCEDURE AnnotationHostPlatformTests.[test provides a useful skip reason]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:RunOnlyOnHostPlatform](''AnotherPlatform'')
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');

  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'AnnotationHostPlatformTests.[SomePlatform]';

  
  EXEC tSQLt_testutil.AssertTestSkipped
       @TestName = 'MyInnerTests.[test should not execute]',
       @ExpectedMessage = 'HostPlatform is required to be ''AnotherPlatform'', but is ''SomePlatform''.'
END;
GO
CREATE PROCEDURE AnnotationHostPlatformTests.[test includes current and required HostPlatform in reason message]
AS
BEGIN
  EXEC tSQLt.NewTestClass 'MyInnerTests'
  EXEC('
--[@'+'tSQLt:RunOnlyOnHostPlatform](''Platform17'')
CREATE PROCEDURE MyInnerTests.[test should not execute] AS RAISERROR(''test executed'',16,10);
  ');

  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'AnnotationHostPlatformTests.[Platform13]';

  
  EXEC tSQLt_testutil.AssertTestSkipped
       @TestName = 'MyInnerTests.[test should not execute]',
       @ExpectedMessage = 'HostPlatform is required to be ''Platform17'', but is ''Platform13''.'
END;
GO
