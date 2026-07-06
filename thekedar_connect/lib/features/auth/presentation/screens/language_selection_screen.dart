import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/localization/locale_provider.dart';
import 'package:thekedar_connect/l10n/app_localizations.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  final bool isFromSettings;

  const LanguageSelectionScreen({
    super.key,
    this.isFromSettings = false,
  });

  @override
  ConsumerState<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen> {
  String _searchQuery = '';
  LanguageModel? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    // Pre-select the current language on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentLocale = ref.read(localeProvider).locale.languageCode;
      setState(() {
        _selectedLanguage = languageList.firstWhere(
          (lang) => lang.code == currentLocale,
          orElse: () => languageList.first,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeState = ref.watch(localeProvider);

    final filteredLanguages = languageList.where((lang) {
      final query = _searchQuery.trim().toLowerCase();
      return lang.englishName.toLowerCase().contains(query) ||
          lang.nativeName.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: widget.isFromSettings
          ? AppBar(
              backgroundColor: AppColors.darkSurface,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
                onPressed: () => context.pop(),
              ),
              title: Text(
                l10n.changeLanguage,
                style: AppTypography.title.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.isFromSettings) ...[
                const SizedBox(height: AppSpacing.xxl),
                // Logo & Welcome Header
                Center(
                  child: Hero(
                    tag: 'app_logo',
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 70,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.construction,
                        color: AppColors.primary,
                        size: 70,
                      ),
                    ),
                  ),
                ).animate().fade(duration: 400.ms).scale(delay: 100.ms),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.appName,
                  textAlign: TextAlign.center,
                  style: AppTypography.headline.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.chooseLanguage,
                  textAlign: TextAlign.center,
                  style: AppTypography.subtitle.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ).animate().fade(delay: 200.ms),
              ] else ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.chooseLanguage,
                  style: AppTypography.subtitle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),

              // Search Bar
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.searchLanguages,
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Language List
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredLanguages.length,
                  itemBuilder: (context, index) {
                    final lang = filteredLanguages[index];
                    final isSelected = _selectedLanguage?.code == lang.code;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedLanguage = lang;
                          });
                          // Hot dynamic translation change
                          ref.read(localeProvider.notifier).setLocale(Locale(lang.code), source: 'manual');
                        },
                        child: AnimatedContainer(
                          duration: 250.ms,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.darkCard,
                            borderRadius: BorderRadius.circular(AppRadius.large),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.darkBorder,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))]
                                : AppShadows.darkCardShadow,
                          ),
                          child: Row(
                            children: [
                              Text(
                                lang.flag,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang.nativeName,
                                      style: AppTypography.body.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      lang.englishName,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                  size: 22,
                                )
                              else
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.textMuted.withOpacity(0.4), width: 1.5),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Button Row
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  children: [
                    if (!widget.isFromSettings)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Defaults to English
                            ref.read(localeProvider.notifier).setLocale(const Locale('en'), source: 'device');
                            context.go('/welcome');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.darkBorder),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
                          ),
                          child: Text(l10n.skipButton, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    if (!widget.isFromSettings) const SizedBox(width: 12),
                    Expanded(
                      flex: widget.isFromSettings ? 1 : 2,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: AppGradients.primaryGradient,
                          borderRadius: AppRadius.buttonBorderRadius,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (_selectedLanguage != null) {
                              ref.read(localeProvider.notifier).setLocale(
                                    Locale(_selectedLanguage!.code),
                                    source: 'manual',
                                  );
                            }
                            if (widget.isFromSettings) {
                              context.pop();
                            } else {
                              context.go('/welcome');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorderRadius),
                          ),
                          child: Text(
                            widget.isFromSettings ? l10n.continueButton : l10n.continueButton,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
