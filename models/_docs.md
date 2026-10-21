{% docs __overview__ %}
# Educação Analytics

Projeto de Analytics Engineering sobre uma empresa fictícia de soluções educacionais
que vende sistemas de ensino, plataformas digitais e serviços para escolas particulares.

**Camadas**

- **staging**: uma view por fonte. Limpa, tipa e padroniza, sem regra de negócio.
- **intermediate**: regras de negócio reaproveitáveis (status de parcelas, renovação).
- **marts**: modelo dimensional em Star Schema (fatos e dimensões) e a tabela
  `escola_360`, orientada à entidade escola.

Os dados são sintéticos e gerados por `scripts/gerar_dados.py`.
{% enddocs %}

{% docs escola_360 %}
Grão: uma escola. Tabela larga orientada à entidade (entity-based) que reúne,
na data de referência, os indicadores de contrato, financeiro, alunos e engajamento.

Pensada para três usos: painel de saúde da carteira, análises de retenção e
consultas em linguagem natural, em que uma tabela por entidade com colunas bem
descritas reduz erros de join.

O contrato do model está ativo (`contract.enforced`): nomes e tipos das colunas
são garantidos para quem consome.
{% enddocs %}

{% docs risco_retencao %}
Classificação de risco de não renovação, só para escolas com contrato ativo:

| Risco | Regra |
| --- | --- |
| alto | inadimplência ≥ 20% **ou** menos de 60% dos alunos ativos usaram a plataforma nos últimos 30 dias |
| medio | inadimplência ≥ 8% **ou** engajamento abaixo de 80% |
| baixo | demais casos |

Os limites são hipóteses de negócio e devem ser revisados com a área comercial.
{% enddocs %}
