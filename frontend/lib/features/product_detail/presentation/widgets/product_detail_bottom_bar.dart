import 'package:flutter/material.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../app/theme/app_radius.dart';
import '../../../../../core/utils/price_formatter.dart';
import 'package:pet_food_app/l10n/app_localizations.dart';

/// 상품 상세 페이지 하단 고정 탭
class ProductDetailBottomBar extends StatelessWidget {
  final bool isFavorite;
  final int? lowestPrice; // 최저가
  final String? purchaseUrl;
  final VoidCallback onFavoriteTap;
  final VoidCallback? onPurchaseTap;

  const ProductDetailBottomBar({
    super.key,
    required this.isFavorite,
    this.lowestPrice,
    this.purchaseUrl,
    required this.onFavoriteTap,
    this.onPurchaseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 왼쪽: + 관심 버튼
              IconButton(
                onPressed: onFavoriteTap,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? AppColors.dangerRed : AppColors.textSecondary,
                  size: 28,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
              ),
              const SizedBox(width: 16),
              // 오른쪽: 최저가 구매하기 버튼
              Expanded(
                child: _buildPurchaseButton(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(BuildContext context) {
    final hasPrice = lowestPrice != null;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (onPurchaseTap != null) {
              onPurchaseTap!();
            } else if (purchaseUrl != null) {
              _launchPurchaseUrl(purchaseUrl!);
            }
          },
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasPrice)
                  Text(
                    AppLocalizations.of(context)!.productDetailWidget_buyAtLowest(PriceFormatter.formatCompactWithoutCurrency(lowestPrice!)),
                    style: AppTypography.button.copyWith(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  )
                else
                  Text(
                    AppLocalizations.of(context)!.productDetailWidget_buyNow,
                    style: AppTypography.button.copyWith(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _launchPurchaseUrl(String url) async {
    // TODO: url_launcher 패키지 추가 후 구현
    // final uri = Uri.parse(url);
    // if (await canLaunchUrl(uri)) {
    //   await launchUrl(uri, mode: LaunchMode.externalApplication);
    // }
    debugPrint('구매 링크: $url');
  }
}
