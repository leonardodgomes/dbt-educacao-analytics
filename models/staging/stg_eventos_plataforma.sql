with fonte as (
    select * from {{ source('educacao_raw', 'raw_eventos_plataforma') }}
),

-- A fonte reenvia alguns eventos em cargas posteriores.
-- Mantém a versão mais recente de cada id_evento.
deduplicado as (
    select
        *,
        row_number() over (
            partition by id_evento
            order by cast(carregado_em as timestamp) desc
        ) as ordem_carga
    from fonte
)

select
    trim(id_evento)                     as id_evento,
    trim(id_aluno)                      as id_aluno,
    cast(ts_evento as timestamp)        as ts_evento,
    cast(cast(ts_evento as timestamp) as date) as data_evento,
    lower(trim(tipo_evento))            as tipo_evento,
    cast(duracao_min as int)            as duracao_min,
    cast(carregado_em as timestamp)     as carregado_em
from deduplicado
where ordem_carga = 1
