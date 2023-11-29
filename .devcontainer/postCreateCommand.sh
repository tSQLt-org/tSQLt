cd "$(dirname "$0")"

docker --version
docker-compose -f sqlserver.yml up -d --force-recreate



# pwsh -File ../tSQLt/PrepareServer.ps1