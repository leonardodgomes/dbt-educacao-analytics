select
    id_marca,
    nome_marca,
    segmento
from {{ ref('stg_marcas') }}
