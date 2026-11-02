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

## Mapas e navegação Android

Os mapas de solicitação e resumo usam `mapbox_maps_flutter` 2.12.0.
A navegação usa o Navigation SDK Android v3.12.0, com manobras, recálculo
e anúncios em português pelo mecanismo de voz do Android. Os artefatos nativos
usam NDK 27; o aplicativo requer Android API 23 ou superior.

1. Copie `mapbox.local.example.json` para `mapbox.local.json` e coloque um
   token **público** Mapbox (`pk.`). O arquivo local é ignorado pelo Git.
2. No Mapbox, mantenha a modalidade de navegação **por viagens**.
3. Use o backend atualizado, com a migration 036 e `GEOAPIFY_API_KEY` configurada.

```powershell
flutter pub get
flutter run --dart-define-from-file=mapbox.local.json --dart-define=API_BASE_URL=http://10.0.2.2:8000
flutter build apk --debug --dart-define-from-file=mapbox.local.json
```

`10.0.2.2` aponta para o computador no emulador Android. Em celular físico,
substitua pelo IP do computador na rede local. Sem `API_BASE_URL`, o aplicativo
usa a API de produção já definida no projeto.

O token público também é passado ao SDK nativo em memória. Não coloque token
secreto Mapbox, chave Geoapify ou credenciais do backend no build.
No CI, forneça o token público por `--dart-define=MAPBOX_PUBLIC_TOKEN=...`.

A orientação só permanece ativa enquanto a tela nativa está visível. Bloquear
a tela, abrir outro app ou voltar encerra a sessão; para retomar, toque em
**Iniciar navegação no Fretado**, que confere novamente o GPS e a corrida.
A tela consulta o destino autorizado a cada seis segundos e continua enviando
a localização ao backend. Confirmações de coleta e entrega são manuais.
Google Maps e Waze continuam disponíveis como opções externas.

A busca de endereço usa Geoapify, incluindo atribuições visíveis. Número é
obrigatório, com seleção explícita de S/N; alterações pedem confirmação do ponto.
Nenhum mapa usa o servidor público de tiles OpenStreetMap como fallback.
Os créditos OpenStreetMap permanecem por serem fontes dos provedores.

As franquias Mapbox de mapas, Directions e Navigation são independentes.
Não há bloqueio local de consumo: acompanhe o painel para permanecer nas faixas
gratuitas. Não são contratados recursos de geocodificação permanente ou
downloads offline. Mais informações: https://www.mapbox.com/pricing.

Esta alteração foi solicitada sem criação ou execução de testes automatizados.
A verificação prevista é análise estática e compilação Android.
