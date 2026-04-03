# Fretado

O **Fretado** é um aplicativo mobile desenvolvido com o objetivo de conectar usuários que precisam transportar cargas a motoristas disponíveis para realizar esse serviço de forma **ágil, prática e segura**.

A plataforma busca otimizar todo o processo de contratação de fretes, permitindo que o usuário solicite um transporte diretamente pelo aplicativo, enquanto motoristas cadastrados podem visualizar e aceitar solicitações compatíveis com sua disponibilidade.

---

## 🧱 Estrutura do Projeto

O projeto está dividido em três partes principais:

````bash
fretado/
├── front/  # Aplicação Flutter
├── back/   # API em Python (FastAPI)
└── sql/    # Scripts e modelagem do banco de dados (Supabase/PostgreSQL)

---

## 📱 Front-end

O front-end do projeto será desenvolvido utilizando **Flutter**, permitindo a criação de uma aplicação multiplataforma (mobile/web).

### 🚀 Como rodar o projeto

**Pré-requisitos:**

* Flutter instalado (versão recomendada: 3.35.2)

**Passos:**

```bash
cd front
flutter pub get
flutter run -d chrome
```

---

## ⚙️ Back-end

O back-end será desenvolvido em **Python** utilizando o framework **FastAPI**, focado em alta performance e construção de APIs modernas.

### 🚀 Como rodar o projeto

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

## 🔐 Variáveis de Ambiente

Para o funcionamento correto do back-end, é necessário criar um arquivo `.env` dentro da pasta `back/`, seguindo o modelo do arquivo `.env.example`.

Exemplo:

```env
APP_NAME=Fretado API
APP_ENV=development
SECRET_KEY=sua_chave_secreta_aqui
DATABASE_URL=postgresql://usuario:senha@localhost:5432/fretado_db
```

---

## 🛠️ Tecnologias Utilizadas

### Front-end

* Flutter

### Back-end

* Python
* FastAPI

### Banco de Dados

* PostgreSQL

### Ferramentas

* Git / GitHub
* VS Code
* Figma (protótipos)
* Trello (gestão de tarefas)

---

## 🎯 Objetivo do Projeto

O principal objetivo do Fretado é simplificar e modernizar o processo de contratação de fretes, oferecendo:

* Facilidade na solicitação de transporte
* Conexão rápida entre cliente e motorista
* Gestão eficiente de demandas
* Maior segurança nas transações