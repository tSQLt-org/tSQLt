<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
        xmlns:lxslt="http://xml.apache.org/xslt"
        xmlns:stringutils="xalan://org.apache.tools.ant.util.StringUtils">
  <xsl:output indent="yes"/>
  <xsl:decimal-format decimal-separator="." grouping-separator="," />

  <xsl:variable name="guidStub">
    <xsl:call-template name="testRunGuid">
      <xsl:with-param name="timestamp" select="/testsuite/@timestamp"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:template match="/">
    <TestRun xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2006">
      <xsl:attribute name="id">
        <xsl:value-of select="concat($guidStub,'FE9CF17251B6')"/>
      </xsl:attribute>
      <xsl:attribute name="runUser">
        <xsl:value-of select="concat(/testsuite/@hostname,'\',/testsuite/properties/property[@name='user.name']/@value)"/>
      </xsl:attribute>
      <xsl:attribute name="name">
        <xsl:value-of select="concat(/testsuite/properties/property[@name='user.name']/@value,'@',/testsuite/@hostname,' ',/testsuite/@name,' ',/testsuite/@timestamp)"/>
      </xsl:attribute>

      <TestRunConfiguration name="JUnit Test Run" id="3A1F7DF7-266A-41d6-8995-A19DDA49FAED">
        <Description>This is an imported JUnit test run.</Description>
        <CodeCoverage enabled="false" />
        <Deployment useDefaultDeploymentRoot="false">
          <xsl:attribute name="runDeploymentRoot">
            <xsl:value-of select="/testsuite/properties/property[@name='basedir']/@value" />
          </xsl:attribute>
        </Deployment>
      </TestRunConfiguration>

      <xsl:variable name="testsuiteName" select="/testsuite/@name" />

      <xsl:variable name="failed_count" select="/testsuite/@failures"/>
      <xsl:variable name="errors_count" select="/testsuite/@errors"/>
      <xsl:variable name="total_count" select="/testsuite/@tests"/>
      <xsl:variable name="pass_count" select="$total_count - $failed_count - $errors_count"/>

      <ResultSummary>
        <xsl:attribute name="outcome">
          <xsl:choose >
            <xsl:when test="$total_count=$pass_count">
              <xsl:value-of select="'Passed'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'Failed'"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>

        <Counters timeout="0" aborted="0" inconclusive="0" passedButRunAborted="0" notRunnable="0" notExecuted="0" disconnected="0" warning="0" completed="0" inProgress="0" pending="0">
          <xsl:attribute name="total">
            <xsl:value-of select="$total_count"/>
          </xsl:attribute>
          <xsl:attribute name="executed">
            <xsl:value-of select="$total_count"/>
          </xsl:attribute>
          <xsl:attribute name="passed">
            <xsl:value-of select="$pass_count"/>
          </xsl:attribute>
          <xsl:attribute name="failed">
            <xsl:value-of select="$failed_count"/>
          </xsl:attribute>
          <xsl:attribute name="error">
            <xsl:value-of select="$errors_count"/>
          </xsl:attribute>
        </Counters>

      </ResultSummary>

      <Times creation="2008-01-01T00:00:00.0000000+0:00" queuing="2008-01-01T00:00:00.0000000+0:00" start="2008-01-01T00:00:00.0000000+0:00" finish="2008-01-01T00:00:00.0000000+0:00" />

      <Build flavor="Release" platform="AnyCPU" />

      <TestDefinitions>
        <xsl:for-each select="//testcase">
          <xsl:variable name="testName" select="concat(@classname,'.',@name)" />
          <xsl:variable name="pos" select="position()" />

          <UnitTest>
            <xsl:attribute name="name">
              <xsl:value-of select="$testName"/>
            </xsl:attribute>
            <xsl:attribute name="id">
              <xsl:call-template name="testIdGuid">
                <xsl:with-param name="value" select="$pos" />
                <xsl:with-param name="name" select="$testName" />
              </xsl:call-template>
            </xsl:attribute>

            <Css projectStructure="" iteration="" />
            <Owners>
              <Owner name="" />
            </Owners>

            <Execution>
              <xsl:attribute name="id">
                <xsl:call-template name="executionIdGuid">
                  <xsl:with-param name="value" select="$pos"/>
                </xsl:call-template>
              </xsl:attribute>
            </Execution>

            <TestMethod>
              <xsl:attribute name="name">
                <xsl:value-of select="$testName"/>
              </xsl:attribute>
              <xsl:attribute name="codeBase">
                <xsl:value-of select="$testsuiteName"/>
              </xsl:attribute>
              <xsl:attribute name="className">
                <xsl:value-of select="@classname"/>
              </xsl:attribute>
            </TestMethod>

          </UnitTest>

        </xsl:for-each>
      </TestDefinitions>

      <TestLists>
        <TestList name="Results Not in a List" id="8c84fa94-04c1-424b-9868-57a2d4851a1d" />
        <TestList name="All Loaded Results" id="19431567-8539-422a-85d7-44ee4e166bda" />
      </TestLists>

      <TestEntries>
        <xsl:for-each select="//testcase">
          <xsl:variable name="pos" select="position()" />
          <TestEntry testListId="8c84fa94-04c1-424b-9868-57a2d4851a1d">
            <xsl:attribute name="testId">
              <xsl:call-template name="testIdGuid">
                <xsl:with-param name="value" select="$pos"/>
              </xsl:call-template>
            </xsl:attribute>
            <xsl:attribute name="executionId">
              <xsl:call-template name="executionIdGuid">
                <xsl:with-param name="value" select="$pos"/>
              </xsl:call-template>
            </xsl:attribute>
          </TestEntry>
        </xsl:for-each>
      </TestEntries>

      <Results>
        <xsl:for-each select="//testcase">
          <xsl:variable name="testName" select="concat(@classname,'.',@name)" />
          <xsl:variable name="pos" select="position()" />
          <UnitTestResult startTime="2008-01-01T00:00:01.0000000+0:00" endTime="2008-01-01T00:00:02.0000000+0:00" testType="13cdc9d9-ddb5-4fa4-a97d-d965ccfc6d4b" testListId="8c84fa94-04c1-424b-9868-57a2d4851a1d">
            <xsl:attribute name="testName">
              <xsl:value-of select="$testName"/>
            </xsl:attribute>
            <xsl:attribute name="computerName">
              <xsl:value-of select="/testsuite/@hostname"/>
            </xsl:attribute>
            <xsl:attribute name="duration">
              <xsl:value-of select="substring(concat('00:00:0',@time,'0000'),1,14)" />
            </xsl:attribute>
            <xsl:attribute name="testId">
              <xsl:call-template name="testIdGuid">
                <xsl:with-param name="value" select="$pos"/>
              </xsl:call-template>
            </xsl:attribute>
            <xsl:attribute name="executionId">
              <xsl:call-template name="executionIdGuid">
                <xsl:with-param name="value" select="$pos"/>
              </xsl:call-template>
            </xsl:attribute>
            <xsl:attribute name="outcome">
              <xsl:choose >
                <xsl:when test="count(descendant::failure) + count(descendant::error) = 0">
                  <xsl:value-of select="'Passed'"/>
                </xsl:when>
                <xsl:when test="count(descendant::error) = 0 ">
                  <xsl:value-of select="'Error'"/>
                </xsl:when>                
                <xsl:otherwise>
                  <xsl:value-of select="'Failed'"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:attribute>
            <Output>
              <xsl:for-each select="./failure">
                <ErrorInfo>
                  <Message>
                    <xsl:value-of select="@message"/>
                  </Message>
                  <StackTrace>
                    <xsl:value-of select="."/>
                  </StackTrace>
                </ErrorInfo>
              </xsl:for-each>
              <xsl:for-each select="./error">
                <ErrorInfo>
                  <Message>
                    <xsl:value-of select="@message"/>
                  </Message>
                  <StackTrace>
                    <xsl:value-of select="."/>
                  </StackTrace>
                </ErrorInfo>
              </xsl:for-each>              
            </Output>
          </UnitTestResult>
        </xsl:for-each>
      </Results>

    </TestRun>
  </xsl:template>

  <!--  TODO StdOut and StdErr -->

  <!-- Psuedo-Guid generation  -->

  <xsl:template name="executionIdGuid">
    <xsl:param name="value" />
    <xsl:variable name="id">
      <xsl:call-template name="dec_to_hex">
        <xsl:with-param name="value" select="$value"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="concat($guidStub,substring(concat('00000000EE00', $id),string-length($id) + 1, 12))"/>
  </xsl:template>

  <xsl:template name="testIdGuid">
    <xsl:param name="value" />
    <xsl:param name="name" />
    <xsl:variable name="id">
      <xsl:call-template name="dec_to_hex">
        <xsl:with-param name="value" select="$value"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="concat($guidStub,substring(concat('00000000DD00', $id),string-length($id) + 1, 12))"/>
  </xsl:template>

  <xsl:template name="testRunGuid">
    <xsl:param name="timestamp" />
    <xsl:variable name="year">
      <xsl:value-of select="substring($timestamp,1,4)"/>
    </xsl:variable>
    <xsl:variable name="month">
      <xsl:value-of select="substring($timestamp,6,2)"/>
    </xsl:variable>
    <xsl:variable name="day">
      <xsl:value-of select="substring($timestamp,9,2)"/>
    </xsl:variable>
    <xsl:variable name="hour">
      <xsl:value-of select="substring($timestamp,12,2)"/>
    </xsl:variable>
    <xsl:variable name="minute">
      <xsl:value-of select="substring($timestamp,15,2)"/>
    </xsl:variable>
    <xsl:variable name="second">
      <xsl:value-of select="substring($timestamp,18,2)"/>
    </xsl:variable>
    <xsl:variable name="hexYear">
      <xsl:call-template name="dec_to_hex">
        <xsl:with-param name="value" select="$year"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="hexMonth">
      <xsl:call-template name="dec_to_hex">
        <xsl:with-param name="value" select="$month"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="hexDay">
      <xsl:call-template name="dec_to_hex">
        <xsl:with-param name="value" select="$day"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="hexHour">
      <xsl:call-template name="dec_to_hex">
        <xsl:with-param name="value" select="$hour"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="hexMinute">
      <xsl:call-template name="dec_to_hex">
        <xsl:with-param name="value" select="$minute"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="hexSecond">
      <xsl:call-template name="dec_to_hex">
        <xsl:with-param name="value" select="$second"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="padYear">
      <xsl:value-of select="substring(concat('0000', $hexYear),string-length($hexYear) + 1, 4)"/>
    </xsl:variable>
    <xsl:variable name="padMonth">
      <xsl:value-of select="substring(concat('00', $hexMonth),string-length($hexMonth) + 1, 2)"/>
    </xsl:variable>
    <xsl:variable name="padDay">
      <xsl:value-of select="substring(concat('00', $hexDay),string-length($hexDay) + 1, 2)"/>
    </xsl:variable>
    <xsl:variable name="padHour">
      <xsl:value-of select="substring(concat('00', $hexHour),string-length($hexHour) + 1, 2)"/>
    </xsl:variable>
    <xsl:variable name="padMinute">
      <xsl:value-of select="substring(concat('00', $hexMinute),string-length($hexMinute) + 1, 2)"/>
    </xsl:variable>
    <xsl:variable name="padSecond">
      <xsl:value-of select="substring(concat('00', $hexSecond),string-length($hexSecond) + 1, 2)"/>
    </xsl:variable>
    <xsl:value-of select="concat($padYear,$padMonth,$padDay,'-',$padHour,$padMinute,'-',$padSecond,'ae-A281-')"/>
  </xsl:template>

  <xsl:template name="dec_to_hex">
    <xsl:param name="value" />
    <xsl:if test="$value >= 16">
      <xsl:call-template name="dec_to_hex">
        <xsl:with-param name="value" select="floor($value div 16)" />
      </xsl:call-template>
    </xsl:if>
    <xsl:value-of select="substring('0123456789ABCDEF', ($value mod 16) + 1, 1)" />
  </xsl:template>

</xsl:stylesheet>
