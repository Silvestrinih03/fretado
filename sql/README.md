# Banco de Dados - Fretado

## 📁 Estrutura

A pasta `sql/` está organizada da seguinte forma:

- **migrations/**: arquivos responsáveis pela criação e evolução da estrutura do banco de dados  
- **seeds/**: dados iniciais necessários para o funcionamento do sistema  
- **schema.sql**: versão consolidada contendo toda a estrutura do banco  

---

## ▶️ Ordem de Execução

Os arquivos dentro da pasta `migrations/` devem ser executados **em ordem numérica**, garantindo a integridade das dependências entre as tabelas.

Exemplo:

1. `001_create_user_types.sql`  
2. `002_create_users.sql`  
3. `003_create_user_profiles.sql`  

---

## ⚡ Inicialização Rápida

Alternativamente, é possível executar o arquivo:

```bash
schema.sql