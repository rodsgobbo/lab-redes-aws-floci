#!/bin/sh
# Testa o site e mostra o endereco para abrir no navegador.
# Roda num conteiner com o cliente do Docker, ligado a rede do laboratorio.
. /lab/ids.env
if [ -z "$ID" ]; then
  echo "Nao achei o servidor no ids.env."
  echo "Rode este comando na mesma pasta em que voce rodou o 01-rede.sh e o 02-servidor.sh."
  exit 1
fi
echo "Testando o site por dentro da rede do laboratorio..."
if ! PAGINA=$(wget -qO- -T 5 "http://floci-ec2-$ID:8080/" 2>/dev/null); then
  echo "O site ainda nao respondeu."
  echo "Se o servidor acabou de ser criado, ele ainda esta instalando o site: espere 1 a 2 minutos e rode de novo."
  echo "Se voce acabou de religar o servidor, rode antes: docker compose run --rm subir-site"
  exit 1
fi
echo "O site respondeu: $PAGINA"
echo ""
PORTA=$(docker port "floci-ec2-fwd-$ID-8080" 8080 2>/dev/null | head -1 | sed 's/.*://')
if [ -n "$PORTA" ]; then
  echo "Abra no navegador do seu computador:  http://localhost:$PORTA"
else
  echo "O site ainda nao esta publicado no seu computador."
  echo "Se voce acabou de religar o servidor, rode: docker compose run --rm subir-site"
fi
