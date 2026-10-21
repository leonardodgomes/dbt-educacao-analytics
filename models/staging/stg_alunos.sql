with fonte as (
    select * from {{ source('educacao_raw', 'raw_alunos') }}
)

select
    trim(id_aluno)                 as id_aluno,
    trim(cod_escola)               as cod_escola,
    trim(serie)                    as serie,
    upper(trim(segmento_ensino))   as segmento_ensino,
    cast(dt_matricula as date)     as dt_matricula,
    upper(trim(ativo)) = 'S'       as eh_ativo
from fonte
