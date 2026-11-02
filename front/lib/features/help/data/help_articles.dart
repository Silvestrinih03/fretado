import '../../../core/enums/home_profile.dart';

enum HelpCategory {
  rides('Corridas'),
  pricing('Valores e pagamentos'),
  cancellations('Cancelamentos'),
  conversations('Chat e avaliações'),
  account('Conta e fotos'),
  location('Localização e notificações'),
  services('Serviços utilizados');

  final String label;
  const HelpCategory(this.label);
}

class HelpArticleLink {
  final String label;
  final String url;
  const HelpArticleLink(this.label, this.url);
}

/// Shared articles have no audience. An article's ID survives copy changes.
class HelpArticle {
  final String id;
  final HelpCategory category;
  final String question;
  final List<String> paragraphs;
  final List<String> keywords;
  final HomeProfileEnum? audience;
  final List<HelpArticleLink> links;

  const HelpArticle({
    required this.id,
    required this.category,
    required this.question,
    required this.paragraphs,
    this.keywords = const [],
    this.audience,
    this.links = const [],
  });

  bool visibleFor(HomeProfileEnum profile) =>
      audience == null || audience == profile;

  String get searchText => normalizeHelpSearch(
    [question, category.label, ...paragraphs, ...keywords].join(' '),
  );
}

String normalizeHelpSearch(String value) {
  const accented = 'áàâãäåéèêëíìîïóòôõöúùûüçñ';
  const plain = 'aaaaaaeeeeiiiiooooouuuucn';
  final result = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    // Ignore combining accents as well as composed Portuguese characters.
    if (rune >= 0x0300 && rune <= 0x036f) continue;
    final character = String.fromCharCode(rune);
    final index = accented.indexOf(character);
    result.write(index < 0 ? character : plain[index]);
  }
  return result.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

List<HelpArticle> filterHelpArticles({
  required HomeProfileEnum profile,
  HelpCategory? category,
  String query = '',
}) {
  final tokens = normalizeHelpSearch(
    query,
  ).split(' ').where((token) => token.isNotEmpty).toList();
  return helpArticles
      .where((article) {
        if (!article.visibleFor(profile) ||
            (category != null && article.category != category)) {
          return false;
        }
        if (tokens.isEmpty) return true;
        final text = article.searchText;
        return tokens.every(text.contains);
      })
      .toList(growable: false);
}

// Content reflects the current app, not services planned for production.
// Revisit these articles when pricing, settlement, tracking or policies change.
const helpArticles = <HelpArticle>[
  HelpArticle(
    id: 'client-request',
    category: HelpCategory.rides,
    audience: HomeProfileEnum.client,
    question: 'Como solicito um frete?',
    paragraphs: [
      'Escolha coleta e entrega, confira os pontos no mapa e preencha os detalhes dos endereços e da encomenda. Depois, calcule o valor, revise o resumo e confirme a solicitação com um cartão cadastrado.',
      'Acompanhe o aceite, o deslocamento para a coleta e a entrega pelo app. A disponibilidade depende de encontrar um motorista com veículo compatível na região.',
    ],
    keywords: ['pedir', 'solicitação', 'enviar', 'pedido', 'passo a passo'],
  ),
  HelpArticle(
    id: 'client-address-number',
    category: HelpCategory.rides,
    audience: HomeProfileEnum.client,
    question: 'Por que preciso informar o número ou marcar S/N?',
    paragraphs: [
      'Coleta e entrega precisam de um número confirmado. Se o endereço realmente não tiver numeração, selecione “Sem número — S/N”. Um campo vazio não é interpretado como S/N.',
      'Confira números preenchidos pela busca. Se você corrigir o número, o app pode pedir a confirmação do ponto de acesso no mapa. Ajuste o pin antes de confirmar.',
      'Use complemento para apartamento, bloco ou sala e referência para algo que facilite a chegada. Esses dois campos são opcionais.',
    ],
    keywords: [
      'endereço',
      'numero',
      'sem numero',
      'sn',
      'pin',
      'complemento',
      'referência',
    ],
  ),
  HelpArticle(
    id: 'package-measurements',
    category: HelpCategory.rides,
    question: 'Como informar e conferir as medidas da encomenda?',
    paragraphs: [
      'Informe largura, altura e comprimento em centímetros (cm), e peso em quilos (kg). Considere a encomenda já embalada e use valores maiores que zero.',
      'Peso e dimensões ajudam a selecionar a categoria de veículo e a verificar se a carga cabe. Informações incorretas podem impedir o atendimento. Como cuidado de transporte, proteja a embalagem e combine os detalhes de acesso pelo chat.',
    ],
    keywords: [
      'carga',
      'tamanho',
      'volume',
      'embalagem',
      'capacidade',
      'veículo',
    ],
  ),
  HelpArticle(
    id: 'client-no-driver',
    category: HelpCategory.rides,
    audience: HomeProfileEnum.client,
    question: 'Por que não encontro um motorista disponível?',
    paragraphs: [
      'É necessário haver um motorista online, elegível e com veículo compatível com a encomenda na região de coleta. Uma localização recente também é necessária para identificar a disponibilidade.',
      'Uma cotação não reserva um motorista. Se ninguém estiver disponível ao confirmar, confira os endereços e as medidas e tente novamente mais tarde.',
    ],
    keywords: [
      'sem motorista',
      'nenhum',
      'disponibilidade',
      'oferta',
      'região',
    ],
  ),
  HelpArticle(
    id: 'ride-statuses',
    category: HelpCategory.rides,
    question: 'O que significam as etapas da corrida?',
    paragraphs: [
      'A corrida passa por espera de aceite, aceite com início pendente, motorista a caminho da coleta, motorista a caminho da entrega e conclusão. Cancelamentos e devoluções têm acompanhamentos próprios.',
      'O motorista confirma a coleta quando recebe a carga e confirma a entrega quando a conclui. Estar perto do ponto no GPS não finaliza a etapa automaticamente.',
    ],
    keywords: ['status', 'andamento', 'acompanhar', 'chegada', 'finalizar'],
  ),
  HelpArticle(
    id: 'driver-offer',
    category: HelpCategory.rides,
    audience: HomeProfileEnum.driver,
    question: 'O que devo conferir antes de aceitar uma oferta?',
    paragraphs: [
      'Confira coleta, entrega, dimensões, peso, veículo e valores apresentados. Aceite apenas quando puder realizar o transporte e seguir as etapas da corrida.',
      'As ofertas dependem de disponibilidade, localização recente e compatibilidade do veículo. Uma oferta pode deixar de estar disponível antes do aceite; acompanhe sempre o estado atualizado no app.',
    ],
    keywords: ['aceitar', 'recusar', 'pedido', 'carga', 'veículo'],
  ),
  HelpArticle(
    id: 'driver-replacement',
    category: HelpCategory.rides,
    audience: HomeProfileEnum.driver,
    question: 'E se eu não conseguir continuar uma corrida?',
    paragraphs: [
      'Antes da coleta, use a opção de desistência da corrida para solicitar substituição. Você continua responsável enquanto a busca é processada; acompanhe as instruções do app até a atribuição ser atualizada.',
      'Depois da coleta, use a opção de transferência da entrega. Sua localização será usada como ponto de encontro, e a responsabilidade pela carga só passa ao substituto quando ele confirmar que a recebeu.',
      'Se não houver substituto, acompanhe a pendência pelo app. Ficar offline ou sair da tela não conclui uma transferência.',
    ],
    keywords: [
      'desistir',
      'trocar motorista',
      'substituto',
      'transferência',
      'responsabilidade',
    ],
  ),
  HelpArticle(
    id: 'client-driver-change',
    category: HelpCategory.rides,
    audience: HomeProfileEnum.client,
    question: 'O motorista da minha corrida pode mudar?',
    paragraphs: [
      'Pode haver substituição antes da coleta ou transferência durante a entrega. O app mostra o andamento e a nova atribuição quando ela é confirmada.',
      'Durante uma transferência com carga, o motorista anterior continua responsável até o substituto confirmar o recebimento. Confira o motorista atual e use a conversa correspondente à atribuição vigente.',
    ],
    keywords: ['troca', 'substituição', 'transferência', 'outro motorista'],
  ),
  HelpArticle(
    id: 'freight-calculation',
    category: HelpCategory.pricing,
    question: 'Como é calculado o valor da corrida?',
    paragraphs: [
      'O cálculo começa com a distância da rota e a categoria de veículo necessária para a carga. A partir do consumo estimado do veículo e do preço de referência do combustível, estimamos o custo de combustível.',
      'Somamos o custo operacional por quilômetro e a margem do motorista. A composição também considera a taxa da plataforma e um preço mínimo da categoria, quando configurado. Os valores são arredondados para centavos.',
      'Peso e dimensões ajudam a definir o veículo adequado. A previsão de tempo serve para orientar o trajeto; o cálculo atual não aplica uma tarifa direta por minuto. Confira a composição e o total antes de confirmar.',
    ],
    keywords: [
      'preço',
      'valor',
      'combustível',
      'taxa',
      'distância',
      'margem',
      'mínimo',
      'minutos',
    ],
  ),
  HelpArticle(
    id: 'anp-fuel-reference',
    category: HelpCategory.pricing,
    question: 'O que a ANP tem a ver com o preço do frete?',
    paragraphs: [
      'Usamos dados públicos da Agência Nacional do Petróleo, Gás Natural e Biocombustíveis (ANP) como referência de combustível. A base reúne preços coletados em postos e permite calcular médias por combustível e estado (UF).',
      'O app usa a referência mais recente importada para o combustível e a UF de origem. Não consulta um posto específico a cada corrida. A referência pode diferir do preço que você encontra na bomba.',
      'A ANP fornece os dados de combustível; o Fretado calcula o frete com esses dados e os demais componentes da corrida. A ANP não define a tarifa do frete.',
    ],
    keywords: [
      'gasolina',
      'etanol',
      'diesel',
      'posto',
      'litro',
      'média',
      'origem',
      'estado',
    ],
    links: [
      HelpArticleLink(
        'Consultar os dados oficiais da ANP',
        'https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/serie-historica-de-precos-de-combustiveis',
      ),
    ],
  ),
  HelpArticle(
    id: 'client-payment',
    category: HelpCategory.pricing,
    audience: HomeProfileEnum.client,
    question: 'Quando eu pago pela corrida?',
    paragraphs: [
      'A regra de negócio é que o cliente paga ao solicitar a corrida, após revisar o valor e confirmar o pedido. O motorista recebe seu ganho após concluir a entrega.',
      'Nesta versão de testes, o app exige um cartão cadastrado para confirmar a solicitação e registra valores simulados. Não há processamento de cobrança no cartão, estorno ou repasse bancário real.',
      'Os valores exibidos permitem acompanhar o fluxo de teste. Cadastre e selecione um cartão na etapa de verificação; isso não representa uma cobrança bancária realizada.',
    ],
    keywords: [
      'pagar',
      'pagamento',
      'cartão',
      'cobrança',
      'simulação',
      'teste',
    ],
  ),
  HelpArticle(
    id: 'driver-payment',
    category: HelpCategory.pricing,
    audience: HomeProfileEnum.driver,
    question: 'Quando recebo e qual valor fica para mim?',
    paragraphs: [
      'A regra de negócio é que o cliente paga ao solicitar e o motorista recebe após concluir a entrega. O crédito do ganho na carteira do app é registrado quando a corrida é finalizada.',
      'O valor total da corrida inclui a taxa da plataforma. Seu ganho líquido corresponde ao total menos essa taxa, conforme os valores registrados na corrida. A carteira mostra o saldo e os lançamentos.',
      'Nesta versão, os registros financeiros são simulados. O crédito na carteira do app não representa depósito bancário ou transferência real para sua conta.',
    ],
    keywords: [
      'ganho',
      'receber',
      'recebimento',
      'líquido',
      'bruto',
      'saldo',
      'taxa',
      'carteira',
    ],
  ),
  HelpArticle(
    id: 'quote-changes',
    category: HelpCategory.pricing,
    question: 'O valor pode mudar antes de confirmar a solicitação?',
    paragraphs: [
      'Sim. A cotação é conferida novamente pelo servidor na confirmação. Mudanças na rota, na disponibilidade de veículos ou nas referências usadas no cálculo podem exigir uma nova revisão do valor ou da categoria.',
      'Se o app apresentar uma cotação atualizada, confira o novo resumo antes de confirmar. Não considere a consulta inicial uma reserva de preço ou de motorista.',
    ],
    keywords: [
      'preço mudou',
      'recalcular',
      'cotação',
      'orçamento',
      'diferença',
    ],
  ),
  HelpArticle(
    id: 'driver-special-earnings',
    category: HelpCategory.pricing,
    audience: HomeProfileEnum.driver,
    question: 'Como ficam os ganhos em cancelamentos e transferências?',
    paragraphs: [
      'Quando o cliente cancela com o motorista a caminho da coleta, a taxa atual de 10% é destinada à compensação do motorista e registrada conforme a resolução do cancelamento.',
      'Após a coleta, o fluxo calcula o serviço já realizado e a devolução. O ganho correspondente é registrado com a conclusão da corrida de devolução.',
      'Em transferências, há rateio entre os motoristas pelos trechos definidos pelo app. Os ganhos são registrados na conclusão da entrega, com os valores apresentados no fluxo. Esses registros e ajustes são simulados nesta versão.',
    ],
    keywords: [
      'rateio',
      'compensação',
      'taxa',
      'devolução',
      'substituição',
      'repasse',
    ],
  ),
  HelpArticle(
    id: 'ride-records',
    category: HelpCategory.pricing,
    question: 'Onde consulto o histórico e os registros de valores?',
    paragraphs: [
      'Abra o histórico de corridas e selecione uma corrida para consultar os detalhes disponíveis, como endereços, andamento e valor. Cancelamentos também têm acompanhamento e registro de eventos.',
      'Motoristas podem consultar ganhos, carteira e lançamentos nas áreas correspondentes. Nesta fase de testes, os registros do app não representam comprovante de pagamento bancário ou nota fiscal. Não há emissão de comprovante bancário real pelo fluxo simulado.',
    ],
    keywords: [
      'comprovante',
      'recibo',
      'extrato',
      'histórico',
      'nota fiscal',
      'consulta',
    ],
  ),
  HelpArticle(
    id: 'driver-withdrawal',
    category: HelpCategory.pricing,
    audience: HomeProfileEnum.driver,
    question: 'Como funciona a solicitação de saque da carteira?',
    paragraphs: [
      'Na carteira, a opção de solicitar saque pede um valor e uma chave Pix. O valor precisa ser positivo e não pode ultrapassar o saldo disponível exibido.',
      'Nesta versão, a movimentação é registrada no fluxo financeiro de testes. Não há repasse bancário ou envio de Pix real, nem promessa de prazo de depósito. Consulte o saldo e o histórico de lançamentos para acompanhar os registros.',
    ],
    keywords: [
      'pix',
      'sacar',
      'saque',
      'retirar',
      'saldo',
      'banco',
      'depósito',
    ],
  ),
  HelpArticle(
    id: 'client-cancel-before-acceptance',
    category: HelpCategory.cancellations,
    audience: HomeProfileEnum.client,
    question: 'Posso cancelar antes de um motorista aceitar?',
    paragraphs: [
      'Enquanto a corrida aguarda aceite, o cancelamento não tem taxa. O app registra a devolução integral do valor da corrida.',
      'Nesta versão, a devolução é um registro financeiro simulado; não corresponde a um estorno bancário. Confira o estado da corrida e a prévia apresentada antes de confirmar.',
    ],
    keywords: [
      'cancelar',
      'antes do aceite',
      'gratuito',
      'reembolso',
      'estorno',
    ],
  ),
  HelpArticle(
    id: 'client-cancel-before-start',
    category: HelpCategory.cancellations,
    audience: HomeProfileEnum.client,
    question: 'E se o motorista aceitou, mas ainda não iniciou o deslocamento?',
    paragraphs: [
      'Nessa etapa, você pode solicitar cancelamento sem taxa, informando uma justificativa com pelo menos dez caracteres. O app registra a devolução integral do valor.',
      'Confira a etapa atual na prévia: quando o motorista já está a caminho da coleta, aplica-se outra regra. Os ajustes financeiros desta versão são simulados.',
    ],
    keywords: [
      'motivo',
      'justificativa',
      'aceite',
      'aguardando início',
      'dez caracteres',
    ],
  ),
  HelpArticle(
    id: 'cancel-pickup-fee',
    category: HelpCategory.cancellations,
    question: 'Qual é a taxa quando o motorista já está a caminho da coleta?',
    paragraphs: [
      'A taxa atual é de 10% do valor total da corrida quando o cliente cancela durante o deslocamento para a coleta. Esse valor compensa o motorista, e o restante é registrado como devolução ao cliente.',
      r'Por exemplo: para uma corrida de R$ 100,00, a taxa é R$ 10,00 e a devolução registrada é R$ 90,00. Confira sempre a prévia do cancelamento. Nesta versão, os ajustes são simulados.',
    ],
    keywords: [
      'cancelamento',
      '10%',
      'dez por cento',
      'cobrança',
      'reembolso',
      'compensação',
    ],
  ),
  HelpArticle(
    id: 'cancel-after-pickup',
    category: HelpCategory.cancellations,
    question: 'Como funciona o cancelamento depois da coleta?',
    paragraphs: [
      'O cliente escolhe se a carga deve voltar à coleta ou seguir para outro endereço de devolução. O fluxo usa a posição recente do motorista para calcular o trajeto já realizado e o caminho de devolução.',
      'O motorista prepara o cálculo e confirma a situação da carga. Depois, o cliente analisa e decide sobre a proposta. Ela pode apresentar valor a devolver ou cobrança complementar em relação ao valor original.',
      'Se o cliente aceitar, o app cancela a corrida original e cria uma corrida de devolução, que deve ser concluída pelo motorista. Não há taxa fixa de 10% para essa etapa. Os ajustes financeiros são simulados nesta versão.',
    ],
    keywords: [
      'carga coletada',
      'devolução',
      'retorno',
      'trajeto',
      'diferença',
      'complementar',
    ],
  ),
  HelpArticle(
    id: 'client-reject-return',
    category: HelpCategory.cancellations,
    audience: HomeProfileEnum.client,
    question: 'O que acontece se eu recusar o custo de devolução?',
    paragraphs: [
      'Se você recusar a proposta de cancelamento após a coleta, a solicitação de cancelamento é encerrada como recusada e a corrida original continua para o destino previsto.',
      'Acompanhe a decisão no app e use o chat para combinar informações operacionais. A proposta só gera a corrida de devolução após a confirmação do cliente.',
    ],
    keywords: [
      'rejeitar',
      'recusa',
      'não aceitar',
      'proposta',
      'continuar entrega',
    ],
  ),
  HelpArticle(
    id: 'cancel-restrictions',
    category: HelpCategory.cancellations,
    question: 'Por que a opção de cancelamento pode ficar indisponível?',
    paragraphs: [
      'Corridas já concluídas não entram no fluxo de cancelamento. Uma corrida criada para devolução também não pode ser cancelada novamente por esse fluxo.',
      'Uma substituição ou transferência de motorista em andamento pode impedir um novo cancelamento até que a situação seja resolvida. Consulte as pendências e o acompanhamento da corrida para entender a etapa atual.',
    ],
    keywords: [
      'bloqueado',
      'indisponível',
      'não consigo cancelar',
      'transferência',
      'devolução',
    ],
  ),
  HelpArticle(
    id: 'driver-cancellation-actions',
    category: HelpCategory.cancellations,
    audience: HomeProfileEnum.driver,
    question: 'O que preciso fazer quando o cliente solicita cancelamento?',
    paragraphs: [
      'Confira o aviso e as ações exigidas na corrida. Após a coleta, mantenha sua localização atualizada para preparar o cálculo de devolução e confirme a situação da carga antes da decisão do cliente.',
      'Depois da decisão, siga o destino e as confirmações apresentados pelo app. Cancelamento pelo cliente é um fluxo diferente de sua solicitação de desistência ou transferência; use a ação correspondente ao caso.',
    ],
    keywords: [
      'confirmar carga',
      'orçamento',
      'pendência',
      'ciência',
      'desistência',
    ],
  ),
  HelpArticle(
    id: 'chat-availability',
    category: HelpCategory.conversations,
    question: 'Quando o chat fica disponível e quem pode conversar?',
    paragraphs: [
      'O chat é criado após o aceite e fica disponível entre o cliente e o motorista daquela atribuição. É possível enviar mensagens enquanto a corrida está aceita, a caminho da coleta ou a caminho da entrega.',
      'Antes de haver motorista atribuído, não há conversa ativa. Use o chat da corrida para combinar acesso, referência e detalhes operacionais do transporte.',
    ],
    keywords: ['conversa', 'mensagens', 'falar', 'comunicação', 'aceite'],
  ),
  HelpArticle(
    id: 'chat-closed',
    category: HelpCategory.conversations,
    question: 'Por que uma conversa foi encerrada?',
    paragraphs: [
      'Conclusão, cancelamento ou troca de motorista encerram a conversa anterior para novas mensagens. As mensagens já registradas continuam disponíveis para consulta pelos participantes autorizados.',
      'Com uma nova atribuição, use a conversa do motorista atual. Uma conversa encerrada não é reaberta apenas porque você voltou à tela.',
    ],
    keywords: [
      'histórico',
      'chat bloqueado',
      'não consigo enviar',
      'troca de motorista',
    ],
  ),
  HelpArticle(
    id: 'chat-message-rules',
    category: HelpCategory.conversations,
    question: 'Quais são as regras e os limites das mensagens?',
    paragraphs: [
      'O chat atual aceita mensagens de texto não vazias com até 1.000 caracteres. Não há envio de fotos, arquivos ou áudio por essa conversa.',
      'Como orientação de uso, mantenha respeito, envie informações relacionadas à corrida e evite compartilhar senhas, códigos de acesso ou dados bancários. Compartilhe apenas as informações necessárias para realizar o transporte.',
    ],
    keywords: [
      'limite',
      'mil',
      '1000',
      'anexo',
      'áudio',
      'imagem',
      'segurança',
      'respeito',
    ],
  ),
  HelpArticle(
    id: 'rating-eligibility',
    category: HelpCategory.conversations,
    question: 'Quando posso avaliar uma corrida?',
    paragraphs: [
      'A avaliação fica disponível após a corrida ser finalizada, com notas de uma a cinco estrelas. Cliente e motorista podem enviar uma avaliação cada por corrida; o app não permite reenviar a mesma avaliação.',
      'A avaliação considera o cliente e o motorista responsável pela conclusão. Em uma transferência, isso não cria automaticamente avaliações para todos os motoristas que participaram dos trechos. Confira as avaliações pendentes no app.',
    ],
    keywords: ['avaliar', 'estrelas', 'pendentes', 'finalizada', 'uma vez'],
  ),
  HelpArticle(
    id: 'rating-average',
    category: HelpCategory.conversations,
    question: 'Como é calculada a nota final do meu perfil?',
    paragraphs: [
      'A nota do perfil é a média simples das estrelas recebidas: somamos as notas e dividimos pela quantidade de avaliações. Cada avaliação tem o mesmo peso.',
      'O resultado é arredondado para uma casa decimal. Exemplo: receber 5, 4 e 3 estrelas resulta em (5 + 4 + 3) ÷ 3 = 4,0. Quando ainda não há avaliações, não existe média calculada.',
    ],
    keywords: ['avaliação', 'média', 'nota', 'reputação', 'pontuação', 'peso'],
  ),
  HelpArticle(
    id: 'rating-criteria',
    category: HelpCategory.conversations,
    question: 'Os critérios marcados e os comentários alteram a nota?',
    paragraphs: [
      'Os critérios ajudam a descrever a experiência, mas não acrescentam peso à nota em estrelas. O comentário também não modifica a média.',
      'Para motoristas, os critérios incluem pontualidade, cuidado com a encomenda, comunicação e cordialidade. Para clientes, incluem comunicação, facilidade na coleta, informações corretas e pontualidade. O comentário é opcional e aceita até 500 caracteres.',
    ],
    keywords: ['tags', 'comentário', 'critérios', 'elogios', 'nota final'],
  ),
  HelpArticle(
    id: 'avatar-formats',
    category: HelpCategory.account,
    question: 'Quais fotos posso usar no perfil?',
    paragraphs: [
      'A foto de perfil aceita JPG/JPEG, PNG e WebP, com tamanho máximo de 5 MB. Toque na foto no perfil ou nos dados pessoais para escolher ou atualizar a imagem.',
      'O arquivo precisa conter uma imagem válida e ter um formato compatível com o tipo enviado. Alterar apenas o nome ou a extensão não converte uma foto.',
    ],
    keywords: [
      'foto',
      'imagem',
      'avatar',
      'png',
      'jpg',
      'jpeg',
      'webp',
      '5mb',
      '5 mb',
    ],
  ),
  HelpArticle(
    id: 'avatar-upload-errors',
    category: HelpCategory.account,
    question: 'Por que minha foto não foi aceita?',
    paragraphs: [
      'O arquivo pode estar acima de 5 MB, corrompido, vazio ou em formato não aceito. HEIC e GIF precisam ser convertidos para JPEG, PNG ou WebP antes do envio.',
      'Se a imagem já estiver em um formato permitido, confira a conexão e tente escolher o arquivo novamente. Para tirar uma foto, permita o acesso à câmera quando o aparelho solicitar.',
    ],
    keywords: [
      'erro foto',
      'upload',
      'heic',
      'gif',
      'converter',
      'câmera',
      'permissão',
    ],
  ),
  HelpArticle(
    id: 'account-data-password',
    category: HelpCategory.account,
    question: 'Como atualizo meus dados ou recupero minha senha?',
    paragraphs: [
      'No perfil, abra Dados pessoais para consultar e editar as informações permitidas. Para alterar a senha enquanto estiver conectado, use Segurança e senha.',
      'Se perdeu o acesso, use a recuperação de senha na tela de entrada e siga as instruções enviadas ao seu e-mail. Confira também a pasta de spam e evite compartilhar o link ou os códigos recebidos.',
    ],
    keywords: [
      'cadastro',
      'nome',
      'telefone',
      'email',
      'e-mail',
      'esqueci',
      'login',
      'conta',
    ],
  ),
  HelpArticle(
    id: 'account-privacy',
    category: HelpCategory.account,
    question: 'Onde encontro os Termos e a Política de Privacidade?',
    paragraphs: [
      'Acesse Termos e privacidade no perfil ou pelo atalho ao final desta central. Lá você pode consultar as informações de uso da plataforma e tratamento de dados apresentadas pelo app.',
      'Mantenha seu cadastro atualizado e use as opções de permissão do aparelho para controlar câmera, localização e notificações. Algumas funcionalidades dependem dessas permissões para funcionar.',
    ],
    keywords: [
      'política',
      'privacidade',
      'dados pessoais',
      'termos',
      'permissões',
    ],
  ),
  HelpArticle(
    id: 'driver-online-requirements',
    category: HelpCategory.location,
    audience: HomeProfileEnum.driver,
    question: 'O que preciso para ficar online e receber ofertas?',
    paragraphs: [
      'Mantenha a CNH preenchida e dentro da validade, incluindo as informações exigidas no cadastro, e pelo menos um veículo ativo. Ative o GPS, permita o acesso à localização e confira sua conexão.',
      'Se houver pendência na CNH ou no veículo, o app informa o que regularizar e pode retirar a disponibilidade para novas ofertas. Depois de corrigir o cadastro, fique online manualmente; a correção não ativa sua disponibilidade sozinha.',
    ],
    keywords: [
      'online',
      'disponível',
      'CNH',
      'documentos',
      'vencida',
      'veículo ativo',
      'GPS',
    ],
  ),
  HelpArticle(
    id: 'driver-offline-active-ride',
    category: HelpCategory.location,
    audience: HomeProfileEnum.driver,
    question: 'Ficar offline encerra uma corrida ou para a localização?',
    paragraphs: [
      'Offline significa indisponível para novas ofertas. Isso não cancela uma corrida já aceita nem conclui uma entrega ou transferência pendente.',
      'Enquanto houver corrida ativa, o app pode continuar atualizando a localização para permitir o acompanhamento e a conclusão, mesmo com a disponibilidade offline. Sem corrida ativa e offline, a atualização periódica de disponibilidade é interrompida.',
    ],
    keywords: [
      'offline',
      'rastreamento',
      'parar',
      'corrida ativa',
      'responsabilidade',
    ],
  ),
  HelpArticle(
    id: 'driver-location-intervals',
    category: HelpCategory.location,
    audience: HomeProfileEnum.driver,
    question: 'De quanto em quanto tempo minha localização é atualizada?',
    paragraphs: [
      'Na disponibilidade, o app solicita a posição ao ativar ou sincronizar o estado e faz atualizações periódicas de aproximadamente 45 segundos enquanto você está online ou com corrida ativa.',
      'Na navegação integrada visível, o envio ao servidor ocorre aproximadamente a cada 6 segundos, conforme o sinal e a conexão. O GPS também fornece posições ao mapa para orientar o deslocamento.',
      'Os 5 minutos são o limite de validade configurado para considerar uma posição recente em operações do servidor. Eles não representam o intervalo entre envios. GPS, permissões, conexão e condições de execução do aparelho podem afetar essas atualizações.',
    ],
    keywords: [
      'coleta de localização',
      'cinco minutos',
      '5 minutos',
      '45 segundos',
      '6 segundos',
      'frequência',
      'GPS',
    ],
  ),
  HelpArticle(
    id: 'client-location',
    category: HelpCategory.location,
    audience: HomeProfileEnum.client,
    question: 'Para que o app usa minha localização e a do motorista?',
    paragraphs: [
      'Na solicitação, você pode usar sua posição para selecionar um endereço no mapa. Também pode buscar o endereço e conferir manualmente o ponto de coleta ou entrega.',
      'A posição do motorista ajuda a identificar disponibilidade e acompanhar o serviço. O acompanhamento depende de GPS, permissões e conexão; a posição exibida pode ficar desatualizada se algum desses recursos falhar.',
    ],
    keywords: [
      'GPS',
      'mapa',
      'permissão',
      'acompanhar motorista',
      'posição',
      'endereço',
    ],
  ),
  HelpArticle(
    id: 'driver-navigation',
    category: HelpCategory.location,
    audience: HomeProfileEnum.driver,
    question: 'Como usar a navegação integrada, Maps ou Waze?',
    paragraphs: [
      'Na corrida, abra a navegação para o próximo destino: coleta ou entrega. A navegação integrada no Android oferece manobras, orientação por voz e recálculo, com GPS preciso e acesso à internet.',
      'A orientação integrada funciona enquanto a tela de navegação está visível. Sair dela, abrir outro app ou bloquear o aparelho encerra a sessão. Para retomar, inicie novamente; o app confere a corrida e a localização.',
      'Você também pode escolher Google Maps ou Waze. A chegada no mapa não confirma coleta ou entrega automaticamente: volte à corrida e confirme apenas depois de realizar a etapa.',
    ],
    keywords: [
      'mapbox',
      'voz',
      'navegar',
      'rota',
      'tela bloqueada',
      'maps',
      'waze',
    ],
  ),
  HelpArticle(
    id: 'client-notifications',
    category: HelpCategory.location,
    audience: HomeProfileEnum.client,
    question: 'Quais notificações posso receber como cliente?',
    paragraphs: [
      'Você pode receber avisos de aceite, motorista a caminho, coleta, entrega, mensagens e atualizações de cancelamento, devolução ou troca de motorista, conforme o andamento da corrida.',
      'Os avisos ajudam a acompanhar o serviço, mas a tela da corrida mostra o estado atualizado. Uma notificação recebida com atraso pode se referir a uma etapa que já mudou.',
    ],
    keywords: ['notificações', 'avisos', 'push', 'alertas', 'mensagens'],
  ),
  HelpArticle(
    id: 'driver-notifications',
    category: HelpCategory.location,
    audience: HomeProfileEnum.driver,
    question: 'Quais notificações posso receber como motorista?',
    paragraphs: [
      'Você pode receber ofertas, mensagens e avisos de cancelamento, substituição, transferência, devolução ou crédito de ganhos, conforme sua participação na corrida.',
      'Uma notificação de oferta não garante que ela ainda esteja disponível no momento do toque. Confira a tela atual antes de agir e acompanhe as pendências da corrida no app.',
    ],
    keywords: [
      'notificações',
      'avisos',
      'push',
      'alertas',
      'ofertas',
      'ganhos',
    ],
  ),
  HelpArticle(
    id: 'notification-troubleshooting',
    category: HelpCategory.location,
    question: 'Não recebo notificações. O que posso conferir?',
    paragraphs: [
      'No Android, confira se as notificações do Fretado estão permitidas nas configurações do aparelho, se há internet e se você está conectado à sua conta. Confira também se o sistema está restringindo a execução ou silenciando os avisos.',
      'Abra o app e consulte a corrida, as mensagens ou as ofertas para atualizar as informações. O recebimento depende do aparelho e do serviço de notificações; não há garantia de entrega imediata de cada aviso.',
    ],
    keywords: [
      'permissão',
      'silencioso',
      'bateria',
      'atraso',
      'não aparece',
      'alerta',
    ],
  ),
  HelpArticle(
    id: 'carpedia-vehicles',
    category: HelpCategory.services,
    audience: HomeProfileEnum.driver,
    question: 'Para que o Fretado usa a Carpédia?',
    paragraphs: [
      'A Carpédia fornece o catálogo usado na seleção de marca, modelo, versão e ano do veículo, além de informações técnicas aproveitadas no cadastro e nas estimativas do app.',
      'Se o catálogo estiver temporariamente indisponível, tente novamente mais tarde. Você não precisa criar conta na Carpédia nem informar uma chave de API para cadastrar seu veículo pelo Fretado.',
    ],
    keywords: [
      'carpedia',
      'catálogo',
      'marca',
      'modelo',
      'versão',
      'ano',
      'veículo',
      'API',
    ],
    links: [
      HelpArticleLink('Conhecer a Carpédia', 'https://www.carpedia.com.br/'),
    ],
  ),
  HelpArticle(
    id: 'mapbox-maps',
    category: HelpCategory.services,
    question: 'Para que o app usa o Mapbox?',
    paragraphs: [
      'O Mapbox fornece os mapas, o cálculo de rotas, a distância e a estimativa de duração. Ele também dá suporte à navegação integrada do motorista no Android.',
      'A rota e a previsão podem mudar conforme as condições disponíveis no serviço. Confira o destino e as condições do trajeto; o mapa não substitui os cuidados necessários durante a condução.',
    ],
    keywords: [
      'mapa',
      'GPS',
      'API',
      'distância',
      'tempo',
      'navegação',
      'trajeto',
    ],
    links: [HelpArticleLink('Conhecer o Mapbox', 'https://www.mapbox.com/')],
  ),
  HelpArticle(
    id: 'geoapify-addresses',
    category: HelpCategory.services,
    question: 'Quem fornece as sugestões de endereço?',
    paragraphs: [
      'A busca e a identificação de endereços no mapa usam a Geoapify. As sugestões ajudam a localizar rua, cidade e coordenadas, mas podem não identificar um número ou acesso com precisão.',
      'Confira o número ou S/N, o complemento e o ponto no mapa antes de confirmar. Os créditos dos fornecedores de dados são exibidos junto aos endereços e mapas.',
    ],
    keywords: [
      'geoapify',
      'API',
      'autocomplete',
      'busca',
      'endereço errado',
      'pin',
    ],
    links: [
      HelpArticleLink('Conhecer a Geoapify', 'https://www.geoapify.com/'),
    ],
  ),
  HelpArticle(
    id: 'external-service-errors',
    category: HelpCategory.services,
    question: 'O mapa, a busca ou o catálogo não está funcionando. O que faço?',
    paragraphs: [
      'Confira sua conexão e tente novamente. Para recursos de posição, confira também o GPS e a permissão de localização. Se apenas um recurso continuar indisponível, pode haver uma falha temporária no serviço utilizado.',
      'Evite confirmar um endereço sem conferir o ponto ou repetir várias vezes uma solicitação cujo resultado ainda está pendente. Volte à corrida ou ao histórico para verificar o estado antes de tentar de novo.',
      'As integrações são administradas pelo Fretado. Você não precisa configurar tokens ou criar contas nos fornecedores para usar os recursos do app.',
    ],
    keywords: [
      'erro',
      'indisponível',
      'não abre',
      'mapbox',
      'carpedia',
      'geoapify',
      'internet',
      'tentar novamente',
    ],
  ),
];
