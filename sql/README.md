# Banco de Dados - Fretado

## 📁 Estrutura

A pasta `sql/` está organizada da seguinte forma:

- **`schema/`**: arquivos responsáveis pela criação da estrutura completa do banco de dados
- **`seeds/`**: dados iniciais necessários para o funcionamento do sistema
- **`migrations/`**: alterações incrementais utilizadas para evoluir bancos de dados já existentes

---

## 🗂️ Schema

Os arquivos da pasta `schema/` representam a estrutura atual do banco de dados e devem ser executados **em ordem numérica**, garantindo que as dependências entre as tabelas sejam respeitadas.

Exemplo:

1. `001_users.sql`
2. `002_fuel_and_vehicles.sql`
3. `003_documents.sql`
4. `004_rides.sql`
5. `005_offers.sql`
6. `006_payments.sql`
7. `007_transactions.sql`
8. `008_cards.sql`
9. `009_driver_locations.sql`

---

## 🌱 Seeds

Após a criação do schema, devem ser executados os arquivos da pasta `seeds/`, também respeitando a ordem numérica.

Os seeds são responsáveis por cadastrar dados iniciais necessários para o funcionamento da aplicação, como:

- Tipos de usuário
- Tipos de combustível
- Tipos de veículo
- Categorias de CNH
- Status de corridas
- Status de ofertas
- Status de transações

---

## 🔄 Migrations

A pasta `migrations/` deve ser utilizada para alterações futuras em bancos de dados já existentes.

Exemplos:

- Adição ou remoção de colunas
- Criação de novas tabelas
- Alteração de constraints
- Criação de novos índices
- Ajustes estruturais necessários entre versões

As migrations não substituem os arquivos da pasta `schema/`. O `schema/` deve sempre representar a estrutura completa e atualizada do banco para uma instalação do zero.

---

## ▶️ Inicialização do Banco

Para criar um novo banco de dados do Fretado:

1. Execute todos os arquivos de `schema/` em ordem numérica.
2. Execute todos os arquivos de `seeds/` em ordem numérica.

Exemplo:

```text
sql/schema/001_users.sql
sql/schema/002_fuel_and_vehicles.sql
...
sql/schema/009_driver_locations.sql

sql/seeds/001_user_types.sql
sql/seeds/002_fuel_types.sql
...# Banco de Dados - Fretado

## 📁 Estrutura

A pasta `sql/` está organizada da seguinte forma:

- **`schema/`**: arquivos responsáveis pela criação da estrutura completa do banco de dados
- **`seeds/`**: dados iniciais necessários para o funcionamento do sistema
- **`migrations/`**: alterações incrementais utilizadas para evoluir bancos de dados já existentes

---

## 🗂️ Schema

Os arquivos da pasta `schema/` representam a estrutura atual do banco de dados e devem ser executados **em ordem numérica**, garantindo que as dependências entre as tabelas sejam respeitadas.

Exemplo:

1. `001_users.sql`
2. `002_fuel_and_vehicles.sql`
3. `003_documents.sql`
4. `004_rides.sql`
5. `005_offers.sql`
6. `006_payments.sql`
7. `007_transactions.sql`
8. `008_cards.sql`
9. `009_driver_locations.sql`

---

## 🌱 Seeds

Após a criação do schema, devem ser executados os arquivos da pasta `seeds/`, também respeitando a ordem numérica.

Os seeds são responsáveis por cadastrar dados iniciais necessários para o funcionamento da aplicação, como:

- Tipos de usuário
- Tipos de combustível
- Tipos de veículo
- Categorias de CNH
- Status de corridas
- Status de ofertas
- Status de transações

---

## 🔄 Migrations

A pasta `migrations/` deve ser utilizada para alterações futuras em bancos de dados já existentes.

Exemplos:

- Adição ou remoção de colunas
- Criação de novas tabelas
- Alteração de constraints
- Criação de novos índices
- Ajustes estruturais necessários entre versões

As migrations não substituem os arquivos da pasta `schema/`. O `schema/` deve sempre representar a estrutura completa e atualizada do banco para uma instalação do zero.

---

## ▶️ Inicialização do Banco

Para criar um novo banco de dados do Fretado:

1. Execute todos os arquivos de `schema/` em ordem numérica.
2. Execute todos os arquivos de `seeds/` em ordem numérica.

Exemplo:

```text
sql/schema/001_users.sql
sql/schema/002_fuel_and_vehicles.sql
...
sql/schema/009_driver_locations.sql

sql/seeds/001_user_types.sql
sql/seeds/002_fuel_types.sql
...