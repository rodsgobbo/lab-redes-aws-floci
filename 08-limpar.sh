#!/bin/bash
# Passo 8: apaga o servidor e o alarme
source ids.env
aws ec2 terminate-instances --instance-ids $ID --query 'TerminatingInstances[0].CurrentState.Name' --output text
aws cloudwatch delete-alarms --alarm-names site-fora
echo ""
echo "Servidor e alarme apagados, como se faz na AWS de verdade."
echo "Para desmontar o resto no seu computador, rode:"
echo ""
echo "    docker compose run --rm desmontar"
