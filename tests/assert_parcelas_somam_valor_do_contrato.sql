-- Para contratos não cancelados, a soma das parcelas deve bater com o valor do contrato.
-- Retorna os contratos em que a diferença passa de R$ 0,01 (o teste falha se houver linhas).

with parcelas as (
    select id_contrato, sum(valor_parcela) as soma_parcelas
    from {{ ref('fct_parcelas') }}
    group by id_contrato
)

select
    c.id_contrato,
    c.valor_total_contrato,
    p.soma_parcelas
from {{ ref('fct_contratos') }} as c
inner join parcelas as p
    on p.id_contrato = c.id_contrato
where c.status_contrato <> 'cancelado'
  and abs(c.valor_total_contrato - p.soma_parcelas) > 0.01
