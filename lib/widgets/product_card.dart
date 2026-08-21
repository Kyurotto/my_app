import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final isMilktea = product.category.toLowerCase() == 'milktea';
    final isOutOfStock = product.isOutOfStock;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isOutOfStock ? null : onAddToCart,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFECE7DE),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryCoffee.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Image / Illustration Box
              Expanded(
                flex: 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isMilktea
                              ? [const Color(0xFFDBEAFE), const Color(0xFFBFDBFE)]
                              : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
                        ),
                      ),
                      child: Center(
                        child: Hero(
                          tag: 'product_${product.id}',
                          child: Icon(
                            isMilktea ? Icons.local_cafe_rounded : Icons.lunch_dining_rounded,
                            size: 40,
                            color: isMilktea
                                ? const Color(0xFF2563EB).withValues(alpha: 0.7)
                                : const Color(0xFFD97706).withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),

                    // Category Badge (Top Left)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isMilktea ? Icons.coffee_rounded : Icons.fastfood_rounded,
                              size: 10,
                              color: isMilktea ? AppTheme.milkTeaBlue : AppTheme.snackAmber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isMilktea ? 'Milk Tea' : 'Snack',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isMilktea ? AppTheme.milkTeaBlue : AppTheme.snackAmber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // "NEW" Badge (Top Right)
                    if (product.isNew)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.amberGold,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.amberGold.withValues(alpha: 0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryCoffee,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                    // Out of stock overlay
                    if (isOutOfStock)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: const BoxDecoration(
                                color: AppTheme.dangerRed,
                                borderRadius: BorderRadius.all(Radius.circular(6)),
                              ),
                              child: const Text(
                                'OUT OF STOCK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Product Information
              Expanded(
                flex: 9,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1B18),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),

                      // Price & Add to Cart Action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                              Text(
                                isOutOfStock
                                    ? '0 in stock'
                                    : '${product.stock} available',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: isOutOfStock
                                      ? AppTheme.dangerRed
                                      : (product.isLowStock
                                          ? const Color(0xFFD97706)
                                          : Colors.grey[500]),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: isOutOfStock
                                  ? Colors.grey[300]
                                  : AppTheme.amberGold,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isOutOfStock
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: AppTheme.amberGold.withValues(alpha: 0.35),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: isOutOfStock
                                  ? Colors.grey[500]
                                  : AppTheme.primaryCoffee,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
