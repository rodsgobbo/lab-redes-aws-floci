#!/bin/sh
# Sobe o site (nginx) de novo depois de religar o servidor.
# No Floci o servidor e um conteiner sem servico de inicializacao, entao o site nao volta sozinho.
# Roda num conteiner com o cliente do Docker: le o codigo do servidor no ids.env, sem precisar copiar nada.
. /lab/ids.env
if [ -z "$ID" ]; then
  echo "Nao achei o servidor no ids.env. Rode este comando na mesma pasta dos passos anteriores."
  exit 1
fi
SERVIDOR="floci-ec2-$ID"
echo "Esperando o servidor $ID ligar..."
for i in $(seq 1 30); do
  [ "$(docker inspect -f '{{.State.Running}}' "$SERVIDOR" 2>/dev/null)" = "true" ] && break
  sleep 1
done
if [ "$(docker inspect -f '{{.State.Running}}' "$SERVIDOR" 2>/dev/null)" != "true" ]; then
  echo "O servidor nao esta ligado. Rode antes: docker compose run --rm cli 07-religar.sh"
  exit 1
fi
if docker exec "$SERVIDOR" pgrep -x nginx >/dev/null 2>&1; then
  echo "O site ja estava no ar."
else
  docker exec "$SERVIDOR" nginx && echo "Site no ar de novo. Confira com: docker logs --tail 5 sonda"
fi

# Depois de religar, o Floci nao publica de novo a porta do site no seu computador.
# Aqui a gente recria essa ponte (porta 30000 em diante -> porta 8080 do servidor).
PONTE="floci-ec2-fwd-$ID-8080"
PORTA=$(docker port "$PONTE" 8080 2>/dev/null | head -1 | sed 's/.*://')
if [ -z "$PORTA" ]; then
  docker rm -f "$PONTE" >/dev/null 2>&1
  docker image inspect alpine/socat >/dev/null 2>&1 || docker pull -q alpine/socat >/dev/null
  for P in 30000 30001 30002 30003 30004 30005 30006 30007 30008 30009; do
    if docker run -d --name "$PONTE" --network labnet -p "$P:8080" alpine/socat \
         TCP-LISTEN:8080,fork,reuseaddr "TCP:$SERVIDOR:8080" >/dev/null 2>&1; then
      PORTA=$P
      break
    fi
    docker rm -f "$PONTE" >/dev/null 2>&1
  done
fi
if [ -n "$PORTA" ]; then
  echo "No navegador do seu computador:  http://localhost:$PORTA"
fi
