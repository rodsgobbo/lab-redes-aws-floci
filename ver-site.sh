#!/bin/bash
# Mostra a pagina do site no terminal, acessando o servidor pela rede do laboratorio
source ids.env
if [ -z "$ID" ]; then
  echo "Nao achei o servidor no ids.env."
  echo "Rode este comando na mesma pasta em que voce rodou o 01-rede.sh e o 02-servidor.sh."
  exit 1
fi
echo "Acessando http://floci-ec2-$ID:8080/ ..."
if ! curl -sf -m 5 -w "\n(HTTP %{http_code}, %{time_total}s)\n" "http://floci-ec2-$ID:8080/"; then
  echo "O site ainda nao respondeu."
  echo "Se o servidor acabou de ser criado, ele ainda esta instalando o site: espere 1 a 2 minutos e rode de novo."
  echo "Se voce acabou de religar o servidor, rode antes: docker compose run --rm subir-site"
fi
