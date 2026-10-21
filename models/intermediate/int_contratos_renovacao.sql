-- Marca, para cada contrato, se ele é novo (sem contrato da mesma marca no ano anterior)
-- e se foi renovado (existe contrato não cancelado da mesma marca no ano seguinte).

with contratos as (
    select * from {{ ref('stg_contratos') }}
),

limites as (
    select min(ano_letivo) as primeiro_ano_com_dados
    from contratos
)

select
    atual.id_contrato,

    -- No primeiro ano da base não dá para saber se o contrato é novo.
    case
        when atual.ano_letivo = l.primeiro_ano_com_dados then null
        else anterior.id_contrato is null
    end as eh_contrato_novo,

    -- O ano letivo corrente ainda não tem renovação definida.
    case
        when atual.ano_letivo >= {{ var('ano_letivo_atual') }} then null
        else seguinte.id_contrato is not null
    end as foi_renovado

from contratos as atual
cross join limites as l
left join contratos as anterior
    on  anterior.cod_escola = atual.cod_escola
    and anterior.id_marca   = atual.id_marca
    and anterior.ano_letivo = atual.ano_letivo - 1
left join contratos as seguinte
    on  seguinte.cod_escola = atual.cod_escola
    and seguinte.id_marca   = atual.id_marca
    and seguinte.ano_letivo = atual.ano_letivo + 1
    and seguinte.status_contrato <> 'cancelado'
