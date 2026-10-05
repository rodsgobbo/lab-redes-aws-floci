#!/bin/bash
# Passo 2: sobe um servidor EC2 na subnet publica com o site
set -e
source ids.env
ID=$(aws ec2 run-instances --image-id ami-ubuntu2204 --instance-type t3.micro --subnet-id $PUB --security-group-ids $SG --user-data file://userdata.sh --query 'Instances[0].InstanceId' --output text)
echo "ID=$ID" >> ids.env
echo "Servidor criado: $ID (o site leva 1 a 2 minutos para ficar pronto)"
sleep 5
aws ec2 describe-instances --instance-ids $ID --query 'Reservations[0].Instances[0].{estado:State.Name,ip_privado:PrivateIpAddress}' --output table
