with fonte as (
    select * from {{ source('educacao_raw', 'raw_contratos') }}
),

tipado as (
    select
        trim(id_contrato)                    as id_contrato,
        trim(cod_escola)                     as cod_escola,
        trim(id_marca)                       as id_marca,
        cast(ano_letivo as int)              as ano_letivo,
        cast(qtd_alunos_contratados as int)  as qtd_alunos_contratados,
        -- A fonte envia "1.234,56": tira o separador de milhar e troca a vírgula decimal.
        {{ converter_moeda_br('valor_por_aluno') }} as valor_por_aluno,
        cast(dt_assinatura as date)          as dt_assinatura,
        lower(trim(status_contrato))         as status_contrato
    from fonte
)

select
    *,
    cast(qtd_alunos_contratados * valor_por_aluno as decimal(14, 2)) as valor_total_contrato
from tipado
