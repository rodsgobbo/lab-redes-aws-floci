#!/bin/bash
# Mostra a pagina do site, acessando o servidor pela rede do laboratorio
source ids.env
echo "Acessando http://floci-ec2-$ID:8080/ ..."
curl -s -m 5 -w "\n(HTTP %{http_code}, %{time_total}s)\n" "http://floci-ec2-$ID:8080/" || echo "O site ainda nao respondeu. Espere mais um minuto e tente de novo."
