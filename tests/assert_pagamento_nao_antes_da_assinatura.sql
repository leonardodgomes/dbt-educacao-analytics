-- Nenhuma parcela pode ter sido paga antes da assinatura do contrato.

select
    p.id_parcela,
    p.dt_pagamento,
    c.dt_assinatura
from {{ ref('fct_parcelas') }} as p
inner join {{ ref('fct_contratos') }} as c
    on c.id_contrato = p.id_contrato
where p.dt_pagamento < c.dt_assinatura
