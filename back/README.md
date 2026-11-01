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

### Carpédia — catálogo v2

O cadastro mantém a seleção de tipo, marca, modelo, versão e ano, seguida
de cor e placa. A integração usa o catálogo da
[API v2 da Carpédia](https://www.carpedia.com.br/desenvolvedores/v2).
As listas exigem acesso PJ ao catálogo na conta vinculada à chave; ter saldo
grátis ou pago, por si só, não concede essa permissão. Isso não significa
necessariamente contratar um plano Enterprise.

Configure somente no backend e reinicie a API:

```dotenv
CARPEDIA_BASE_URL=https://www.carpedia.com.br/api/v2
CARPEDIA_API_KEY=sua_chave_cpk
CARPEDIA_TIMEOUT_SECONDS=10
CARPEDIA_CACHE_TTL_SECONDS=3600
```

Para liberar o acesso, confira no portal da Carpédia a aprovação PJ e a
habilitação do catálogo na conta da chave configurada. `GET /api/v2/produtos`
é uma leitura sem cobrança: `catalogo: null` significa que a chave ainda não
tem esse acesso. Quando habilitado, o catálogo informa as tarifas em
`precosPorEntidadeMilesimos`. Se o painel mostrar a liberação e a API continuar
retornando `catalogo: null`, confirme a conta/chave com o suporte da Carpédia.
Não é necessário comprar mais créditos para corrigir uma falta de permissão.
A habilitação é realizada no provedor, não por uma alteração no código do app.

O backend verifica a autorização em `/produtos`, com cache de 15 segundos.
Não consulta `/conta/consumo` para impedir operações com base apenas em
`saldo_milesimos`: esse campo legado não é usado como prova de ausência de
saldo grátis. A Carpédia decide o saldo aplicável à operação e informa HTTP 402
quando ele for insuficiente.

Rotas autenticadas com Bearer token de motorista:

- `GET /vehicle-catalog/brands/page?page=1`
- `GET /vehicle-catalog/models/page?brand_id=...&page=1`
- `GET /vehicle-catalog/versions/page?brand_id=...&model_id=...&page=1`

As respostas contêm `items`, `page`, `total_pages`, `total_items` e `has_more`.
Os seletores de marca, modelo e versão apresentam uma lista contínua com busca
digitável. Ao rolar perto do fim, o app acrescenta a próxima página dentro do
próprio seletor, sem botão para carregar opções e sem perder o texto da busca.
A busca ignora maiúsculas e acentos e filtra as opções já carregadas; se não
houver correspondências e ainda existirem páginas, a lista orienta continuar
rolando. Não há carregamento de todo o catálogo ao abrir a tela nem chamada por
tecla digitada. O app preserva os itens se uma página
seguinte falhar e permite repetir somente a página que falhou. Trocar marca
ou modelo limpa os campos dependentes e ignora respostas antigas.
As rotas antigas sem `/page` mantêm respostas em lista e aceitam `page`;
o padrão é a primeira página. `search` filtra os nomes da página atual.

As consultas usam `POST /catalogo/pesquisar`, com `entidade`, `filtros` e
paginação de até 24 itens. A ficha usa `entidade=detalhes`, `fipeId` e ano,
sem paginação. `POST /vehicles` recebe `user_id` do próprio motorista,
`vehicle_type_id`, `version_id`, `year`, `plate`, `color` opcional e `status`.
O ID de versão é o inteiro não zero retornado pelo catálogo, diferente do
código FIPE textual. Modelos existentes são reutilizados; o mapeamento de
combustível, consumo e estimativas da categoria permanece.
O fluxo por placa e os tokens de consulta foram removidos. Não há migration.

Cada operação envia UUID em `Idempotency-Key`. O cache guarda até 512
operações por processo e separa contas/ambientes. Não há varredura automática
de páginas nem repetição automática de POST. Após timeout ou resultado
ambíguo, o UUID é preservado durante a validade da entrada. Expirar/remover
entradas ou reiniciar workers perde essa proteção; não há deduplicação
persistente entre workers. Uma nova consulta fora do cache pode consumir saldo.

Falhas retornam `detail.code` e `detail.message` em português:

- `vehicle_catalog_access_denied`: catálogo não habilitado para a conta.
- `vehicle_catalog_credentials_invalid`: chave recusada pela Carpédia.
- `vehicle_catalog_insufficient_balance`: saldo insuficiente informado pelo provedor.
- `vehicle_catalog_unavailable` / `vehicle_catalog_timeout`: conexão ou demora.
- `vehicle_catalog_upstream_error` / `vehicle_catalog_invalid_response`: falha ou resposta inesperada do provedor.

Esses erros do provedor não encerram a sessão do motorista. Logs registram
operação, status HTTP e código seguro, sem chave ou corpo da resposta.
O OpenAPI em `/docs` detalha os campos e exemplos dos erros.

Após liberar o catálogo e reiniciar a API, confira manualmente marca → modelo →
versão → ano → cor/placa → cadastro, incluindo a próxima página e uma nova
consulta dos veículos cadastrados. A conferência com o catálogo real depende
da autorização da conta e pode consumir créditos. Não foram executados testes
automatizados; a verificação local usa sintaxe Python e análise estática Flutter.

### Disponibilidade do motorista

O motorista só pode ficar online com CNH preenchida, não vencida, e pelo
menos um veículo com `status=true`. O vencimento considera o dia em
`America/Sao_Paulo`, incluindo a própria data de validade. Instale as
dependências atualizadas em `requirements.txt`, que inclui `tzdata`.

- `GET /driver-locations/me/eligibility` retorna `can_go_online`,
  `pending_requirements`, `has_active_ride` e `message`, autenticando o motorista
  pelo Bearer token. Funciona antes do primeiro registro de localização.
- As respostas de localização incluem esses mesmos campos. Ao detectar uma
  pendência, a API retira a disponibilidade e redistribui ofertas pendentes.
- `POST /driver-locations/me/online` retorna 409 com
  `detail.code=driver_setup_incomplete` e os campos acima quando houver pendência.
  Os códigos são `missing_driver_license`, `expired_driver_license` e
  `missing_active_vehicle`.
- Regularizar o cadastro libera a ativação manual; não coloca o motorista
  online automaticamente.

Corridas já aceitas, incluindo transferências aguardando recebimento da carga,
continuam permitindo localização, acompanhamento e conclusão enquanto o
motorista está offline. `has_active_ride` mantém o envio periódico de GPS
independentemente da disponibilidade para novas ofertas. A home compartilha
a verificação entre o aviso e o botão e atualiza ao retornar do cadastro,
retomar o aplicativo, voltar à aba Início ou atualizar a lista.

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
