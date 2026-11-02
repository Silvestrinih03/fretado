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

**Ver rota** abre apenas a prévia do destino, sem iniciar GPS de navegação,
voz ou sessão do Navigation SDK. A orientação é iniciada exclusivamente pelo
botão **Iniciar navegação no Fretado**. Ao voltar, a prévia é atualizada sem
reabrir a orientação automaticamente.

A busca de endereço usa Geoapify, incluindo atribuições visíveis. Número é
obrigatório, com seleção explícita de S/N. Ao calcular o frete, o cliente
confirma primeiro a coleta e depois a entrega em modais com mapa, podendo
ajustar os pontos de acesso. Só após ambas as confirmações é calculada a
cotação e aberto o resumo. Voltar ou fechar um modal preserva os detalhes e
não solicita a cotação.
Um resultado só move o pin quando número, rua, cidade e UF forem compatíveis.
Quando o número não é localizado com precisão, preservamos o pin e mostramos
um aviso no resumo se ele não for ajustado na confirmação. S/N também usa o
ponto escolhido, que pode ser ajustado no modal.

No resumo, **Ajustar ponto de coleta/entrega** retorna ao mapa com os dados
da encomenda e dos endereços preservados. Nessa edição, tocar no mapa ajusta
o pin do endereço informado. A próxima cotação usa as coordenadas ajustadas.
Os indicadores de imprecisão são locais ao aplicativo, sem novos campos na API.

A UF de coleta é normalizada e enviada tanto na cotação quanto na criação.
Se o campo estiver ausente, o aplicativo pode recuperar a sigla explícita do
endereço selecionado no formato rua, cidade, UF, CEP. Ajustar o número com um
resultado compatível preserva essa UF quando a busca não a repetir. Se a UF
estiver ausente, ou o pin for movido na confirmação da coleta, o app consulta
o estado do ponto confirmado antes de cotar, preservando o endereço e o número
informados. A API usa uma consulta de nível estadual quando o resultado do
endereço não inclui UF; essa correção exige reiniciar o backend atualizado.

As confirmações operacionais do motorista usam um diálogo compartilhado no
tema grafite e dourado: iniciar corrida, confirmar coleta e confirmar entrega
para finalizar a corrida. Devoluções mantêm seus textos específicos. Fechar
ou voltar não executa a ação; somente o botão principal confirma a etapa.

Flutter e navegação Android usam Streets v12 com a paleta compartilhada em
`assets/maps/fret_map_theme.json`: fundo areia, parques verdes, água azul,
construções neutras e rota dourada. As cores são aplicadas depois de carregar
o estilo; camadas ausentes mantêm o mapa funcional. A barra de escala fica
oculta, e logo e informações Mapbox permanecem visíveis com margens discretas.
Os créditos de geocodificação usam uma faixa neutra, com links e fontes
adicionais preservadas. Sem sugestões ou endereços, essa faixa não é exibida.
Nenhum mapa usa o servidor público de tiles OpenStreetMap como fallback.
Os créditos OpenStreetMap permanecem por serem fontes dos provedores.

As franquias Mapbox de mapas, Directions e Navigation são independentes.
Não há bloqueio local de consumo: acompanhe o painel para permanecer nas faixas
gratuitas. Não são contratados recursos de geocodificação permanente ou
downloads offline. Mais informações: https://www.mapbox.com/pricing.

Esta alteração foi solicitada sem criação ou execução de testes automatizados.
A verificação prevista é análise estática e compilação Android.

## Central de ajuda

O botão **Ajuda e suporte** do perfil abre uma central com conteúdo adaptado
a `HomeProfileEnum.client` ou `HomeProfileEnum.driver`. Busca e categorias são
locais; consultar as respostas não exige chamadas à API.

As perguntas ficam em `lib/features/help/data/help_articles.dart`, separadas da
interface. Cada artigo tem identificador estável, categoria, pergunta,
parágrafos, palavras de busca e, quando necessário, perfil e links de referência.
Busca ignora maiúsculas e acentos e respeita o perfil e a categoria selecionados.

Ao alterar cálculo de frete, pagamentos, cancelamentos, avaliação ou localização,
revise também os artigos correspondentes. O conteúdo documenta os pagamentos
simulados, a referência ANP, os intervalos de localização atuais e as regras
implementadas, sem modificar esses comportamentos.

O contato `suporte@freteja.com.br` permanece demonstrativo, com aviso visível.
O botão de atendimento abre uma explicação; não envia e-mail nem abre um canal
real de suporte. A central também oferece acesso a Termos e privacidade.
