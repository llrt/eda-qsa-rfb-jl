# essa é uma análise exploratória (EDA) da base pública de CNPJs (QSA) da Receita Federal do Brasil (RFB)

## carrega bibliotecas relevantes
using DataFrames # para manipulação de data frames
#using CSV # para ler CSVs
using SQLite, Tables # para ler SQLites
using StatsBase, Statistics # para estatística básica
using Queryverse # metapacote para data science
using Gadfly


## lendo arquivo de entrada
db = SQLite.DB("bd_dados_qsa_cnpj.db") # carrega o arquivo SQLite com as tabelas

## cria índices com colunas úteis para consultas
# SQLite.createindex!(db, "cnpj_dados_cadastrais_pj", "idx_situacao_cadastral", "situacao_cadastral", 
#     unique=false, ifnotexists=true)

# SQLite.createindex!(db, "cnpj_dados_cadastrais_pj", "idx_identificador_matriz_filial", "identificador_matriz_filial", 
#     unique=false, ifnotexists=true)

# SQLite.createindex!(db, "cnpj_dados_cadastrais_pj", "idx_porte_empresa", "porte_empresa", 
#     unique=false, ifnotexists=true)

# SQLite.createindex!(db, "cnpj_dados_cadastrais_pj", "idx_opcao_pelo_simples", "opcao_pelo_simples", 
#     unique=false, ifnotexists=true)

# SQLite.createindex!(db, "cnpj_dados_cadastrais_pj", "idx_opcao_pelo_mei", "opcao_pelo_mei", 
#     unique=false, ifnotexists=true)

# SQLite.createindex!(db, "cnpj_dados_cadastrais_pj", "idx_cnpj", "cnpj", 
#     unique=true, ifnotexists=true)


## executa a consulta base e retorna um result set, que será depois usado 
# para trazer as empresas de interesse
# IMPORTANTE: como a base é muito grande, para reduzir o uso massivo de memória RAM
# é crucial ter uma consulta base que já filtre as empresas de principal interesse - 
# no nosso caso só estamos interessados nas empresas ativas (situacao_cadastral='02'),
# matrizes (identificador_matriz_filial = '1'), e sem considerar MEIs (opcao_pelo_mei = 'N') 
# - e restrinja os campos de interesse; 
# como teremos de fazer já a consulta, vamos aproveitar para fazer joins e transformações
# interessantes
dados_pj_rs = 
    DBInterface.execute(db, 
"
    SELECT 
        pj.cnpj, 
        pj.nome_fantasia, 
        pj.situacao_cadastral as situacao, 
        case pj.porte_empresa 
            when '00' then '?'
            when '01' then 'MICRO'
            when '03' then 'PEQUENA'
            when '05' then 'DEMAIS'
        end as porte, 
        case pj.opcao_pelo_simples
            when '' then 'N'
            when '0' then 'N'
            when '5' then 'S'
            when '7' then 'S'
            when '6' then 'S - Excluido'
            when '8' then 'S - Excluido'
        end as simples,
        case pj.opcao_pelo_mei 
            when 'S' then 'S'
            else 'N'
        end as MEI,
        nat_jur.nm_natureza_juridica as nat_juridica,
        pj.data_inicio_atividade as dat_ini_atividade, 
        pj.cnae_fiscal as cod_cnae_principal, 
        cnae.nm_cnae as cnae_principal,
        cnae.nm_divisao as divisao_cnae_principal,
        cnae.nm_classe as classe_cnae_principal,
        cnae.nm_grupo as grupo_cnae_principal,
        pj.bairro, pj.codigo_municipio as cod_municipio, pj.municipio, pj.uf
    FROM `cnpj_dados_cadastrais_pj` pj 
        INNER JOIN `tab_cnae` cnae on cnae.cod_cnae = pj.cnae_fiscal 
        INNER JOIN `tab_natureza_juridica` nat_jur on nat_jur.cod_subclass_natureza_juridica = pj.codigo_natureza_juridica
    WHERE 
        situacao_cadastral='02' -- somente ativas
        and identificador_matriz_filial='1' -- somente matrizes
        and pj.opcao_pelo_mei = 'N' -- não considerar MEIs (muito numerosos, não são empresas, mas empresários individuais)
    ;
") # consulta base  

# OBS: o result set somente suporta ser consumido uma única vez (single pass, forware only). 
# Para usá-lo de novo, é preciso resetá-lo (rodar a query de novo) com: SQLite.reset!(dados_pj_rs)


## tendo o result set inicial, podemos executar as análises de interesse

### configurações gerais de plot
include("estilo_plot.jl")
Gadfly.push_theme(estilo_plot())
set_default_plot_size(21cm, 10cm)

## Análise 1: quantos cartórios temos no Brasil?
SQLite.reset!(dados_pj_rs) # para recarregar o result set, se necessário
dados_cartorios = dados_pj_rs |> 
    @filter(_.cnae_principal=="Cartórios") |>
    DataFrame

print("O Brasil possui $(nrow(dados_cartorios)) cartórios!")


# mas onde eles estão localizados? são muitos porque temos muitas cidades?
dados_cartorios_uf = dados_cartorios |> 
    @groupby(_.uf) |> @map({uf=key(_), n_cartorios=length(_), n_cartorios_str=string(length(_)) }) |> @orderby_descending(_.n_cartorios)

dados_cartorios_uf_municipios = dados_cartorios |> 
    @select(:uf, :municipio) |> @unique() |> 
    @groupby(_.uf) |> @map({uf=key(_), n_municipios=length(_), n_municipios_str=string(length(_))}) |> @orderby_descending(_.n_municipios)

comparacao_cartorios_uf = dados_cartorios_uf |> 
    @join(dados_cartorios_uf_municipios, _.uf, _.uf, {_.uf, _.n_cartorios, _.n_cartorios_str, __.n_municipios, __.n_municipios_str}) |> 
    @orderby_descending(_.n_cartorios) |> DataFrame

print(comparacao_cartorios_uf)

set_default_plot_size(30cm, 18cm)

p1 = plot(comparacao_cartorios_uf |> @take(10) |> DataFrame, 
    y=:uf, x=:n_cartorios, label=:n_cartorios_str,
    Geom.bar(orientation=:horizontal), Geom.label(position=:right),
    Scale.x_continuous(format=:plain),
    Guide.title("Top 10 UFs em nr cartórios"), Guide.xlabel("Cartórios"), Guide.ylabel("UF"))

p2 = plot(comparacao_cartorios_uf |> @orderby_descending(_.n_municipios) |> @take(10) |> DataFrame, 
    y=:uf, x=:n_municipios, label=:n_municipios_str,
    Geom.bar(orientation=:horizontal), Geom.label(position=:right),
    Scale.x_continuous(format=:plain),
    Guide.title("Top 10 UFs em nr municípios"),  Guide.xlabel("Municípios"), Guide.ylabel("UF"))

vstack(p1, p2)