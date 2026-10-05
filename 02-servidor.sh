#!/bin/bash
# Passo 2: sobe um servidor EC2 na subnet publica com o site
set -e
source ids.env
if [ -n "$ID" ]; then
  echo "Ja existe um servidor deste laboratorio: $ID"
  echo "Para comecar de novo, rode primeiro: docker compose run --rm cli 08-limpar.sh"
  exit 1
fi
ID=$(aws ec2 run-instances --image-id ami-ubuntu2204 --instance-type t3.micro --subnet-id $PUB --security-group-ids $SG --user-data file://userdata.sh --query 'Instances[0].InstanceId' --output text)
echo "ID=$ID" >> ids.env
echo "Servidor criado: $ID (o site leva 1 a 2 minutos para ficar pronto)"
sleep 5
aws ec2 describe-instances --instance-ids $ID --query 'Reservations[0].Instances[0].{estado:State.Name,ip_privado:PrivateIpAddress}' --output table
echo ""
echo "Daqui a 2 minutos, veja o site com: docker compose run --rm cli ver-site.sh"
