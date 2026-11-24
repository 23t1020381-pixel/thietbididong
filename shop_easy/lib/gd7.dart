//Chi tiết sản phẩm
import 'package:flutter/material.dart';

import 'api.dart';
import 'config/app_config.dart';
import 'models/product_model.dart';

class ShopProductDetailPage extends StatefulWidget {
  final ShopProduct product;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final void Function(int) onAddCart;
  final void Function(int)? onBuyNow;

  const ShopProductDetailPage({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onFavorite,
    required this.onAddCart,
    this.onBuyNow,
  });

  @override
  State<ShopProductDetailPage> createState() => _ShopProductDetailPageState();
}

class _ShopProductDetailPageState extends State<ShopProductDetailPage> {
  late ShopProduct currentProduct;
  bool isLoadingDetail = false;
  int quantity = 1;
  int currentImage = 0;
  late bool favorite;
  bool showFullDescription = false;
  final PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    currentProduct = widget.product;
    favorite = widget.isFavorite;
    if (widget.product.id > 0) {
      fetchProductDetail();
    }
  }

  Future<void> fetchProductDetail() async {
    setState(() => isLoadingDetail = true);
    try {
      final response = await dio.get('/products/${widget.product.id}');
      if (mounted) {
        final detailed = ShopProduct.fromJson(response.data);
        productCache[detailed.id] = detailed;
        setState(() {
          currentProduct = detailed;
          isLoadingDetail = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoadingDetail = false);
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  List<String> get productImages {
    if (currentProduct.images.isNotEmpty) {
      return currentProduct.images;
    }
    return [currentProduct.image];
  }

  Widget stars(double rating, {double size = 18}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (i) {
      final n = i + 1;
      final icon = rating >= n
          ? Icons.star_rounded
          : rating >= n - .5
          ? Icons.star_half_rounded
          : Icons.star_border_rounded;
      return Icon(icon, color: Colors.amber, size: size);
    }),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = currentProduct;
    final images = productImages;
    final description = p.description;
    final canExpand = description.length > 90;
    final shownDescription = showFullDescription || !canExpand
        ? description
        : '${description.substring(0, 90)}...';

    final hasDiscount = p.oldPrice > p.price && p.oldPrice > 0;
    final discountPercent = hasDiscount
        ? (100 * (p.oldPrice - p.price) / p.oldPrice).round()
        : 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 350,
            leadingWidth: 64,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
              child: _floatingImageButton(
                icon: Icons.arrow_back,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            title: Text(tr('Chi tiết sản phẩm', 'Product Details', '商品详情')),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12, top: 6, bottom: 6),
                child: _floatingImageButton(
                  icon: favorite ? Icons.favorite : Icons.favorite_border,
                  iconColor: const Color(0xFFFF4081),
                  onPressed: () {
                    widget.onFavorite();
                    setState(() => favorite = !favorite);
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: isDark
                    ? const Color(0xFF282D3B)
                    : const Color(0xFFF3F6FA),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      controller: pageController,
                      physics: const PageScrollPhysics(),
                      itemCount: images.length,
                      onPageChanged: (index) =>
                          setState(() => currentImage = index),
                      itemBuilder: (context, index) {
                        final img = buildProductImage(
                          images[index],
                          fit: BoxFit.contain,
                        );
                        if (index == 0) {
                          return Hero(tag: 'product-${p.id}', child: img);
                        }
                        return img;
                      },
                    ),
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.42),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(images.length, (index) {
                              final selected = currentImage == index;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: selected ? 18 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.white
                                      : Colors.white60,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoadingDetail) const LinearProgressIndicator(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.teal,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      stars(p.rating),
                      const SizedBox(width: 8),
                      Text(
                        '${p.rating}/5',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '(${p.reviewCount} ${tr('đánh giá', 'reviews', '条评价')})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E222D) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                    ),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        Text(
                          formatProductPrice(p),
                          style: const TextStyle(
                            color: Color(0xFFE65100),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (hasDiscount) ...[
                          Text(
                            formatProductOldPrice(p),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          if (discountPercent > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '-$discountPercent%',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr('Mô tả sản phẩm', 'Description', '商品描述'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(shownDescription, style: const TextStyle(height: 1.55)),
                  if (canExpand)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => setState(
                          () => showFullDescription = !showFullDescription,
                        ),
                        child: Text(
                          showFullDescription
                              ? tr('Thu gọn', 'Show less', '收起')
                              : tr('Xem thêm', 'Read more', '展开'),
                        ),
                      ),
                    ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr('Đánh giá sản phẩm', 'Reviews', '商品评价'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${p.rating}/5 ⭐',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...p.reviews.map(
                    (r) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF17365D)
                                      .withValues(alpha: 0.15),
                                  child: Text(
                                    r.name.isEmpty ? '?' : r.name[0],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        r.date,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                stars(r.rating, size: 16),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(r.comment),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (quantity > 1) setState(() => quantity--);
                      },
                      icon: const Icon(Icons.remove, size: 18),
                    ),
                    Text(
                      '$quantity',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => setState(() => quantity++),
                      icon: const Icon(Icons.add, size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => widget.onAddCart(quantity),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: isDark
                        ? const Color(0xFF64B5F6)
                        : const Color(0xFF17365D),
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF64B5F6)
                          : const Color(0xFF17365D),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tr('Thêm giỏ', 'Add to cart', '加入购物车'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.onBuyNow != null) {
                      widget.onBuyNow!(quantity);
                    } else {
                      widget.onAddCart(quantity);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tr('Mua ngay', 'Buy now', '立即购买'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _floatingImageButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color iconColor = Colors.black87,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor),
      ),
    );
  }
}
