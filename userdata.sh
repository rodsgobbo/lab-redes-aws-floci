#!/bin/bash
# Roda uma vez quando o servidor liga: instala o nginx e cria a pagina do site
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
echo "<h1>Ola, turma de Redes do SENAI!</h1>" > /var/www/html/index.html
# No Floci a porta 80 do servidor ja e usada pelo servico de metadados (IMDS); o site usa a 8080
sed -i 's/listen 80 default_server;/listen 8080 default_server;/; s/listen \[::\]:80 default_server;/listen [::]:8080 default_server;/' /etc/nginx/sites-available/default
nginx
