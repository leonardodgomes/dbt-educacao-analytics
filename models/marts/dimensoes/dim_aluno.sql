select
    id_aluno,
    cod_escola,
    serie,
    segmento_ensino,
    dt_matricula,
    eh_ativo
from {{ ref('stg_alunos') }}
