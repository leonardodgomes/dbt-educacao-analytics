-- Grão: uma parcela de contrato.

with parcelas as (
    select * from {{ ref('int_pagamentos_classificados') }}
),

contratos as (
    select id_contrato, cod_escola, id_marca, ano_letivo
    from {{ ref('stg_contratos') }}
)

select
    p.id_parcela,
    p.id_contrato,
    c.cod_escola,
    c.id_marca,
    c.ano_letivo,
    p.num_parcela,
    p.dt_vencimento,
    p.dt_pagamento,
    p.valor_parcela,
    p.status_parcela,
    p.dias_atraso
from parcelas as p
inner join contratos as c
    on c.id_contrato = p.id_contrato
