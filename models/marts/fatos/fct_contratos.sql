-- Grão: um contrato (escola × marca × ano letivo).

with contratos as (
    select * from {{ ref('stg_contratos') }}
),

renovacao as (
    select * from {{ ref('int_contratos_renovacao') }}
),

parcelas as (
    select
        id_contrato,
        sum(valor_parcela)                                                    as valor_faturado,
        sum(case when dt_pagamento is not null then valor_parcela else 0 end) as valor_pago,
        sum(case when status_parcela = 'vencido' then valor_parcela else 0 end) as valor_vencido_em_aberto,
        sum(case when status_parcela = 'vencido' then 1 else 0 end)           as qtd_parcelas_vencidas
    from {{ ref('int_pagamentos_classificados') }}
    group by id_contrato
)

select
    c.id_contrato,
    c.cod_escola,
    c.id_marca,
    c.ano_letivo,
    c.dt_assinatura,
    c.status_contrato,
    r.eh_contrato_novo,
    r.foi_renovado,
    c.qtd_alunos_contratados,
    c.valor_por_aluno,
    c.valor_total_contrato,
    cast(coalesce(p.valor_faturado, 0) as decimal(14, 2))          as valor_faturado,
    cast(coalesce(p.valor_pago, 0) as decimal(14, 2))              as valor_pago,
    cast(coalesce(p.valor_vencido_em_aberto, 0) as decimal(14, 2)) as valor_vencido_em_aberto,
    cast(coalesce(p.qtd_parcelas_vencidas, 0) as int)              as qtd_parcelas_vencidas
from contratos as c
left join renovacao as r
    on r.id_contrato = c.id_contrato
left join parcelas as p
    on p.id_contrato = c.id_contrato
