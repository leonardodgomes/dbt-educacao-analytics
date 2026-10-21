{#
    Converte um texto monetário no formato brasileiro ("1.234,56") para decimal.
    Equivalente a uma macro SAS usada em vários fluxos: a regra fica em um só lugar.
#}
{% macro converter_moeda_br(coluna, precisao=14, escala=2) %}
    cast(
        replace(replace(trim({{ coluna }}), '.', ''), ',', '.')
        as decimal({{ precisao }}, {{ escala }})
    )
{% endmacro %}
