#!/bin/sh
# Desmonta o laboratorio inteiro no seu computador: conteineres e redes.
# Roda num conteiner com o cliente do Docker, entao funciona igual no Windows, no Mac e no Linux.
echo "Desmontando o laboratorio..."
docker rm -f sonda floci-ui console floci >/dev/null 2>&1
SERVIDORES=$(docker ps -aq --filter "name=floci-ec2")
[ -n "$SERVIDORES" ] && docker rm -f $SERVIDORES >/dev/null && echo "Servidores apagados"
REDES=$(docker network ls -q --filter "name=floci-vpc")
[ -n "$REDES" ] && docker network rm $REDES >/dev/null && echo "Redes de VPC apagadas"
docker network rm labnet >/dev/null 2>&1
: > /lab/ids.env
echo ""
SOBROU=$(docker ps -a --format '{{.Names}}' | grep -E '^(floci|console|sonda)' ; docker network ls --format '{{.Name}}' | grep -E '^(labnet|floci-vpc)')
if [ -z "$SOBROU" ]; then
  echo "Pronto: nao sobrou nada do laboratorio."
else
  echo "Ainda sobrou (rode de novo em alguns segundos):"
  echo "$SOBROU"
fi
