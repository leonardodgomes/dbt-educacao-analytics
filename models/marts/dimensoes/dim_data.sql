with datas as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2025-01-01' as date)",
        end_date="cast('2027-01-01' as date)"
    ) }}
)

select
    cast(date_day as date)                                     as data,
    cast({{ dbt.date_part('year', 'date_day') }} as int)       as ano,
    cast({{ dbt.date_part('quarter', 'date_day') }} as int)    as trimestre,
    cast({{ dbt.date_part('month', 'date_day') }} as int)      as mes,
    cast({{ dbt.date_trunc('month', 'date_day') }} as date)    as inicio_mes,
    -- 1 = domingo ... 7 = sábado (padrão do Databricks)
    cast({{ dbt.date_part('dayofweek', 'date_day') }} as int)  as dia_semana,
    {{ dbt.date_part('dayofweek', 'date_day') }} in (1, 7)     as eh_fim_de_semana
from datas
