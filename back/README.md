# ⚙️ Back-end

O back-end será desenvolvido em **Python** utilizando o framework **FastAPI**, focado em alta performance e construção de APIs modernas.

## 🚀 Como rodar o projeto

**Pré-requisitos:**

* Python instalado (versão recomendada: 3.13.3)

**Passos:**

```bash
cd back

# Criar ambiente virtual
python -m venv venv

# Ativar ambiente virtual
# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate

# Instalar dependências
pip install -r requirements.txt

# Rodar o servidor
uvicorn app.main:app --reload
```

Após rodar, acesse:

* API: [http://127.0.0.1:8000](http://127.0.0.1:8000)
* Documentação automática: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)

---

### 🔐 Variáveis de Ambiente

Para o funcionamento correto do back-end, é necessário criar um arquivo `.env` dentro da pasta `back/`, seguindo o modelo do arquivo `.env.example`.

---

## Serviços externos

### ⛽ Atualização de preços de combustíveis — ANP

O Fretado utiliza dados oficiais da **Agência Nacional do Petróleo, Gás Natural e Biocombustíveis (ANP)** como referência para o cálculo do custo de combustível das corridas.

Os dados são obtidos a partir dos arquivos públicos disponibilizados pela ANP com os preços coletados nos postos de combustíveis brasileiros.

### Como funciona

O serviço `AnpFuelPriceService` realiza o seguinte processo:

1. Baixa os arquivos mais recentes disponibilizados pela ANP;
2. Processa os registros de **gasolina, etanol e diesel**;
3. Identifica a semana mais recente disponível;
4. Agrupa os preços por **UF e tipo de combustível**;
5. Calcula o preço médio de venda por litro;
6. Armazena os resultados na tabela `fuel_prices`.

A tabela mantém o histórico semanal, permitindo que o cálculo de frete utilize os preços mais recentes disponíveis sem precisar consultar a ANP durante cada solicitação de corrida.

### Execução manual

A atualização pode ser executada manualmente a partir da pasta `back`:

```bash
python -m scripts.update_fuel_prices
```

O script pode ser executado novamente com segurança. Caso os dados referentes à mesma semana já existam, os registros são atualizados em vez de duplicados.

### Atualização automática

Em produção, o script é executado periodicamente através de um **Cron Job no Render**.

A atualização é realizada semanalmente, acompanhando a periodicidade de publicação dos levantamentos da ANP.

```text
ANP
 ↓
Render Cron Job
 ↓
scripts/update_fuel_prices.py
 ↓
AnpFuelPriceService
 ↓
fuel_prices
 ↓
Cálculo do frete
```

Dessa forma, a consulta à fonte externa fica desacoplada do fluxo de cotação, reduzindo o tempo de resposta e mantendo o sistema disponível mesmo quando a fonte da ANP estiver temporariamente indisponível.

### Fonte dos dados

Dados abertos da Agência Nacional do Petróleo, Gás Natural e Biocombustíveis (ANP):

https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/serie-historica-de-precos-de-combustiveis

### Novo fluxo de cotacao

A cotacao e a criacao usam `RideQuoteService` com a sessao do banco. A UF de origem
pode ser enviada em `origin_state`; se ausente, e resolvida pelo Mapbox. Os precos
sao lidos exclusivamente de `fuel_prices`. O importador ANP continua separado,
executado pelo comando `python -m scripts.update_fuel_prices` no cron semanal.

Antes de publicar, aplicar a migration `025_snapshot_ride_app_fee.sql` e garantir
que `pricing_policies` esteja criada e configurada (migration 024). Corridas antigas
sem earning ficam sem taxa conhecida e precisam de conciliacao antes da liquidacao;
a migration recupera apenas taxas ja registradas em `driver_earnings`.

O preco enviado pelo cliente na criacao e ignorado. A resposta `pricing` agora
contem combustivel, custo operacional, margem, taxa e `driver_net_value`; nao ha
mais valores de base, distancia ou tempo. O frontend deve usar essa composicao.
O valor liquido inclui eventual complemento decorrente do preco minimo.

A criacao de earnings recebe apenas `ride_id` e usa os valores persistidos da
corrida finalizada. Carteiras iniciam com saldo zero; a atualizacao direta de saldo
via PUT foi removida. Creditos e saques alteram o saldo dentro da mesma transacao.
