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

### Fotos de perfil — Supabase Storage

1. No banco existente, aplique `sql/migrations/034_add_user_profile_avatar.sql`
   antes de atualizar a API. Instalações novas já incluem a coluna no schema.
2. Mantenha o bucket **público** `avatars`, com limite de **5 MiB** e MIME types
   `image/jpeg`, `image/png` e `image/webp`.
3. Configure no ambiente **do backend**:

```dotenv
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_SERVICE_ROLE_KEY=sua_service_role_key
SUPABASE_AVATARS_BUCKET=avatars
```

Use a URL base do projeto em `SUPABASE_URL`, sem acrescentar `/rest/v1`,
`/storage/v1` ou o nome do bucket. Reinicie a API após alterar o `.env`.

A service role é uma credencial de servidor e não deve ir para Flutter,
`--dart-define`, Git ou logs. O JWT do Fretado continua autenticando a API;
o frontend não precisa de Supabase Auth nem de chave do Storage. Escritas
usam a service role; não é necessário liberar upload anônimo nas policies.
Como o bucket é público, quem tem a URL pode visualizar a foto.

- `PUT /users/{user_id}/avatar`: Bearer token do dono do perfil,
  `multipart/form-data` com campo `file`. JPEG, PNG ou WebP válidos até
  5 MiB; retorna o perfil com `avatar_url`.
- `DELETE /users/{user_id}/avatar`: mesmo token; retorna o perfil com
  `avatar_url: null`, inclusive quando não havia foto.
- `GET /users/{user_id}` e `PATCH /users/{user_id}` incluem `avatar_url`
  opcional. A foto é alterada exclusivamente pelos endpoints de avatar.
- As respostas de corrida incluem `client.avatar_url` e `driver.avatar_url`;
  as conversas incluem `other_participant.avatar_url`. Esses campos opcionais
  permitem exibir as fotos em cartões, acompanhamento, detalhes e chat.

A tela inicial reutiliza o perfil carregado no login/abertura da home para
mostrar a foto no cabeçalho e na aba Perfil. Alterar ou remover a foto atualiza
essas visualizações imediatamente; mudar de conta limpa a foto em memória.

A documentação `/docs` descreve os erros. Sem as variáveis do Storage, a API
inicializa normalmente, mas envio/remoção retornam 503. Cada troca gera uma
URL nova. A foto antiga é excluída após a confirmação no banco; falhas de
limpeza são registradas como `Avatar cleanup failed` e podem exigir remoção
manual dos objetos órfãos, sem desfazer a atualização do perfil.

Publique na ordem: migration → configuração e backend → frontend.
No app, toque na foto em Perfil ou Dados pessoais, escolha galeria/câmera,
confira a prévia e confirme. Na web, use o seletor de imagens. Formatos
como HEIC devem ser convertidos para JPEG, PNG ou WebP antes da seleção.

Verificação local, sem credenciais ou acesso ao Supabase:

```bash
cd back
python -m unittest tests.test_profile_avatar
```

Os testes executam as rotas reais, SQLite e um servidor HTTP local que
simula upload/remoção do Storage. Câmera, permissões e recuperação de seleção
interrompida precisam ser conferidas em dispositivo Android/iOS. Antes da
publicação, confirme upload, troca, remoção e nova consulta com uma conta
de cliente e uma de motorista no bucket real configurado.

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
