#!/bin/bash

set -eo pipefail

# Create secondary _dev database for development environment

echo "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}_dev\` ;" | "${mysql[@]}"
echo "GRANT ALL ON \`${MYSQL_DATABASE}_dev\`.* TO '$MYSQL_USER'@'%' ;" | "${mysql[@]}"
echo 'FLUSH PRIVILEGES ;' | "${mysql[@]}"
