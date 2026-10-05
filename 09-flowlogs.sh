#!/bin/bash
# Extra NAO validado: no Floci 2.1.0 os VPC Flow Logs sao criados, mas nao chegam ao CloudWatch Logs.
# Deixado aqui so como referencia para a AWS de verdade.
source ids.env
aws ec2 create-flow-logs --resource-type VPC --resource-ids $VPC --traffic-type ALL \
  --log-destination-type cloud-watch-logs \
  --log-destination arn:aws:logs:us-east-1:000000000000:log-group:/lab/flowlogs \
  --deliver-logs-permission-arn arn:aws:iam::000000000000:role/flowlogs
