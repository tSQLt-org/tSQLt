cd "$(dirname "$0")"

docker --version
docker-compose -f sqlserver.yml up -d