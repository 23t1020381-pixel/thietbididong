//Giỏ hàng & Thanh toán
import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'models/product_model.dart';

class ShopCartPage extends StatefulWidget {
  final Map<int, int> cart;
  final VoidCallback onChanged;
  final VoidCallback onContinueShopping;

  const ShopCartPage({
    super.key,
    required this.cart,
    required this.onChanged,
    required this.onContinueShopping,
  });

  @override
  State<ShopCartPage> createState() => _ShopCartPageState();
}

class _ShopCartPageState extends State<ShopCartPage> {
  static const Color primaryNavy = Color(0xFF17365D);
  static const double shippingFee = 5000;
  static const double freeShippingThreshold = 500000;

  void changeQuantity(ShopProduct product, int change) {
    setState(() {
      final next = (widget.cart[product.id] ?? 0) + change;
      if (next <= 0) {
        widget.cart.remove(product.id);
      } else {
        widget.cart[product.id] = next;
      }
    });
    widget.onChanged();
  }

  void undoRemove(ShopProduct product, int quantity) {
    setState(() => widget.cart[product.id] = quantity);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<bool>(
      valueListenable: convertUsdToVnd,
      builder: (context, isVndMode, child) {
        final items = productCache.values
            .where((p) => (widget.cart[p.id] ?? 0) > 0)
            .toList();

        final subtotalVnd = items.fold<double>(
          0,
          (sum, p) => sum + toVnd(p) * (widget.cart[p.id] ?? 0),
        );

        final shipping =
            subtotalVnd == 0 || subtotalVnd >= freeShippingThreshold
            ? 0.0
            : shippingFee;
        final totalVnd = subtotalVnd + shipping;
        final progress = (subtotalVnd / freeShippingThreshold).clamp(0.0, 1.0);

        return Scaffold(
          appBar: AppBar(
            title: Text(tr('Giỏ hàng', 'Shopping Cart', '购物车')),
            actions: [
              TextButton.icon(
                onPressed: () {
                  convertUsdToVnd.value = !convertUsdToVnd.value;
                  saveAppSettings();
                },
                icon: const Icon(Icons.currency_exchange, color: Colors.white),
                label: Text(
                  isVndMode ? 'VNĐ' : 'USD',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          body: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: primaryNavy.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.shopping_cart_outlined,
                            size: 56,
                            color: isDark
                                ? const Color(0xFF64B5F6)
                                : primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          tr(
                            'Giỏ hàng của bạn đang trống',
                            'Your cart is empty',
                            '您的购物车是空的',
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr(
                            'Hãy chọn sản phẩm yêu thích để thêm vào giỏ nhé!',
                            'Pick your favorite items and add them to cart!',
                            '挑选您喜欢的商品加入购物车吧！',
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton.icon(
                          onPressed: widget.onContinueShopping,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.storefront_outlined),
                          label: Text(
                            tr('Tiếp tục mua sắm', 'Continue shopping', '继续购物'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                      color: isDark
                          ? const Color(0xFF182620)
                          : const Color(0xFFE8F5E9),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                subtotalVnd >= freeShippingThreshold
                                    ? Icons.check_circle_rounded
                                    : Icons.local_shipping_outlined,
                                size: 18,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  subtotalVnd >= freeShippingThreshold
                                      ? 'Chúc mừng! Đơn hàng được Miễn phí vận chuyển'
                                      : 'Mua thêm ${formatVnd(freeShippingThreshold - subtotalVnd)} để được Miễn phí ship',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.green.shade200
                                        : Colors.green.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: Colors.green.withValues(
                                alpha: 0.2,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final product = items[index];
                          final quantity = widget.cart[product.id] ?? 0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Dismissible(
                              key: ValueKey('cart-${product.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              onDismissed: (_) {
                                setState(() => widget.cart.remove(product.id));
                                widget.onChanged();
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Đã xóa ${product.name} khỏi giỏ hàng',
                                    ),
                                    action: SnackBarAction(
                                      label: 'HOÀN TÁC',
                                      onPressed: () =>
                                          undoRemove(product, quantity),
                                    ),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E222D)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.grey.shade200,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.2 : 0.04,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF282D3B)
                                            : const Color(0xFFF3F6FA),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: buildProductImage(
                                        product.image,
                                        width: 78,
                                        height: 78,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            product.isUsd
                                                ? '${formatVnd(toVnd(product))} (\$${product.price.toStringAsFixed(2)})'
                                                : formatVnd(product.price),
                                            style: const TextStyle(
                                              color: Color(0xFFE65100),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              _QuantityButton(
                                                icon: Icons.remove,
                                                isDark: isDark,
                                                onPressed: () =>
                                                    changeQuantity(product, -1),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                    ),
                                                child: Text(
                                                  '$quantity',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              _QuantityButton(
                                                icon: Icons.add,
                                                isDark: isDark,
                                                onPressed: () =>
                                                    changeQuantity(product, 1),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: tr('Xóa', 'Remove', '删除'),
                                      onPressed: () {
                                        final oldQuantity = quantity;
                                        setState(
                                          () => widget.cart.remove(product.id),
                                        );
                                        widget.onChanged();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Đã xóa ${product.name}',
                                                ),
                                                action: SnackBarAction(
                                                  label: 'HOÀN TÁC',
                                                  onPressed: () => undoRemove(
                                                    product,
                                                    oldQuantity,
                                                  ),
                                                ),
                                              ),
                                            );
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.redAccent,
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
                  ],
                ),
          bottomNavigationBar: items.isEmpty
              ? null
              : SafeArea(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 12,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CartPriceRow(
                          label: tr(
                            'Tiền hàng (quy đổi VNĐ)',
                            'Subtotal (VND)',
                            '商品小计 (VND)',
                          ),
                          value: formatVnd(subtotalVnd),
                        ),
                        const SizedBox(height: 7),
                        _CartPriceRow(
                          label: tr('Phí vận chuyển', 'Shipping fee', '运费'),
                          value: shipping == 0
                              ? tr('Miễn phí', 'Free', '免运费')
                              : formatVnd(shipping),
                          valueColor: shipping == 0 ? Colors.green : null,
                        ),
                        const Divider(height: 20),
                        _CartPriceRow(
                          label: tr('Tổng thanh toán', 'Total payment', '应付总额'),
                          value: formatVnd(totalVnd),
                          bold: true,
                          valueColor: const Color(0xFFE65100),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              await addNewOrder(totalVnd);
                              if (!mounted) return;
                              showMessage(
                                context,
                                'Thanh toán thành công ${formatVnd(totalVnd)}!',
                              );
                              setState(() => widget.cart.clear());
                              widget.onChanged();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryNavy,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${tr('Thanh toán', 'Checkout', '结算')} (${formatVnd(totalVnd)})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onPressed;
  const _QuantityButton({
    required this.icon,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        style: IconButton.styleFrom(
          backgroundColor: isDark
              ? const Color(0xFF282D3B)
              : const Color(0xFFF3F6FA),
          foregroundColor: isDark ? Colors.white : const Color(0xFF17365D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isDark ? Colors.white12 : Colors.grey.shade300,
            ),
          ),
        ),
      ),
    );
  }
}

class _CartPriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _CartPriceRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
              fontSize: bold ? 18 : 14,
            ),
          ),
        ),
      ],
    );
  }
}
