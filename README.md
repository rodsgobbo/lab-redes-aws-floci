# Laboratório: a AWS no seu computador com o Floci

Rede, servidor e observabilidade, **sem conta na AWS e sem cartão de crédito**. Material da palestra "Redes na nuvem" para a turma do Técnico em Redes de Computadores do SENAI Jandira.

Neste laboratório você monta, no seu próprio computador, a mesma rede que viu na palestra: uma VPC com duas subnets, um servidor com um site e uma "sonda" que vigia o site. Depois você derruba o servidor de propósito e vê o alarme disparar, como um time de SRE ou de NOC vê na vida real.

Tudo foi testado do começo ao fim em 05/10/2026, num Windows 11 com Docker Desktop, usando o Floci 2.1.0. As saídas mostradas aqui são as que apareceram no teste; os códigos (como `vpc-...` e `i-...`) mudam a cada vez.

## O que você precisa

- **Docker Desktop** (Windows ou Mac) ou **Docker Engine** (Linux). No Windows, ele usa o WSL 2 e pede a virtualização ligada na BIOS.
- **8 GB de RAM** no Windows. O laboratório inteiro usou cerca de 140 MB; o resto é o próprio Docker.
- **Internet só na primeira vez**, para baixar as imagens. Elas ocupam cerca de 1,3 GB em disco (Floci 323 MB, AWS CLI 649 MB, console 148 MB, Ubuntu 119 MB), mais o nginx que o servidor instala.
- **Os arquivos deste repositório** no seu computador (veja o passo 0).

Você **não** precisa instalar a AWS CLI nem Python: a linha de comando da AWS roda dentro de um contêiner.

### E no Windows?

Funciona, e foi testado justamente num Windows 11. Os arquivos `.sh` são scripts de Linux, mas você nunca roda eles direto. Quando você digita `docker compose run --rm cli 01-rede.sh`, o Docker abre um contêiner Linux, que já vem com a linha de comando da AWS, e roda o script lá dentro.

No PowerShell você só digita comandos que começam com `docker`, e eles são iguais no Windows, no Mac e no Linux. Não abra os `.sh` com duplo clique. Se quiser ler ou mudar um deles, use o VS Code (veja "Se algo der errado").

## O que você vai montar

```text
Seu computador (Docker)
 ├── floci ............ a "AWS de mentira", na porta 4566
 ├── console .......... painel no navegador, em http://localhost:8081
 ├── VPC 10.0.0.0/16 .. a rede privada
 │    ├── subnet pública 10.0.1.0/24
 │    │     └── servidor EC2 (Ubuntu + nginx) em 10.0.1.10, site na porta 8080
 │    └── subnet privada 10.0.2.0/24
 ├── sonda ............ olha o site a cada 5 segundos
 └── CloudWatch ....... guarda métricas, logs e o alarme "site-fora"
```

## Siglas que aparecem

- **AWS** (Amazon Web Services): a nuvem da Amazon.
- **VPC** (Virtual Private Cloud): a rede privada da empresa dentro da nuvem.
- **EC2** (Elastic Compute Cloud): o servidor virtual da AWS. No Floci, cada EC2 vira um contêiner.
- **CLI** (Command Line Interface): comandos digitados no terminal.
- **SG** (Security Group): o firewall de cada servidor.
- **IMDS** (Instance Metadata Service): o serviço que informa ao servidor quem ele é.
- **CloudWatch**: o serviço de observabilidade da AWS, com métricas, logs e alarmes.

## Passo 0: baixar o laboratório e abrir o terminal na pasta

Jeito mais fácil: no topo desta página, clique em **Code** e depois em **Download ZIP**. Descompacte onde quiser.

Se você já usa Git:

```powershell
git clone https://github.com/rodsgobbo/lab-redes-aws-floci.git
```

No Windows, abra o PowerShell e entre na pasta (troque pelo caminho onde você salvou):

```powershell
cd C:\caminho\para\lab-redes-aws-floci
```

## Passo 1: ligar o Floci

```powershell
docker compose up -d
```

Na primeira vez ele baixa as imagens, o que leva alguns minutos. Confira se está no ar:

```powershell
docker ps
```

Tem que aparecer as linhas `floci` e `console` com o status `Up`.

### O console no navegador

Abra **http://localhost:8081**. É o StackPort, um painel feito pela comunidade que mostra os recursos do Floci parecido com o console da AWS. Ele é só de leitura: você cria tudo pelos scripts e acompanha por ele.

Onde olhar em cada passo:

- **ec2:** as VPCs, as subnets, os Security Groups e o servidor.
- **logs:** os registros que a sonda grava.
- **monitoring → Alarms:** o alarme `site-fora` e o estado dele (`OK` ou `ALARM`).

O próprio Floci tem outro painel, em http://localhost:4566/_floci/ui (ele abre em http://localhost:4500). Ele mostra o servidor e a rede, mas não tem tela de alarmes, por isso o laboratório usa o StackPort.

## Passo 2: criar a rede

```powershell
docker compose run --rm cli 01-rede.sh
```

Saída esperada (os códigos mudam a cada vez):

```text
VPC: vpc-cb3beaf4
Subnet publica: subnet-f22d589d
Subnet privada: subnet-c1351f56
Internet gateway: igw-f8d963dd
Route table: rtb-b2b2e275
Security group: sg-80c43c7af271fcefa (libera 8080 e 22)
--- regras do SG
|   origem   |  porta  |
|  0.0.0.0/0 |  8080   |
|  0.0.0.0/0 |  22     |
```

O que aconteceu: você criou a VPC, uma subnet pública e uma privada, um internet gateway (a saída para a internet), uma tabela de rotas mandando a subnet pública para esse gateway e um Security Group liberando as portas 8080 (site) e 22 (SSH). Os códigos ficam guardados no arquivo `ids.env`, que os próximos passos usam.

## Passo 3: subir o servidor

```powershell
docker compose run --rm cli 02-servidor.sh
```

Saída esperada:

```text
Servidor criado: i-64a71dee28c9f485d (o site leva 1 a 2 minutos para ficar pronto)
|  estado  | ip_privado   |
|  running |  10.0.1.10   |
```

O Floci deu ao servidor o IP 10.0.1.10. Na AWS de verdade seria o 10.0.1.4: em cada subnet, a AWS reserva os 4 primeiros endereços e o último (por isso o console mostra 251 IPs livres numa /24, e não 256). Ao ligar, ele roda o arquivo `userdata.sh`, que instala o nginx e cria a página do site. **Espere 1 a 2 minutos** antes do próximo passo.

Rode este passo **uma vez só**. Se rodar de novo, o script avisa que o servidor já existe.

### Ver o site

Pelo terminal:

```powershell
docker compose run --rm cli ver-site.sh
```

Saída esperada: `<h1>Ola, turma de Redes do SENAI!</h1>` e `(HTTP 200 ...)`.

Pelo navegador: o Floci publica no seu computador a porta que o Security Group libera. Descubra qual:

```powershell
docker ps --filter "name=fwd" --format "{{.Ports}}"
```

A saída é parecida com `0.0.0.0:30000->8080/tcp`. Abra no navegador o endereço com o primeiro número, por exemplo `http://localhost:30000`.

Atenção: esse endereço só funciona até o passo 7. Depois de desligar e religar o servidor, o Floci não publica a porta de novo; aí use o `ver-site.sh`.

## Passo 4: criar o alarme

```powershell
docker compose run --rm cli 04-alarme.sh
```

O alarme `site-fora` dispara quando a métrica "Disponivel" fica abaixo de 1 em 3 checagens seguidas de 10 segundos.

Ele já nasce em `ALARM`, e isso é de propósito: a sonda ainda não mandou nenhum dado, e o alarme trata dado ausente como falha. Se o monitoramento parou de falar, você não sabe se está tudo bem. Ele vai para `OK` uns 15 segundos depois de você ligar a sonda no próximo passo.

## Passo 5: ligar a sonda

A sonda roda em segundo plano, olhando o site a cada 5 segundos:

```powershell
docker compose run -d --name sonda cli 03-sonda.sh
```

Para ver o que ela está anotando:

```powershell
docker logs --tail 5 sonda
```

Saída esperada:

```text
18:07:35 status=200 latencia=1ms disponivel=1
18:07:41 status=200 latencia=1ms disponivel=1
18:07:47 status=200 latencia=1ms disponivel=1
```

`status=200` quer dizer que o site respondeu certo. A latência é o tempo de resposta. O horário está em UTC, 3 horas à frente de Brasília: servidores do mundo todo usam UTC para não se confundir com fuso horário. O console converte para o seu horário.

## Passo 6: olhar o painel

```powershell
docker compose run --rm cli 05-painel.sh
```

O painel mostra quatro coisas: a disponibilidade por minuto (mínimo e média), a latência média, os últimos logs e o estado do alarme. Com o site no ar, a disponibilidade fica em 1.0 e o alarme aparece como `OK`.

No navegador, a mesma informação fica em http://localhost:8081, em **monitoring → Alarms**.

## Passo 7: derrubar o servidor

Agora a parte importante: simular a falha.

```powershell
docker compose run --rm cli 06-derrubar.sh
```

Acompanhe a sonda:

```powershell
docker logs --tail 5 sonda
```

Saída esperada:

```text
19:44:10 status=200 latencia=2ms disponivel=1
19:44:19 status=000 latencia=3002ms disponivel=0
19:44:27 status=000 latencia=3002ms disponivel=0
```

O servidor leva uns 30 segundos para desligar, então a sonda ainda mostra `status=200` logo depois do comando. Repita o `docker logs` até aparecer `status=000`, que quer dizer que ninguém respondeu. A partir daí, espere mais 30 segundos e abra o painel de novo:

```powershell
docker compose run --rm cli 05-painel.sh
```

No teste, o alarme mudou para `ALARM` 26 a 31 segundos depois da primeira falha (cerca de 1 minuto depois do comando), com o motivo "Threshold Crossed: 3 datapoint(s) breaching the threshold". A disponibilidade do minuto caiu para 0 e a latência média subiu, por causa das tentativas que esperaram 3 segundos até desistir.

No console (http://localhost:8081, **monitoring → Alarms**), clique no botão de atualizar: o `site-fora` aparece em vermelho, com `ALARM`. Em **ec2**, o servidor aparece como `stopped`.

## Passo 8: religar

```powershell
docker compose run --rm cli 07-religar.sh
```

O script religa o servidor e mostra um comando para você rodar. Ele é parecido com este (o código muda):

```powershell
docker exec floci-ec2-i-64a71dee28c9f485d nginx
```

Esse comando sobe o site de novo. A sonda volta a mostrar `status=200` em poucos segundos, e o alarme volta para `OK` uns 20 segundos depois. Para ver o site, use o `ver-site.sh`: o endereço `localhost:30000` não volta depois de religar.

## Passo 9: apagar tudo

Pare a sonda:

```powershell
docker rm -f sonda
```

Apague o servidor e o alarme:

```powershell
docker compose run --rm cli 08-limpar.sh
```

Se você abriu o painel do próprio Floci (porta 4500), apague o contêiner dele antes de desligar, senão a rede `labnet` fica presa:

```powershell
docker rm -f floci-ui
```

O `08-limpar.sh` termina mostrando os últimos comandos. Desligue o Floci e o console:

```powershell
docker compose down
```

E apague a rede da VPC que o Floci criou no Docker (copie o nome que o script mostrou):

```powershell
docker network rm floci-vpc-4566-us-east-1-vpc-cb3beaf4
```

## O que o teste mostrou sobre o Floci

São diferenças em relação à AWS de verdade, e cada uma ensina alguma coisa:

- **A porta 80 já está ocupada.** No Floci, o serviço de metadados do servidor (IMDS) usa a porta 80. O nginx não conseguia subir nela ("bind() to 0.0.0.0:80 failed"), por isso o site usa a 8080. Conflito de porta é um dos erros mais comuns em redes.
- **O Security Group funciona pela metade.** Para o seu computador, o Floci só abre as portas que o SG libera (a 8080 aparece como 30000 em diante). Mas entre os contêineres da rede do laboratório, o SG não bloqueia: no teste, o site respondeu numa porta que o SG não liberava. Na AWS de verdade, o SG bloqueia sempre.
- **O site não volta sozinho depois de religar.** O servidor do Floci é um contêiner sem serviço de inicialização. Na AWS de verdade, o nginx sobe junto com o sistema. Além disso, a porta publicada no seu computador (30000) não é recriada.
- **Os VPC Flow Logs não funcionaram.** O Floci cria o Flow Log, mas os registros não chegam ao CloudWatch. O arquivo `09-flowlogs.sh` ficou só como referência.

## Se algo der errado

- **"port is already allocated" no passo 1:** outro programa usa a porta 4566 ou a 8081. Feche o programa ou troque a porta no `docker-compose.yml`.
- **A sonda mostra `status=000` desde o começo:** o site ainda está instalando. Espere 2 minutos depois do passo 3.
- **"Cannot connect to the Docker daemon":** o Docker Desktop não está aberto.
- **Comando não encontrado no PowerShell:** confira se você está dentro da pasta `lab-redes-aws-floci`.
- **Erro estranho como `$'\r': command not found`:** você editou um arquivo `.sh` num editor do Windows e ele salvou com fim de linha do Windows (CRLF). No VS Code, troque para LF no canto inferior direito e salve de novo.

## Próximo passo

Quando estiver seguro, repita na AWS de verdade. Antes de criar qualquer coisa, ligue um alerta de gasto (AWS Budgets) e apague tudo ao terminar: lá, servidor ligado custa dinheiro.

Floci: [github.com/floci-io/floci](https://github.com/floci-io/floci)

## Arquivos

| Arquivo | O que faz |
|---|---|
| `docker-compose.yml` | Liga o Floci e o console no navegador, e define o contêiner `cli` com a linha de comando da AWS |
| `01-rede.sh` | Cria a VPC, as subnets, o internet gateway, a rota e o Security Group |
| `02-servidor.sh` | Sobe o servidor EC2 com o site |
| `userdata.sh` | Roda quando o servidor liga: instala o nginx e cria a página |
| `ver-site.sh` | Mostra a página do site pelo terminal |
| `03-sonda.sh` | Olha o site a cada 5 segundos e grava métrica e log no CloudWatch |
| `04-alarme.sh` | Cria o alarme `site-fora` |
| `05-painel.sh` | Mostra métricas, logs e o estado do alarme |
| `06-derrubar.sh` | Desliga o servidor para simular a falha |
| `07-religar.sh` | Religa o servidor |
| `08-limpar.sh` | Apaga o servidor e o alarme |
| `09-flowlogs.sh` | Referência: VPC Flow Logs (não funciona no Floci 2.1.0) |

## Licença

MIT: pode copiar, mudar e usar como quiser.
