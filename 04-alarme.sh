#!/bin/bash
# Passo 4: cria o alarme que dispara quando o site fica fora por 3 checagens seguidas
aws cloudwatch put-metric-alarm --alarm-name site-fora --namespace LabSenai --metric-name Disponivel \
  --statistic Minimum --period 10 --evaluation-periods 3 --threshold 1 --comparison-operator LessThanThreshold \
  --treat-missing-data breaching
echo "Alarme criado"
