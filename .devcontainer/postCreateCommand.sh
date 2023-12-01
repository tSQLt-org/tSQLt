cd "$(dirname "$0")"

docker --version
docker-compose -f sqlserver.yml up -d --force-recreate

cd "$TSQLTCERTPATH"
openssl req -x509 -newkey rsa:4096 -keyout tSQLtOfficialSigningKey.key -out tSQLtOfficialSigningKey.crt -days 365 -nodes -subj "/CN=yourdomain.com"
openssl pkcs12 -export -out tSQLtOfficialSigningKey.pfx -inkey tSQLtOfficialSigningKey.key -in tSQLtOfficialSigningKey.crt -passout pass:"$TSQLTCERTPASSWORD"


# pwsh -File ../tSQLt/PrepareServer.ps1