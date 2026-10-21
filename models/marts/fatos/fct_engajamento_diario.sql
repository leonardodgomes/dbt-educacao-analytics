-- Grão: um aluno em um dia com uso da plataforma.
-- Incremental: em cada execução reprocessa só os últimos dias, para pegar eventos
-- que chegam atrasados, e faz MERGE pela chave aluno × dia.

{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='sk_engajamento',
        on_schema_change='append_new_columns'
    )
}}

with eventos as (
    select *
    from {{ ref('stg_eventos_plataforma') }}
    {% if is_incremental() %}
    where data_evento >= (
        select {{ dbt.dateadd('day', -var('dias_reprocessamento_incremental'), 'max(data_evento)') }}
        from {{ this }}
    )
    {% endif %}
),

alunos as (
    select id_aluno, cod_escola
    from {{ ref('stg_alunos') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['e.id_aluno', 'e.data_evento']) }} as sk_engajamento,
    e.id_aluno,
    a.cod_escola,
    e.data_evento,
    cast(count(*) as int)                                                         as qtd_eventos,
    cast(sum(case when e.tipo_evento = 'login' then 1 else 0 end) as int)               as qtd_logins,
    cast(sum(case when e.tipo_evento = 'aula_assistida' then 1 else 0 end) as int)      as qtd_aulas_assistidas,
    cast(sum(case when e.tipo_evento = 'exercicio_resolvido' then 1 else 0 end) as int) as qtd_exercicios,
    cast(sum(case when e.tipo_evento = 'avaliacao_concluida' then 1 else 0 end) as int) as qtd_avaliacoes,
    cast(sum(e.duracao_min) as int)                                               as minutos_totais,
    {{ dbt.current_timestamp() }}                                                 as processado_em
from eventos as e
inner join alunos as a
    on a.id_aluno = e.id_aluno
group by e.id_aluno, a.cod_escola, e.data_evento
