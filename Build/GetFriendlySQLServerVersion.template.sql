DECLARE @ProductVersion NVARCHAR(128) = CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128));
 DECLARE @FriendlyVersion NVARCHAR(128) = (SELECT FriendlyVersion 
 FROM 
 (  
 /*snip1content*/
 FROM
 (
 /*snip2content*/ 
 )SSV
 )X
 ); 
 PRINT @FriendlyVersion;