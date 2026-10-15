#!/bin/bash
# Passo 7: religa o servidor
source ids.env
aws ec2 start-instances --instance-ids $ID --query 'StartingInstances[0].CurrentState.Name' --output text
echo ""
echo "Servidor religado. No Floci o servidor e um conteiner sem servico de inicializacao,"
echo "entao o site nao volta sozinho. Para subir o site, rode:"
echo ""
echo "    docker compose run --rm subir-site"
