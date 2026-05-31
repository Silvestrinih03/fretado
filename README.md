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
````

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

## Publicação

### API

A API pode ser publicada no Render usando a pasta `back/`.

```bash
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

Configure as variáveis de ambiente do serviço:

```env
DATABASE_URL=sua_url_do_supabase_com_sslmode_require
SECRET_KEY=sua_chave_secreta
CORS_ALLOW_ORIGINS=https://fretado.pages.dev
CORS_ALLOW_ORIGIN_REGEX=
```

O banco pode ser criado no Supabase executando `sql/schema.sql` e os arquivos de `sql/seeds/`.

### Front/PWA

O front pode ser publicado na Cloudflare Pages como PWA.

```bash
cd front
flutter build web --release --dart-define=API_BASE_URL=https://fretado-api.onrender.com
npx wrangler pages deploy build/web --project-name=fretado
```

Depois do deploy, acesse `https://fretado.pages.dev` no celular e use a opção do navegador para instalar/adicionar à tela inicial.
