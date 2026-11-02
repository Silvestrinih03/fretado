import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/enums/home_profile.dart';
import '../../../profile/presentation/pages/terms_privacy_page.dart';
import '../../../profile/presentation/widgets/profile_widgets.dart';
import '../../data/help_articles.dart';

class HelpSupportPage extends StatefulWidget {
  final HomeProfileEnum profile;

  const HelpSupportPage({super.key, required this.profile});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final _searchController = TextEditingController();
  String _query = '';
  HelpCategory? _category;
  String? _expandedArticleId;

  @override
  void didUpdateWidget(covariant HelpSupportPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      _searchController.clear();
      _query = '';
      _category = null;
      _expandedArticleId = null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    setState(() {
      _query = '';
      _category = null;
      _expandedArticleId = null;
    });
  }

  Future<void> _openLink(HelpArticleLink link) async {
    final uri = Uri.tryParse(link.url);
    var opened = false;
    try {
      if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir a página. Tente novamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final articles = filterHelpArticles(
      profile: widget.profile,
      category: _category,
      query: _query,
    );
    final isDriver = widget.profile == HomeProfileEnum.driver;
    return Scaffold(
      backgroundColor: FretColors.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            const ProfileHeader(title: 'Ajuda e suporte'),
            Expanded(
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HelpIntroduction(isDriver: isDriver),
                          const SizedBox(height: 22),
                          TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) =>
                                FocusScope.of(context).unfocus(),
                            onChanged: (value) => setState(() {
                              _query = value;
                              _expandedArticleId = null;
                            }),
                            style: const TextStyle(
                              fontSize: 15,
                              color: FretColors.screenDark,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Buscar uma dúvida',
                              hintText: 'Ex.: cancelamento, nota, foto…',
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: FretColors.brandGoldDark,
                              ),
                              suffixIcon: _query.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Limpar busca',
                                      icon: const Icon(Icons.close_rounded),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _query = '';
                                          _expandedArticleId = null;
                                        });
                                      },
                                    ),
                              filled: true,
                              fillColor: FretColors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: FretColors.appBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: FretColors.appBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: FretColors.brandGoldDark,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Explore por assunto',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: FretColors.screenDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _categoryChip(null),
                              for (final category in HelpCategory.values)
                                _categoryChip(category),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              Text(
                                _category?.label ?? 'Dúvidas frequentes',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: FretColors.screenDark,
                                ),
                              ),
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  '${articles.length} ${articles.length == 1 ? 'resposta' : 'respostas'}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: FretColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (articles.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _EmptySearch(onClear: _clearFilters),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final article = articles[index];
                            return Padding(
                              key: ValueKey(article.id),
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _HelpArticleCard(
                                article: article,
                                expanded: _expandedArticleId == article.id,
                                onTap: () {
                                  FocusScope.of(context).unfocus();
                                  setState(
                                    () => _expandedArticleId =
                                        _expandedArticleId == article.id
                                        ? null
                                        : article.id,
                                  );
                                },
                                onOpenLink: _openLink,
                              ),
                            );
                          },
                          childCount: articles.length,
                          findChildIndexCallback: (key) {
                            if (key is! ValueKey<String>) return null;
                            final index = articles.indexWhere(
                              (article) => article.id == key.value,
                            );
                            return index < 0 ? null : index;
                          },
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const TermsPrivacyPage(),
                              ),
                            ),
                            icon: const Icon(
                              Icons.privacy_tip_outlined,
                              size: 18,
                            ),
                            label: const Text('Termos e privacidade'),
                            style: TextButton.styleFrom(
                              foregroundColor: FretColors.screenDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(HelpCategory? category) => ChoiceChip(
    label: Text(category?.label ?? 'Todos'),
    selected: _category == category,
    onSelected: (_) {
      FocusScope.of(context).unfocus();
      setState(() {
        _category = category;
        _expandedArticleId = null;
      });
    },
    selectedColor: FretColors.brandGoldSoft,
    backgroundColor: FretColors.white,
    labelStyle: TextStyle(
      fontSize: 12,
      fontWeight: _category == category ? FontWeight.w700 : FontWeight.w500,
      color: FretColors.screenDark,
    ),
    side: BorderSide(
      color: _category == category
          ? FretColors.brandGold
          : FretColors.appBorder,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    showCheckmark: false,
  );
}

class _HelpIntroduction extends StatelessWidget {
  final bool isDriver;
  const _HelpIntroduction({required this.isDriver});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: FretColors.screenDark,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.help_outline_rounded,
              color: FretColors.screenGold,
              size: 23,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                isDriver ? 'Ajuda para motoristas' : 'Ajuda para clientes',
                style: const TextStyle(
                  color: FretColors.brandGoldSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Como podemos ajudar?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -.6,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isDriver
              ? 'Da primeira oferta à entrega: entenda seus ganhos, a disponibilidade e as regras da corrida.'
              : 'Do endereço à entrega: entenda os valores, acompanhe seu frete e tire suas dúvidas.',
          style: const TextStyle(
            color: Color(0xFFD9D5CB),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

class _HelpArticleCard extends StatelessWidget {
  final HelpArticle article;
  final bool expanded;
  final VoidCallback onTap;
  final ValueChanged<HelpArticleLink> onOpenLink;
  const _HelpArticleCard({
    required this.article,
    required this.expanded,
    required this.onTap,
    required this.onOpenLink,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: FretColors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: expanded ? FretColors.brandGold : FretColors.appBorder,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: AnimatedSize(
      duration: const Duration(milliseconds: 180),
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            hint: expanded
                ? 'Toque para recolher a resposta'
                : 'Toque para abrir a resposta',
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        article.question,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: FretColors.screenDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedRotation(
                      turns: expanded ? .5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: expanded
                            ? FretColors.brandGoldDark
                            : FretColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 0, 17, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1, color: FretColors.appDivider),
                  for (final paragraph in article.paragraphs)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        paragraph,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: FretColors.textSecondary,
                        ),
                      ),
                    ),
                  for (final link in article.links)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => onOpenLink(link),
                        style: TextButton.styleFrom(
                          foregroundColor: FretColors.brandGoldDark,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.open_in_new_rounded, size: 16),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                link.label,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _EmptySearch extends StatelessWidget {
  final VoidCallback onClear;
  const _EmptySearch({required this.onClear});
  @override
  Widget build(BuildContext context) => ProfileSurface(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const Icon(
          Icons.search_off_rounded,
          size: 38,
          color: FretColors.brandGoldDark,
        ),
        const SizedBox(height: 14),
        const Text(
          'Nenhuma resposta encontrada',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: FretColors.screenDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tente outras palavras ou limpe os filtros para ver as dúvidas do seu perfil.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: FretColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Limpar filtros'),
          style: TextButton.styleFrom(
            foregroundColor: FretColors.brandGoldDark,
          ),
        ),
      ],
    ),
  );
}
