-- Grão: uma escola. Tabela larga orientada à entidade (entity-based), pronta para
-- consumo em BI, análises de retenção e perguntas em linguagem natural.
-- Junta contratos, financeiro, alunos e engajamento em indicadores por escola.

{% set ano_atual = var('ano_letivo_atual') %}

with escolas as (
    select * from {{ ref('dim_escola') }}
),

referencia as (
    select cast('{{ var("data_referencia") }}' as date) as data_referencia
),

contratos as (
    select
        cod_escola,
        count(distinct case when ano_letivo = {{ ano_atual }} and status_contrato = 'ativo' then id_marca end)
            as qtd_marcas_ativas,
        sum(case when ano_letivo = {{ ano_atual }} and status_contrato <> 'cancelado' then valor_total_contrato else 0 end)
            as receita_contratada_ano_atual,
        sum(case when ano_letivo = {{ ano_atual - 1 }} then valor_total_contrato else 0 end)
            as receita_contratada_ano_anterior,
        max(case when ano_letivo = {{ ano_atual - 1 }} then 1 else 0 end)
            as teve_contrato_ano_anterior,
        max(case when ano_letivo = {{ ano_atual }} and status_contrato = 'ativo' then 1 else 0 end)
            as tem_contrato_ativo
    from {{ ref('fct_contratos') }}
    group by cod_escola
),

financeiro as (
    select
        p.cod_escola,
        sum(case when p.dt_vencimento < r.data_referencia then p.valor_parcela else 0 end) as valor_ja_vencido,
        sum(case when p.status_parcela = 'vencido' then p.valor_parcela else 0 end)       as valor_em_atraso
    from {{ ref('fct_parcelas') }} as p
    cross join referencia as r
    group by p.cod_escola
),

alunos as (
    select
        cod_escola,
        sum(case when eh_ativo then 1 else 0 end) as qtd_alunos_ativos
    from {{ ref('dim_aluno') }}
    group by cod_escola
),

engajamento_30d as (
    select
        f.cod_escola,
        count(distinct f.id_aluno) as qtd_alunos_engajados_30d,
        sum(f.minutos_totais)      as minutos_30d
    from {{ ref('fct_engajamento_diario') }} as f
    cross join referencia as r
    where f.data_evento >  {{ dbt.dateadd('day', -30, 'r.data_referencia') }}
      and f.data_evento <= r.data_referencia
    group by f.cod_escola
),

indicadores as (
    select
        e.cod_escola,
        e.nome_escola,
        e.cidade,
        e.uf,
        e.regiao,
        e.porte,
        e.dt_inicio_parceria,

        coalesce(c.qtd_marcas_ativas, 0)                 as qtd_marcas_ativas,
        coalesce(c.receita_contratada_ano_atual, 0)      as receita_contratada_ano_atual,
        coalesce(c.receita_contratada_ano_anterior, 0)   as receita_contratada_ano_anterior,
        coalesce(c.tem_contrato_ativo, 0) = 1            as tem_contrato_ativo,
        coalesce(c.teve_contrato_ano_anterior, 0) = 1    as teve_contrato_ano_anterior,

        coalesce(f.valor_ja_vencido, 0)                  as valor_ja_vencido,
        coalesce(f.valor_em_atraso, 0)                   as valor_em_atraso,

        coalesce(a.qtd_alunos_ativos, 0)                 as qtd_alunos_ativos,
        coalesce(g.qtd_alunos_engajados_30d, 0)          as qtd_alunos_engajados_30d,
        coalesce(g.minutos_30d, 0)                       as minutos_30d
    from escolas as e
    left join contratos as c        on c.cod_escola = e.cod_escola
    left join financeiro as f       on f.cod_escola = e.cod_escola
    left join alunos as a           on a.cod_escola = e.cod_escola
    left join engajamento_30d as g  on g.cod_escola = e.cod_escola
),

taxas as (
    select
        *,
        case
            when receita_contratada_ano_anterior > 0
                then (receita_contratada_ano_atual - receita_contratada_ano_anterior) / receita_contratada_ano_anterior
        end as variacao_receita_pct,
        case when valor_ja_vencido > 0 then valor_em_atraso / valor_ja_vencido end
            as pct_inadimplencia,
        case when qtd_alunos_ativos > 0 then cast(qtd_alunos_engajados_30d as double) / qtd_alunos_ativos end
            as pct_alunos_engajados_30d,
        case when qtd_alunos_ativos > 0 then cast(minutos_30d as double) / qtd_alunos_ativos end
            as minutos_por_aluno_30d
    from indicadores
)

select
    cod_escola,
    nome_escola,
    cidade,
    uf,
    regiao,
    porte,
    dt_inicio_parceria,

    case
        when tem_contrato_ativo and teve_contrato_ano_anterior     then 'renovada'
        when tem_contrato_ativo                                    then 'nova'
        when teve_contrato_ano_anterior                            then 'perdida'
        else 'sem_contrato'
    end as situacao_parceria,

    cast(qtd_marcas_ativas as int)                          as qtd_marcas_ativas,
    cast(receita_contratada_ano_atual as decimal(16, 2))    as receita_contratada_ano_atual,
    cast(receita_contratada_ano_anterior as decimal(16, 2)) as receita_contratada_ano_anterior,
    cast(variacao_receita_pct as decimal(9, 4))             as variacao_receita_pct,

    cast(valor_em_atraso as decimal(16, 2))                 as valor_em_atraso,
    cast(pct_inadimplencia as decimal(9, 4))                as pct_inadimplencia,

    cast(qtd_alunos_ativos as int)                          as qtd_alunos_ativos,
    cast(qtd_alunos_engajados_30d as int)                   as qtd_alunos_engajados_30d,
    cast(pct_alunos_engajados_30d as decimal(9, 4))         as pct_alunos_engajados_30d,
    cast(minutos_por_aluno_30d as decimal(10, 1))           as minutos_por_aluno_30d,

    -- Regra de negócio documentada em _marts.yml. Só se aplica a escolas com contrato ativo.
    case
        when not tem_contrato_ativo then null
        when coalesce(pct_inadimplencia, 0) >= 0.20 or coalesce(pct_alunos_engajados_30d, 0) < 0.60 then 'alto'
        when coalesce(pct_inadimplencia, 0) >= 0.08 or coalesce(pct_alunos_engajados_30d, 0) < 0.80 then 'medio'
        else 'baixo'
    end as risco_retencao

from taxas
