using PackageCompiler

## Instruções para gerar sysimage com pacotes úteis pré-compilados, de forma a reduzir enormemente a penalidade
## de latência na carga de pacotes e compilação JIT de funções na 1a utilização - ver
## https://www.youtube.com/watch?v=d7avhSuK2NA para mais infos

PackageCompiler.create_sysimage(
    [:DataFrames, :CSV, :SQLite, :Tables, :StatsBase, 
     :Queryverse, :Gadfly, :Cairo, :Colors, :Statistics]; 
    precompile_statements_file="precompile.jl" 
    #, replace_default=false    # descomente se quiser substituir a sysimage padrão do Julia - 
                                # ela pode ser restaurada com PackageCompiler::restore_default_sysimage, se necessário
    )