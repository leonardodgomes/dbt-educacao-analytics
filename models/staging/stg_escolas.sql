with fonte as (
    select * from {{ source('educacao_raw', 'raw_escolas') }}
)

select
    trim(cod_escola)                     as cod_escola,
    trim(nome_escola)                    as nome_escola,
    trim(cidade)                         as cidade,
    upper(trim(uf))                      as uf,
    upper(trim(porte))                   as porte,
    cast(qtd_alunos_estimada as int)     as qtd_alunos_estimada,
    cast(dt_inicio_parceria as date)     as dt_inicio_parceria,
    lower(trim(status))                  as status_escola
from fonte
