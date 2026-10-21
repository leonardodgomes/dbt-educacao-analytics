"""
Gera os dados sintéticos usados como camada "raw" do projeto.

Simula uma empresa de soluções educacionais que vende sistemas de ensino,
plataformas digitais e serviços para escolas particulares. Os dados são
fictícios, reprodutíveis (semente fixa) e trazem alguns problemas típicos de
fontes reais para a camada de staging tratar:

- status com caixa e espaços inconsistentes ("Ativo", " ATIVO ")
- UF em minúsculas em parte das escolas
- valores monetários em formato brasileiro ("1.234,56") salvos como texto
- eventos duplicados na carga da plataforma (mesmo id_evento, cargas diferentes)

Uso:
    python scripts/gerar_dados.py
"""

import csv
import random
from datetime import date, datetime, timedelta
from pathlib import Path

SEMENTE = 42
DATA_REFERENCIA = date(2026, 10, 20)
INICIO_EVENTOS = date(2026, 8, 1)
QTD_ESCOLAS = 300

SAIDA = Path(__file__).resolve().parents[1] / "seeds" / "raw"
rnd = random.Random(SEMENTE)

MARCAS = [
    ("M01", "Sistema Aurora", "sistema_ensino", (900, 1600)),
    ("M02", "Rede Horizonte", "sistema_ensino", (850, 1450)),
    ("M03", "Trilha Digital", "plataforma_digital", (150, 300)),
    ("M04", "Ponte Bilíngue", "bilingue", (1200, 2000)),
    ("M05", "Nexo Gestão Escolar", "gestao", (40, 80)),
]

CIDADES = {
    "SP": ["São Paulo", "Campinas", "Santo André", "Ribeirão Preto", "Sorocaba"],
    "RJ": ["Rio de Janeiro", "Niterói", "Petrópolis"],
    "MG": ["Belo Horizonte", "Uberlândia", "Juiz de Fora"],
    "PR": ["Curitiba", "Londrina", "Maringá"],
    "RS": ["Porto Alegre", "Caxias do Sul"],
    "SC": ["Florianópolis", "Joinville"],
    "BA": ["Salvador", "Feira de Santana"],
    "PE": ["Recife", "Caruaru"],
    "CE": ["Fortaleza", "Sobral"],
    "GO": ["Goiânia", "Anápolis"],
    "DF": ["Brasília"],
    "PA": ["Belém"],
    "AM": ["Manaus"],
}
PESO_UF = {"SP": 30, "RJ": 10, "MG": 12, "PR": 8, "RS": 6, "SC": 5, "BA": 7,
           "PE": 5, "CE": 6, "GO": 4, "DF": 3, "PA": 2, "AM": 2}

PREFIXOS = ["Colégio", "Escola", "Instituto", "Centro Educacional"]
NOMES = ["São José", "Santa Maria", "Monteiro Lobato", "Cecília Meireles",
         "Paulo Freire", "Anísio Teixeira", "Machado de Assis", "Dom Bosco",
         "Vila Nova", "Primavera", "Novo Saber", "Caminho do Saber", "Arco-Íris",
         "Pequeno Príncipe", "Santa Clara", "São Francisco", "Bom Jesus",
         "Nossa Senhora", "Educar", "Aprender Mais", "Sol Nascente", "Integração"]

SERIES = [
    ("Infantil 4", "EI"), ("Infantil 5", "EI"),
    ("1º ano EF", "EF1"), ("2º ano EF", "EF1"), ("3º ano EF", "EF1"),
    ("4º ano EF", "EF1"), ("5º ano EF", "EF1"),
    ("6º ano EF", "EF2"), ("7º ano EF", "EF2"), ("8º ano EF", "EF2"),
    ("9º ano EF", "EF2"),
    ("1ª série EM", "EM"), ("2ª série EM", "EM"), ("3ª série EM", "EM"),
]

TIPOS_EVENTO = [
    ("login", 35, (0, 2)),
    ("aula_assistida", 30, (10, 50)),
    ("exercicio_resolvido", 28, (3, 20)),
    ("avaliacao_concluida", 7, (20, 60)),
]


def br_moeda(valor: float) -> str:
    """Formata 1234.5 como '1.234,50' (formato que chega da fonte)."""
    inteiro, dec = f"{valor:,.2f}".split(".")
    return f"{inteiro.replace(',', '.')},{dec}"


def baguncar_status(status: str) -> str:
    return rnd.choice([status, status.upper(), status.capitalize(), f" {status.upper()} "])


def data_aleatoria(inicio: date, fim: date) -> date:
    return inicio + timedelta(days=rnd.randint(0, (fim - inicio).days))


def escrever(nome: str, cabecalho: list[str], linhas: list[list]) -> None:
    SAIDA.mkdir(parents=True, exist_ok=True)
    with open(SAIDA / f"{nome}.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(cabecalho)
        w.writerows(linhas)
    print(f"{nome}: {len(linhas)} linhas")


def main() -> None:
    # Marcas
    escrever("raw_marcas", ["id_marca", "nome_marca", "segmento"],
             [[m[0], m[1], m[2]] for m in MARCAS])

    # Escolas: cada escola tem uma "saúde" latente que guia renovação,
    # pagamento e engajamento, para os indicadores terem padrão realista.
    escolas = []
    for i in range(1, QTD_ESCOLAS + 1):
        uf = rnd.choices(list(PESO_UF), weights=list(PESO_UF.values()))[0]
        qtd = int(rnd.lognormvariate(6.2, 0.55))
        qtd = max(80, min(qtd, 2500))
        porte = "P" if qtd < 300 else ("M" if qtd < 900 else "G")
        escolas.append({
            "cod_escola": f"ESC{i:04d}",
            "nome_escola": f"{rnd.choice(PREFIXOS)} {rnd.choice(NOMES)}",
            "cidade": rnd.choice(CIDADES[uf]),
            "uf": uf.lower() if rnd.random() < 0.15 else uf,
            "porte": porte,
            "qtd_alunos_estimada": qtd,
            "dt_inicio_parceria": data_aleatoria(date(2015, 1, 1), date(2024, 12, 31)),
            "saude": rnd.random(),
        })

    # Contratos: um por escola, marca e ano letivo
    contratos, id_contrato = [], 0
    marcas_por_escola = {}
    for e in escolas:
        m25 = [rnd.choice(["M01", "M02"])] if rnd.random() < 0.92 else []
        for m, p in [("M03", 0.5), ("M04", 0.2), ("M05", 0.3)]:
            if rnd.random() < p:
                m25.append(m)
        if not m25:
            m25 = ["M03"]
        m26 = [m for m in m25 if rnd.random() < 0.70 + 0.27 * e["saude"]]
        for m in ["M03", "M04", "M05"]:
            if m not in m26 and rnd.random() < 0.12 * e["saude"]:
                m26.append(m)
        marcas_por_escola[e["cod_escola"]] = {2025: m25, 2026: m26}

        for ano, lista in [(2025, m25), (2026, m26)]:
            for m in lista:
                id_contrato += 1
                marca = next(x for x in MARCAS if x[0] == m)
                fracao = rnd.uniform(0.85, 1.0) if marca[2] in ("sistema_ensino", "gestao") else rnd.uniform(0.3, 0.8)
                if ano == 2025:
                    status = "encerrado"
                elif rnd.random() < 0.05 * (1 - e["saude"]) + 0.01:
                    status = "cancelado"
                else:
                    status = "ativo"
                contratos.append({
                    "id_contrato": f"CTR{id_contrato:05d}",
                    "cod_escola": e["cod_escola"],
                    "id_marca": m,
                    "ano_letivo": ano,
                    "qtd_alunos_contratados": max(10, int(e["qtd_alunos_estimada"] * fracao)),
                    "valor_por_aluno": round(rnd.uniform(*marca[3]), 2),
                    "dt_assinatura": data_aleatoria(date(ano - 1, 10, 1), date(ano - 1, 12, 20)),
                    "status": status,
                    "saude": e["saude"],
                })

    escrever("raw_contratos",
             ["id_contrato", "cod_escola", "id_marca", "ano_letivo", "qtd_alunos_contratados",
              "valor_por_aluno", "dt_assinatura", "status_contrato"],
             [[c["id_contrato"], c["cod_escola"], c["id_marca"], c["ano_letivo"],
               c["qtd_alunos_contratados"], br_moeda(c["valor_por_aluno"]),
               c["dt_assinatura"].isoformat(), baguncar_status(c["status"])] for c in contratos])

    # Parcelas: 12 por contrato (vencimento dia 10); contratos cancelados param no mês do cancelamento
    parcelas, id_parcela = [], 0
    for c in contratos:
        total = round(c["qtd_alunos_contratados"] * c["valor_por_aluno"], 2)
        base = round(total / 12, 2)
        valores = [base] * 11 + [round(total - base * 11, 2)]
        qtd = rnd.randint(3, 8) if c["status"] == "cancelado" else 12
        for n in range(1, qtd + 1):
            id_parcela += 1
            venc = date(c["ano_letivo"], n, 10)
            pagamento = None
            if venc <= DATA_REFERENCIA:
                r = rnd.random()
                if r < 0.60 + 0.35 * c["saude"]:
                    pagamento = venc - timedelta(days=rnd.randint(0, 5))
                elif r < 1 - 0.15 * (1 - c["saude"]):
                    pagamento = venc + timedelta(days=rnd.randint(1, 60))
                    if pagamento > DATA_REFERENCIA:
                        pagamento = None
            parcelas.append([f"PAR{id_parcela:06d}", c["id_contrato"], n, venc.isoformat(),
                             pagamento.isoformat() if pagamento else "", f"{valores[n - 1]:.2f}"])
    escrever("raw_pagamentos",
             ["id_parcela", "id_contrato", "num_parcela", "dt_vencimento", "dt_pagamento", "valor_parcela"],
             parcelas)

    # Escolas (depois dos contratos, para refletir o status atual)
    linhas_escolas = []
    for e in escolas:
        ativa = bool(marcas_por_escola[e["cod_escola"]][2026])
        linhas_escolas.append([e["cod_escola"], e["nome_escola"], e["cidade"], e["uf"], e["porte"],
                               e["qtd_alunos_estimada"], e["dt_inicio_parceria"].isoformat(),
                               baguncar_status("ativa" if ativa else "inativa")])
    escrever("raw_escolas",
             ["cod_escola", "nome_escola", "cidade", "uf", "porte", "qtd_alunos_estimada",
              "dt_inicio_parceria", "status"], linhas_escolas)

    # Alunos: amostra dos alunos usuários da plataforma em cada escola
    alunos, id_aluno = [], 0
    for e in escolas:
        for _ in range(max(5, e["qtd_alunos_estimada"] // 25)):
            id_aluno += 1
            serie, segmento = rnd.choice(SERIES)
            ativa = bool(marcas_por_escola[e["cod_escola"]][2026])
            ativo = ativa and rnd.random() < 0.94
            alunos.append({
                "id_aluno": f"ALU{id_aluno:06d}",
                "cod_escola": e["cod_escola"],
                "serie": serie,
                "segmento": segmento,
                "dt_matricula": data_aleatoria(date(2022, 1, 15), date(2026, 3, 1)),
                "ativo": ativo,
                "engaj": e["saude"] * rnd.betavariate(2, 2),
            })
    escrever("raw_alunos", ["id_aluno", "cod_escola", "serie", "segmento_ensino", "dt_matricula", "ativo"],
             [[a["id_aluno"], a["cod_escola"], a["serie"], a["segmento"],
               a["dt_matricula"].isoformat(), "S" if a["ativo"] else "N"] for a in alunos])

    # Eventos da plataforma (ago-out/2026), com ~1% de duplicidade de carga
    eventos, id_evento = [], 0
    dias = (DATA_REFERENCIA - INICIO_EVENTOS).days + 1
    tipos, pesos = [t[0] for t in TIPOS_EVENTO], [t[1] for t in TIPOS_EVENTO]
    for a in alunos:
        if not a["ativo"]:
            continue
        for _ in range(int(a["engaj"] * 22)):
            id_evento += 1
            dia = INICIO_EVENTOS + timedelta(days=rnd.randrange(dias))
            ts = datetime(dia.year, dia.month, dia.day, rnd.randint(7, 22), rnd.randint(0, 59), rnd.randint(0, 59))
            tipo = rnd.choices(tipos, weights=pesos)[0]
            faixa = next(t[2] for t in TIPOS_EVENTO if t[0] == tipo)
            carga = datetime(dia.year, dia.month, dia.day, 23, 30) + timedelta(hours=2)
            linha = [f"EVT{id_evento:07d}", a["id_aluno"], ts.isoformat(sep=" "), tipo,
                     rnd.randint(*faixa), carga.isoformat(sep=" ")]
            eventos.append(linha)
            if rnd.random() < 0.01:
                eventos.append(linha[:-1] + [(carga + timedelta(hours=24)).isoformat(sep=" ")])
    escrever("raw_eventos_plataforma",
             ["id_evento", "id_aluno", "ts_evento", "tipo_evento", "duracao_min", "carregado_em"], eventos)


if __name__ == "__main__":
    main()
