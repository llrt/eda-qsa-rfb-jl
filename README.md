# Análise exploratória da base pública de CNPJs (QSA) da Receita Federal do Brasil (RFB)

Esse é um repositório em Julia com análise exploratória (EDA) em cima da base pública de CNPJs (QSA - que inclui além dos dados de empresa, também os CNAEs e o quadro societário delas) que a RFB [disponibiliza](https://receita.economia.gov.br/orientacao/tributaria/cadastros/cadastro-nacional-de-pessoas-juridicas-cnpj/dados-publicos-cnpj). Para entender o layout da base disponibilizada, consulte a documentação disponível no site da RFB. 

A análise é vagamente inspirada em outras análises disponíveis em R, como [esta](https://www.curso-r.com/blog/2019-09-20-qsacnpj/). 

Para baixar a base completa do QSA, você pode utilizar o excelente [Brasil.io](https://brasil.io/), um portal de dados públicos ("libertos") brasileiros. A base do QSA em CSV neste site está [aqui](https://data.brasil.io/dataset/socios-brasil/_meta/list.html). 

**Atenção:** a base QSA em CSV é **muito** grande (cerca de 2.4 GB para a parte de empresas, 0,4 GB para a parte de sócios, 0,7 GB para a parte de CNAE) - tenha certeza que possui espaço disponível em seu HD e memória RAM suficiente para processá-la. Caso não tenha, é possível gerar uma base *trimmada* (enxugada, recortada com algum critério específico) usando pacotes como o [`qsacnpj`](https://github.com/georgevbsantiago/qsacnpj) no R. Neste repositório o autor gentilmente disponibiliza também os arquivos estáticos base em formato SQLite - que na minha experiência é muito melhor para fazer consultas e agregações com menor necessidade de memória RAM, motivo pelo qual será esta a base que utilizaremos.


## Base utilizada

Como dito acima, a base que será utilizada nessa EDA é a base QSA em formato SQLite obtida a partir do repositório `qsacnpj`. A base utilizada foi a de [04/07/2020](https://github.com/georgevbsantiago/qsacnpj#base-de-dados-do-cnpj-tratada), com tamanho aproximado de 5,3 GB comprimidos (19,1 GB descomprimidos) e 43,9 milhões de CNPJs. Para não deixar pesado o repositório, o arquivo estático *não* será incluído. O esquema relacional se encontra [aqui](https://raw.githubusercontent.com/georgevbsantiago/qsacnpj/master/img/esquema_cnpj.png)   

## Bibliotecas utilizadas

- **DataFrames**: para criar e manipular estruturas de data frames
- **CSV**: para importar arquivos CSV
- **StatsBase**: para realizar análises estatísticas básicas
- **Queryverse**: para manipulação de data frames usando um estilo `dplyr/tidyverse`
- **Gadfly**: para plotar gráficos usando um estilo `ggplot`
- **Cairo**: para salvar os plots gerados em formato PNG