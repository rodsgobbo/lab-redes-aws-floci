#!/bin/bash
# Passo 1: cria a rede (VPC, duas subnets, internet gateway, rota e Security Group)
set -e
VPC=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text)
echo "VPC: $VPC"
PUB=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.0.1.0/24 --query Subnet.SubnetId --output text); echo "Subnet publica: $PUB"
PRIV=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.0.2.0/24 --query Subnet.SubnetId --output text); echo "Subnet privada: $PRIV"
IGW=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text); echo "Internet gateway: $IGW"
aws ec2 attach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC
RT=$(aws ec2 create-route-table --vpc-id $VPC --query RouteTable.RouteTableId --output text); echo "Route table: $RT"
aws ec2 create-route --route-table-id $RT --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW >/dev/null
aws ec2 associate-route-table --route-table-id $RT --subnet-id $PUB >/dev/null
SG=$(aws ec2 create-security-group --group-name web --description "lab SENAI" --vpc-id $VPC --query GroupId --output text); echo "Security group: $SG (libera 8080 e 22)"
aws ec2 authorize-security-group-ingress --group-id $SG --protocol tcp --port 8080 --cidr 0.0.0.0/0 >/dev/null
aws ec2 authorize-security-group-ingress --group-id $SG --protocol tcp --port 22 --cidr 0.0.0.0/0 >/dev/null
echo "--- regras do SG"
aws ec2 describe-security-groups --group-ids $SG --query 'SecurityGroups[0].IpPermissions[].{porta:FromPort,origem:IpRanges[0].CidrIp}' --output table
echo "VPC=$VPC PUB=$PUB PRIV=$PRIV SG=$SG IGW=$IGW RT=$RT" > ids.env
