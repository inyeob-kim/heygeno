import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../onboarding_shell.dart';
import '../widgets/selection_card.dart';
import '../widgets/toss_text_input.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';

/// Step 4: Age - matches React Step4Age
class Step04Age extends StatelessWidget {
  final String ageType; // 'birthdate' | 'approximate' | ''
  final String birthdate;
  final String approximateAge;
  final ValueChanged<Map<String, dynamic>> onUpdate;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final int currentStep;
  final int totalSteps;

  const Step04Age({
    super.key,
    required this.ageType,
    required this.birthdate,
    required this.approximateAge,
    required this.onUpdate,
    required this.onNext,
    required this.onBack,
    required this.currentStep,
    required this.totalSteps,
  });

  bool get isValid {
    return (ageType == 'birthdate' && birthdate.isNotEmpty) ||
        (ageType == 'approximate' && approximateAge.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      currentStep: currentStep,
      totalSteps: totalSteps,
      onBack: onBack,
      emoji: '🎂',
      title: '나이를 어떻게 알려주실래요?',
      ctaText: '다음',
      ctaDisabled: !isValid,
      onCTAClick: onNext,
      child: Column(
        children: [
          SelectionCard(
            selected: ageType == 'birthdate',
            onTap: () => onUpdate({'ageType': 'birthdate'}),
            emoji: '📅',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '생년월일 알아요',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (ageType == 'birthdate') ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: _buildDatePicker(context),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SelectionCard(
            selected: ageType == 'approximate',
            onTap: () => onUpdate({'ageType': 'approximate'}),
            emoji: '🎈',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '대략 나이만',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (ageType == 'approximate') ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: TossTextInput(
                value: approximateAge,
                onChanged: (val) => onUpdate({'approximateAge': val}),
                placeholder: '예: 2살 3개월',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    DateTime? selectedDate;
    if (birthdate.isNotEmpty) {
      selectedDate = DateTime.tryParse(birthdate);
    }
    final initialDate = selectedDate ?? DateTime.now().subtract(const Duration(days: 365));

    return GestureDetector(
      onTap: () {
        DateTime? tempSelectedDate = initialDate;
        
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) => DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              builder: (context, scrollController) => Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 드래그 핸들
                      Container(
                        margin: const EdgeInsets.only(
                          top: AppSpacing.md,
                          bottom: AppSpacing.sm,
                        ),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                      // 헤더 (취소/완료 버튼)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                '취소',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '생년월일 선택',
                              style: AppTypography.h3.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                if (tempSelectedDate != null) {
                                  onUpdate({'birthdate': tempSelectedDate!.toIso8601String().split('T')[0]});
                                }
                                Navigator.pop(context);
                              },
                              child: Text(
                                '완료',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.divider,
                      ),
                      
                      // 날짜 선택기
                      Expanded(
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.date,
                          maximumDate: DateTime.now(),
                          minimumDate: DateTime.now().subtract(const Duration(days: 7300)), // ~20 years
                          initialDateTime: initialDate,
                          onDateTimeChanged: (date) {
                            tempSelectedDate = date;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.divider,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                birthdate.isEmpty ? '생년월일을 선택해주세요' : birthdate,
                style: AppTypography.body.copyWith(
                  color: birthdate.isEmpty
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: AppColors.iconMuted,
            ),
          ],
        ),
      ),
    );
  }
}
