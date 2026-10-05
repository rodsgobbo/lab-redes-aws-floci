#!/bin/bash
# Passo 6: simula a falha desligando o servidor
source ids.env
aws ec2 stop-instances --instance-ids $ID --query 'StoppingInstances[0].CurrentState.Name' --output text
