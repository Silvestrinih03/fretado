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

## 🔐 Variáveis de Ambiente

Para o funcionamento correto do back-end, é necessário criar um arquivo `.env` dentro da pasta `back/`, seguindo o modelo do arquivo `.env.example`.

Exemplo:

```env
APP_NAME=Fretado API
APP_ENV=development
SECRET_KEY=sua_chave_secreta_aqui
DATABASE_URL=postgresql://usuario:senha@localhost:5432/fretado_db
```