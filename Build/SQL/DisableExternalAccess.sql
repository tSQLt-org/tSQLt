IF(EXISTS(SELECT 1 FROM tSQLt.Info() WHERE HostPlatform NOT IN ('Linux')))
BEGIN
   EXEC tSQLt.EnableExternalAccess @try = 0, @enable=0;
END;
