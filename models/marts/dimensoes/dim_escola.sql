-- Versão atual de cada escola, a partir do snapshot (SCD tipo 2).
-- O histórico completo continua disponível em snap_escolas.

with escolas_atuais as (
    select *
    from {{ ref('snap_escolas') }}
    where dbt_valid_to is null
),

regioes as (
    select * from {{ ref('uf_regiao') }}
)

select
    e.cod_escola,
    e.nome_escola,
    e.cidade,
    e.uf,
    r.nome_uf,
    r.regiao,
    e.porte,
    e.qtd_alunos_estimada,
    e.dt_inicio_parceria,
    e.status_escola,
    cast(e.dbt_valid_from as timestamp) as versao_desde
from escolas_atuais as e
left join regioes as r
    on r.uf = e.uf
