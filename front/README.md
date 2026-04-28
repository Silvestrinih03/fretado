# 📱 Front-end

O front-end do projeto será desenvolvido utilizando **Flutter**, permitindo a criação de uma aplicação multiplataforma (mobile/web).

## 🚀 Como rodar o projeto

**Pré-requisitos:**

* Flutter instalado (versão recomendada: 3.35.2)

**Passos:**

```bash
cd front
flutter pub get
flutter run -d chrome
```

## API do backend

O app aceita a URL da API pelo `--dart-define=API_BASE_URL=...`.

### Web no mesmo computador

```bash
flutter run -d chrome
```

Nesse modo, a API padrao usada pelo front e `http://localhost:8000`.

### Web aberta pelo celular na mesma rede

1. Rode o backend com `--host 0.0.0.0`.
2. Descubra o IP local do computador com `ipconfig`.
3. Rode o front como servidor web:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

Abra no celular:

```text
http://SEU_IP:8080
```

Quando a pagina for aberta por `http://SEU_IP:8080`, o front usa automaticamente `http://SEU_IP:8000` como API.

### Emulador Android

```bash
flutter run -d emulator-5554
```

No Android Emulator, o front usa `http://10.0.2.2:8000`.

### Celular fisico Android ou iOS

```bash
flutter run -d SEU_DEVICE_ID --dart-define=API_BASE_URL=http://SEU_IP:8000
```

Use o IP local do computador que esta rodando o backend.
