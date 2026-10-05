#!/bin/bash
# Passo 3: a "sonda" olha o site a cada 5 segundos e grava metrica e log no CloudWatch
source ids.env
ALVO="http://floci-ec2-$ID:8080/"
aws logs create-log-group --log-group-name /lab/senai 2>/dev/null
aws logs create-log-stream --log-group-name /lab/senai --log-stream-name sonda 2>/dev/null
echo "Sonda olhando $ALVO (Ctrl+C para parar)"
while true; do
  R=$(curl -s -o /dev/null -m 3 -w "%{http_code} %{time_total}" "$ALVO")
  CODIGO=${R% *}; SEG=${R#* }
  MS=$(awk "BEGIN{printf \"%d\", $SEG*1000}")
  if [ "$CODIGO" = "200" ]; then OK=1; else OK=0; fi
  aws cloudwatch put-metric-data --namespace LabSenai --metric-data "MetricName=Disponivel,Value=$OK" "MetricName=LatenciaMs,Value=$MS,Unit=Milliseconds"
  MSG="$(date +%H:%M:%S) status=$CODIGO latencia=${MS}ms disponivel=$OK"
  aws logs put-log-events --log-group-name /lab/senai --log-stream-name sonda --log-events "timestamp=$(date +%s%3N),message=$MSG" >/dev/null
  echo "$MSG"
  sleep 5
done
