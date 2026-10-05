#!/bin/bash
# Passo 5: o "painel": ultimas metricas, ultimos logs e o estado do alarme
INICIO=$(date -u -d '-3 minutes' +%Y-%m-%dT%H:%M:%SZ); FIM=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo "== Disponibilidade (1 = no ar, 0 = fora), por minuto"
aws cloudwatch get-metric-statistics --namespace LabSenai --metric-name Disponivel --start-time $INICIO --end-time $FIM --period 60 --statistics Minimum Average --query 'sort_by(Datapoints,&Timestamp)[].[Timestamp,Minimum,Average]' --output table
echo "== Latencia media (ms)"
aws cloudwatch get-metric-statistics --namespace LabSenai --metric-name LatenciaMs --start-time $INICIO --end-time $FIM --period 60 --statistics Average --query 'sort_by(Datapoints,&Timestamp)[].[Timestamp,Average]' --output table
echo "== Ultimos logs"
aws logs get-log-events --log-group-name /lab/senai --log-stream-name sonda --limit 5 --query 'events[].message' --output text | tr '\t' '\n'
echo "== Alarme"
aws cloudwatch describe-alarms --alarm-names site-fora --query 'MetricAlarms[0].{alarme:AlarmName,estado:StateValue,motivo:StateReason}' --output table
