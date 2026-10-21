with fonte as (
    select * from {{ source('educacao_raw', 'raw_pagamentos') }}
)

select
    trim(id_parcela)                     as id_parcela,
    trim(id_contrato)                    as id_contrato,
    cast(num_parcela as int)             as num_parcela,
    cast(dt_vencimento as date)          as dt_vencimento,
    cast(dt_pagamento as date)           as dt_pagamento,
    cast(valor_parcela as decimal(14, 2)) as valor_parcela
from fonte
