USE master;
GO
EXECUTE AS LOGIN='SA';
GO
CREATE LOGIN <login_name, sysname, [Domain\TeamCity]> FROM WINDOWS WITH DEFAULT_DATABASE=[tempdb], DEFAULT_LANGUAGE=[us_english]
GO
GRANT IMPERSONATE ON LOGIN::[tSQLt.Build] TO <login_name, sysname, [Domain\TeamCity]>;
GO
