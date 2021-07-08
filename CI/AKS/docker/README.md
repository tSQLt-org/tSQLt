# containerbuild

1. `docker build -f <DIRECTORY>/Dockerfile .`
   1. You can also change directories and run `docker build -f Dockerfile ..`
1. `docker container create -p HOSTPORT:1433 IMAGENAME`
1. `docker container start CONTAINERNAME`
1. `docker container exec 93d676bf0088 sqlcmd -E -S ".,1433" -Q "SELECT @@VERSION"`
1. `sqlcmd -U sa -P "W3lc0mE002" -S ".,41433" -Q "SELECT @@VERSION"`

Changing the sa password.
`$cmd = "Invoke-SqlCmd -Query `"`"ALTER LOGIN sa WITH PASSWORD='test123451'`"`""`
`docker container exec CONTAINERNAMEorID powershell $cmd`
`sqlcmd -Q "SELECT SUSER_NAME() U,SYSDATETIME() T,@@VERSION V;" -S ".,41417" -U "sa" -P "test123451"`