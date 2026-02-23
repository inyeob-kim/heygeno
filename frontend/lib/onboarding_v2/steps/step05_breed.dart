import 'package:flutter/material.dart';
import '../onboarding_shell.dart';
import '../../ui/widgets/figma_search_bar.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

/// Step 5: Breed (Dog & Cat) - DESIGN_GUIDE v1.0 준수
class Step05Breed extends StatefulWidget {
  final String value;
  final String species; // 'dog' | 'cat'
  final ValueChanged<String> onUpdate;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final int currentStep;
  final int totalSteps;

  const Step05Breed({
    super.key,
    required this.value,
    required this.species,
    required this.onUpdate,
    required this.onNext,
    required this.onBack,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  State<Step05Breed> createState() => _Step05BreedState();
}

class _Step05BreedState extends State<Step05Breed> {
  late TextEditingController _searchController;

  // 대표적인 강아지 품종 목록 (확장)
  static const List<String> _dogBreeds = [
    '골든리트리버',
    '래브라도리트리버',
    '비글',
    '불독',
    '푸들',
    '치와와',
    '요크셔테리어',
    '시추',
    '포메라니안',
    '말티즈',
    '비숑프리제',
    '웰시코기',
    '허스키',
    '진돗개',
    '도베르만',
    '로트와일러',
    '저먼셰퍼드',
    '보더콜리',
    '잭러셀테리어',
    '닥스훈트',
    '샤페이',
    '시바견',
    '아키타',
    '코카스파니엘',
    '미니어처슈나우저',
    '보스턴테리어',
    '프렌치불독',
    '퍼그',
    '보더테리어',
    '스코티시테리어',
    '웨스트하이랜드화이트테리어',
    '스탠다드푸들',
    '미니어처푸들',
    '토이푸들',
    '믹스',
  ];

  // 대표적인 고양이 품종 목록 (확장)
  static const List<String> _catBreeds = [
    '페르시안',
    '러시안블루',
    '브리티시숏헤어',
    '아메리칸숏헤어',
    '메인쿤',
    '노르웨이숲고양이',
    '스코티시폴드',
    '랙돌',
    '버만',
    '샴',
    '터키시앙고라',
    '아비시니안',
    '벵갈',
    '이집션마우',
    '스핑크스',
    '먼치킨',
    '아메리칸컬',
    '스코티시스트레이트',
    '엑조틱숏헤어',
    '히말라얀',
    '버미즈',
    '오리엔탈',
    '데본렉스',
    '코니시렉스',
    '셀커크렉스',
    '라가머핀',
    '맹크스',
    '아메리칸밥테일',
    '일본꼬리',
    '믹스',
  ];

  List<String> get _popularBreeds {
    return widget.species == 'cat' ? _catBreeds : _dogBreeds;
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get isValid => _searchController.text.trim().isNotEmpty;

  void _onSearchChanged(String value) {
    widget.onUpdate(value);
    setState(() {}); // isValid 업데이트를 위해
  }

  void _onBreedTagTap(String breed) {
    _searchController.text = breed;
    widget.onUpdate(breed);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      currentStep: widget.currentStep,
      totalSteps: widget.totalSteps,
      onBack: widget.onBack,
      emoji: widget.species == 'cat' ? '🐱' : '🐶',
      title: AppLocalizations.of(context)!.onboarding_step5_title,
      ctaText: AppLocalizations.of(context)!.common_next,
      ctaDisabled: !isValid,
      onCTAClick: widget.onNext,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.onboarding_step5_label,
            style: AppTypography.small.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FigmaSearchBar(
            controller: _searchController,
            placeholder: AppLocalizations.of(context)!.onboarding_step5_placeholder,
            onSearch: _onSearchChanged,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            AppLocalizations.of(context)!.onboarding_step5_popularBreeds,
            style: AppTypography.small.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs + 2,
            runSpacing: AppSpacing.xs + 2,
            alignment: WrapAlignment.start,
            children: _popularBreeds.asMap().entries.map((entry) {
              final index = entry.key;
              final breed = entry.value;
              final isSelected = _searchController.text.trim() == breed;
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 200 + (index * 30)),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.9 + (0.1 * value.clamp(0.0, 1.0)),
                      child: _CompactBreedChip(
                        label: breed,
                        selected: isSelected,
                        onTap: () => _onBreedTagTap(breed),
                      ),
                    ),
                  );
                },
                child: const SizedBox.shrink(),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 컴팩트한 품종 태그 위젯 - DESIGN_GUIDE v1.0 준수
class _CompactBreedChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CompactBreedChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(
            minHeight: 32,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryBlue // 결정/이동용
                : AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: selected
                  ? AppColors.primaryBlue
                  : AppColors.divider,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.small.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected
                  ? Colors.white
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
