#!/bin/bash
# Passo 8: apaga o servidor e o alarme
source ids.env
aws ec2 terminate-instances --instance-ids $ID --query 'TerminatingInstances[0].CurrentState.Name' --output text
aws cloudwatch delete-alarms --alarm-names site-fora
echo ""
echo "Agora, no terminal do seu computador, rode estes comandos:"
echo ""
echo "    docker rm -f floci-ui        (so se voce abriu o painel do Floci, porta 4500)"
echo "    docker compose down"
echo "    docker network rm floci-vpc-4566-us-east-1-$VPC"
