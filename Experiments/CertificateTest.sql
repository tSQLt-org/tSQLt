IF(CERT_ID('tSQLtSigningKey') IS NOT NULL) DROP CERTIFICATE tSQLtSigningKey;
GO
CREATE CERTIFICATE tSQLtSigningKey 
ENCRYPTION BY PASSWORD = 'password'  
WITH SUBJECT = 'CN=tSQLt.org, title=tSQLt_OfficialSigningKey',
     EXPIRY_DATE = '2020-12-01T00:00:00.000'
GO
BACKUP CERTIFICATE tSQLtSigningKey TO FILE ='C:\Data\git\tSQLt\tSQLt\tSQLtCLR\OfficialSigningKey\tSQLtSigningKey.cer' 
WITH PRIVATE KEY(FILE='C:\Data\git\tSQLt\tSQLt\tSQLtCLR\OfficialSigningKey\tSQLtSigningKey.pkf', DECRYPTION BY PASSWORD = 'password', ENCRYPTION BY PASSWORD = 'password');
