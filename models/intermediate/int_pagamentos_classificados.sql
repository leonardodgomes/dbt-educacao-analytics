-- Classifica cada parcela pela situação na data de referência.
-- A regra fica isolada aqui e coberta por um teste unitário (_intermediate.yml).

with parcelas as (
    select * from {{ ref('stg_pagamentos') }}
),

referencia as (
    select cast('{{ var("data_referencia") }}' as date) as data_referencia
)

select
    p.id_parcela,
    p.id_contrato,
    p.num_parcela,
    p.dt_vencimento,
    p.dt_pagamento,
    p.valor_parcela,

    case
        when p.dt_pagamento is not null and p.dt_pagamento <= p.dt_vencimento then 'pago_em_dia'
        when p.dt_pagamento is not null then 'pago_com_atraso'
        when p.dt_vencimento < r.data_referencia then 'vencido'
        else 'a_vencer'
    end as status_parcela,

    cast(
        case
            when p.dt_pagamento is not null and p.dt_pagamento > p.dt_vencimento
                then {{ dbt.datediff('p.dt_vencimento', 'p.dt_pagamento', 'day') }}
            when p.dt_pagamento is null and p.dt_vencimento < r.data_referencia
                then {{ dbt.datediff('p.dt_vencimento', 'r.data_referencia', 'day') }}
            else 0
        end
    as int) as dias_atraso

from parcelas as p
cross join referencia as r
