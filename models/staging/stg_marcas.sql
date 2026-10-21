with fonte as (
    select * from {{ source('educacao_raw', 'raw_marcas') }}
)

select
    trim(id_marca)        as id_marca,
    trim(nome_marca)      as nome_marca,
    lower(trim(segmento)) as segmento
from fonte
