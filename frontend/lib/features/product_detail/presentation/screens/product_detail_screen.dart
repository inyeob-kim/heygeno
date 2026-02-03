import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../ui/widgets/app_scaffold.dart';
import '../../../../../ui/widgets/app_header.dart';
import '../../../../../ui/widgets/card_container.dart';
import '../../../../../ui/widgets/app_buttons.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_radius.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../core/widgets/loading.dart';
import '../../../../../core/providers/pet_id_provider.dart';
import '../controllers/product_detail_controller.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productDetailControllerProvider(widget.productId).notifier).loadProduct(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailControllerProvider(widget.productId));

    return AppScaffold(
      appBar: AppHeader(
        title: '상품 상세',
        showNotification: false,
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, ProductDetailState state) {
    if (state.isLoading) {
      return const LoadingWidget();
    }

    if (state.error != null && state.product == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.error!,
                style: AppTypography.body.copyWith(
                  color: AppColors.dangerRed,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.gridGap),
              AppPrimaryButton(
                text: '다시 시도',
                onPressed: () {
                  ref.read(productDetailControllerProvider(widget.productId).notifier).loadProduct(widget.productId);
                },
              ),
            ],
          ),
        ),
      );
    }

    final product = state.product;
    if (product == null) {
      return Center(
        child: Text(
          '상품 정보를 불러올 수 없습니다.',
          style: AppTypography.body,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.pagePaddingHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상품 이미지
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(AppRadius.media),
            ),
            child: const Icon(Icons.pets, size: 80, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // 상품명 (H2: 26px)
          Text(
            product.productName,
            style: AppTypography.h2,
          ),
          const SizedBox(height: AppSpacing.sm),
          // 브랜드명 (Body2: muted)
          Text(
            product.brandName,
            style: AppTypography.body2,
          ),
          if (product.sizeLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              product.sizeLabel!,
              style: AppTypography.body2,
            ),
          ],
          const SizedBox(height: AppSpacing.gridGap),
          
          // 가격 정보 카드
          CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // H3: 18px
                Text('가격 정보', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.gridGap),
                // Body: 16px
                Text(
                  '최근 14일 평균: 50,000원',
                  style: AppTypography.body,
                ),
                const SizedBox(height: 4),
                // Body: green
                Text(
                  '우리 아이에게 좋은 가격이에요',
                  style: AppTypography.body.copyWith(
                    color: AppColors.positiveGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gridGap),
          
          // 알림 설정/성공 메시지
          if (state.trackingCreated)
            CardContainer(
              backgroundColor: AppColors.positiveGreen.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.positiveGreen),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '가격 알림이 설정되었습니다',
                      style: AppTypography.body,
                    ),
                  ),
                ],
              ),
            )
          else
            AppPrimaryButton(
              text: '우리 아이 사료 가격 알림 받기',
              onPressed: state.isTrackingLoading
                  ? null
                  : () async {
                      final petId = ref.read(currentPetIdProvider);
                      if (petId == null) {
                        // TODO: 에러 처리 (프로필 먼저 등록하라는 메시지)
                        return;
                      }
                      await ref.read(productDetailControllerProvider(widget.productId).notifier).createTracking(
                            widget.productId,
                            petId,
                          );
                    },
            ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.gridGap),
              child: Text(
                state.error!,
                style: AppTypography.body.copyWith(
                  color: AppColors.dangerRed,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
