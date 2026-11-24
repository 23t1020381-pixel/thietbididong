//Trang chủ & Yêu thích
import 'package:flutter/material.dart';

import 'api.dart';
import 'config/app_config.dart';
import 'gd11.dart';
import 'gd3.dart';
import 'gd4.dart';
import 'gd5.dart';
import 'gd7.dart';
import 'gd8.dart';
import 'models/product_model.dart';

class ShopHomePage extends StatefulWidget {
  const ShopHomePage({super.key});

  @override
  State<ShopHomePage> createState() => _ShopHomePageState();
}

class _ShopHomePageState extends State<ShopHomePage> {
  int tab = 0;
  String category = 'Tất cả';
  String searchText = '';
  int bannerIndex = 0;
  final Set<int> favorites = {};
  final Map<int, int> cart = {};

  List<ShopProduct> allProducts = [...localProducts];
  bool isLoadingApi = true;

  final int pageSize = 30;
  int currentSkip = 0;
  int totalApiProducts = 0;
  bool isLoadingMore = false;
  bool hasMoreApiProducts = true;

  final TextEditingController searchController = TextEditingController();
  final PageController bannerController = PageController();

  @override
  void initState() {
    super.initState();
    fetchProductsFromApi();
  }

  @override
  void dispose() {
    searchController.dispose();
    bannerController.dispose();
    super.dispose();
  }

  void _hideSystemKeyboard() {
    FocusScope.of(context).unfocus();
  }

  int get totalCartCount =>
      cart.values.fold<int>(0, (sum, quantity) => sum + quantity);

  Future<void> fetchProductsFromApi([String query = '']) async {
    final trimmedQuery = query.trim();
    setState(() {
      isLoadingApi = true;
      currentSkip = 0;
      hasMoreApiProducts = trimmedQuery.isEmpty;
    });

    try {
      final response = trimmedQuery.isEmpty
          ? await dio.get(
              '/products',
              queryParameters: {'limit': pageSize, 'skip': 0},
            )
          : await dio.get(
              '/products/search',
              queryParameters: {'q': trimmedQuery, 'limit': 0},
            );

      final List danhSachJson = response.data['products'] ?? [];
      final int totalFromApi = (response.data['total'] as num?)?.toInt() ?? 0;

      final List<ShopProduct> apiItems = danhSachJson
          .map((json) => ShopProduct.fromJson(json))
          .toList();

      final matchingLocal = trimmedQuery.isEmpty
          ? localProducts
          : localProducts
                .where(
                  (p) =>
                      p.name.toLowerCase().contains(trimmedQuery.toLowerCase()),
                )
                .toList();

      setState(() {
        totalApiProducts = totalFromApi;
        allProducts = [...matchingLocal, ...apiItems];
        shopProducts = allProducts;
        cacheProducts(allProducts);

        if (trimmedQuery.isNotEmpty ||
            apiItems.length < pageSize ||
            (totalApiProducts > 0 && apiItems.length >= totalApiProducts)) {
          hasMoreApiProducts = false;
        }
      });
    } catch (_) {
      setState(() {
        allProducts = [...localProducts];
        shopProducts = allProducts;
        cacheProducts(allProducts);
        hasMoreApiProducts = false;
      });
    } finally {
      if (mounted) setState(() => isLoadingApi = false);
    }
  }

  Future<void> loadMoreProductsFromApi() async {
    if (isLoadingMore ||
        isLoadingApi ||
        !hasMoreApiProducts ||
        searchController.text.trim().isNotEmpty) {
      return;
    }

    setState(() => isLoadingMore = true);
    final nextSkip = currentSkip + pageSize;

    try {
      final response = await dio.get(
        '/products',
        queryParameters: {'limit': pageSize, 'skip': nextSkip},
      );

      final List danhSachJson = response.data['products'] ?? [];
      final int totalFromApi =
          (response.data['total'] as num?)?.toInt() ?? totalApiProducts;

      final List<ShopProduct> moreItems = danhSachJson
          .map((json) => ShopProduct.fromJson(json))
          .toList();

      final existingIds = allProducts.map((e) => e.id).toSet();
      final uniqueNewItems = moreItems
          .where((e) => !existingIds.contains(e.id))
          .toList();

      setState(() {
        currentSkip = nextSkip;
        totalApiProducts = totalFromApi;
        allProducts = [...allProducts, ...uniqueNewItems];
        shopProducts = allProducts;
        cacheProducts(uniqueNewItems);

        final loadedApiCount = allProducts.where((p) => p.id > 0).length;
        if (moreItems.isEmpty ||
            moreItems.length < pageSize ||
            (totalApiProducts > 0 && loadedApiCount >= totalApiProducts)) {
          hasMoreApiProducts = false;
        }
      });
    } catch (_) {
      if (mounted) {
        showMessage(
          context,
          tr(
            'Không thể tải thêm sản phẩm, vui lòng thử lại.',
            'Failed to load more products, please try again.',
            '无法加载更多商品，请重试。',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoadingMore = false);
    }
  }

  List<ShopProduct> get visibleProducts {
    Iterable<ShopProduct> result = allProducts;
    if (category != 'Tất cả') {
      if (category == 'API DummyJSON') {
        result = result.where((p) => p.id > 0);
      } else {
        result = result.where((p) => p.category == category);
      }
    }
    if (searchText.isNotEmpty) {
      result = result.where(
        (p) => p.name.toLowerCase().contains(searchText.toLowerCase()),
      );
    }
    return result.toList();
  }

  void addCart(ShopProduct p, [int quantity = 1]) {
    productCache[p.id] = p;
    setState(() => cart[p.id] = (cart[p.id] ?? 0) + quantity);
    showMessage(
      context,
      tr(
        'Đã thêm ${p.name} (x$quantity) vào giỏ hàng.',
        'Added ${p.name} (x$quantity) to cart.',
        '已将 ${p.name} (x$quantity) 加入购物车。',
      ),
    );
  }

  void openProduct(ShopProduct p) {
    _hideSystemKeyboard();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopProductDetailPage(
          product: p,
          isFavorite: favorites.contains(p.id),
          onFavorite: () {
            setState(() {
              if (favorites.contains(p.id)) {
                favorites.remove(p.id);
              } else {
                favorites.add(p.id);
              }
            });
          },
          onAddCart: (quantity) => addCart(p, quantity),
          onBuyNow: (quantity) {
            addCart(p, quantity);
            Navigator.pop(context);
            _onChangeTab(1);
          },
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _onChangeTab(int index) {
    if (index != 0) {
      _hideSystemKeyboard();
    }
    setState(() => tab = index);
  }

  Widget _cartBadgeIcon({required bool selected}) {
    final count = totalCartCount;
    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : '$count'),
      child: Icon(
        selected ? Icons.shopping_cart : Icons.shopping_cart_outlined,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (context, language, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: convertUsdToVnd,
          builder: (context, isVndMode, child) {
            final pages = [
              _buildHomeContent(),
              ShopCartPage(
                cart: cart,
                onChanged: () => setState(() {}),
                onContinueShopping: () => _onChangeTab(0),
              ),
              const SettingsPage(),
            ];

            return Scaffold(
              body: isDesktop
                  ? Row(
                      children: [
                        NavigationRail(
                          selectedIndex: tab,
                          onDestinationSelected: _onChangeTab,
                          labelType: NavigationRailLabelType.all,
                          destinations: [
                            NavigationRailDestination(
                              icon: const Icon(Icons.home_outlined),
                              selectedIcon: const Icon(Icons.home),
                              label: Text(tr('Trang chủ', 'Home', '首页')),
                            ),
                            NavigationRailDestination(
                              icon: _cartBadgeIcon(selected: false),
                              selectedIcon: _cartBadgeIcon(selected: true),
                              label: Text(tr('Giỏ hàng', 'Cart', '购物车')),
                            ),
                            NavigationRailDestination(
                              icon: const Icon(Icons.settings_outlined),
                              selectedIcon: const Icon(Icons.settings),
                              label: Text(tr('Cài đặt', 'Settings', '设置')),
                            ),
                          ],
                        ),
                        const VerticalDivider(thickness: 1, width: 1),
                        Expanded(
                          child: IndexedStack(index: tab, children: pages),
                        ),
                      ],
                    )
                  : IndexedStack(index: tab, children: pages),
              bottomNavigationBar: isDesktop
                  ? null
                  : NavigationBar(
                      selectedIndex: tab,
                      onDestinationSelected: _onChangeTab,
                      destinations: [
                        NavigationDestination(
                          icon: const Icon(Icons.home_outlined),
                          selectedIcon: const Icon(Icons.home),
                          label: tr('Trang chủ', 'Home', '首页'),
                        ),
                        NavigationDestination(
                          icon: _cartBadgeIcon(selected: false),
                          selectedIcon: _cartBadgeIcon(selected: true),
                          label: tr('Giỏ hàng', 'Cart', '购物车'),
                        ),
                        NavigationDestination(
                          icon: const Icon(Icons.settings_outlined),
                          selectedIcon: const Icon(Icons.settings),
                          label: tr('Cài đặt', 'Settings', '设置'),
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildPromoBanner(double fontScale) {
    final slides = [
      (
        title: tr('Miễn phí vận chuyển', 'Free Shipping', '全场满额免运费'),
        subtitle: tr(
          'Áp dụng cho mọi đơn hàng từ 500.000 đ',
          'Valid on all orders from 500,000 VND',
          '订单满 500,000 đ 即享免邮',
        ),
        icon: Icons.local_shipping_rounded,
        colors: const [Color(0xFF17365D), Color(0xFF2878D0)],
      ),
      (
        title: tr('Kho hàng quốc tế API', 'Global API Catalog', '全球好物精选'),
        subtitle: tr(
          'Tự động quy đổi USD sang VNĐ minh bạch',
          'Transparent USD to VND auto-conversion',
          '自动透明换算美元与越南盾',
        ),
        icon: Icons.currency_exchange_rounded,
        colors: const [Color(0xFF0F766E), Color(0xFF14B8A6)],
      ),
      (
        title: tr('Ưu đãi thành viên mới', 'New Member Deals', '新会员专享礼遇'),
        subtitle: tr(
          'Giảm đến 25% cho phụ kiện & thời trang',
          'Up to 25% off accessories & fashion',
          '配饰与时尚单品低至75折',
        ),
        icon: Icons.local_offer_rounded,
        colors: const [Color(0xFFB45309), Color(0xFFF59E0B)],
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 126 * fontScale,
          child: PageView.builder(
            controller: bannerController,
            itemCount: slides.length,
            onPageChanged: (index) => setState(() => bannerIndex = index),
            itemBuilder: (context, index) {
              final slide = slides[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: slide.colors,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: slide.colors.first.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            slide.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            slide.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(slide.icon, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (index) {
            final active = bannerIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF17365D)
                    : Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHomeContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = visibleProducts;
    final loadedApiCount = allProducts.where((p) => p.id > 0).length;
    final fontScale = (appFontSize.value / 16).clamp(0.85, 1.5);
    final gridAspectRatio = (0.68 / fontScale).clamp(0.46, 0.74);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ShopEasy',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        actions: [
          IconButton(
            tooltip: tr('Tổng quan', 'Dashboard', '仪表盘'),
            icon: const Icon(Icons.dashboard_outlined),
            onPressed: () {
              _hideSystemKeyboard();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DashboardPage()),
              );
            },
          ),
          IconButton(
            tooltip: tr('Sản phẩm yêu thích', 'Favorites', '我的收藏'),
            icon: Badge(
              isLabelVisible: favorites.isNotEmpty,
              label: Text('${favorites.length}'),
              child: const Icon(Icons.favorite, color: Color(0xFFFF4081)),
            ),
            onPressed: () {
              _hideSystemKeyboard();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShopFavoritesPage(
                    favorites: favorites,
                    onToggleFavorite: (product) {
                      setState(() {
                        if (favorites.contains(product.id)) {
                          favorites.remove(product.id);
                        } else {
                          favorites.add(product.id);
                        }
                      });
                    },
                    onOpenProduct: (product) => openProduct(product),
                  ),
                ),
              ).then((_) {
                if (mounted) setState(() {});
              });
            },
          ),
          IconButton(
            tooltip: tr('Trang cá nhân', 'Profile', '个人主页'),
            icon: const Icon(Icons.account_circle, size: 28),
            onPressed: () {
              _hideSystemKeyboard();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => searchText = v),
              onSubmitted: (v) {
                setState(() => category = 'Tất cả');
                fetchProductsFromApi(v);
                _hideSystemKeyboard();
              },
              decoration: InputDecoration(
                hintText: tr(
                  'Tìm kiếm sản phẩm...',
                  'Search products...',
                  '搜索商品...',
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                        tooltip: tr('Xóa từ khóa', 'Clear', '清除'),
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchText = '';
                            category = 'Tất cả';
                          });
                          fetchProductsFromApi('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF1E222D) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
              ),
            ),
          ),
          if (isLoadingApi) const LinearProgressIndicator(),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _hideSystemKeyboard,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  int crossAxisCount = 2;
                  if (width >= 900) {
                    crossAxisCount = 4;
                  } else if (width >= 600) {
                    crossAxisCount = 3;
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 4, bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (searchText.isEmpty) ...[
                          _buildPromoBanner(fontScale),
                          const SizedBox(height: 10),
                        ],
                        SizedBox(
                          height: 46 * fontScale,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            children:
                                [
                                      'Tất cả',
                                      'API DummyJSON',
                                      'Điện tử',
                                      'Thời trang',
                                      'Phụ kiện',
                                    ]
                                    .map(
                                      (c) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: ChoiceChip(
                                          label: Text(c),
                                          selected: category == c,
                                          onSelected: (_) =>
                                              setState(() => category = c),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tr(
                                    'Sản phẩm nổi bật',
                                    'Featured Products',
                                    '精选商品',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                totalApiProducts > 0 && searchText.isEmpty
                                    ? '${items.length} SP ($loadedApiCount/$totalApiProducts)'
                                    : '${items.length} SP',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: Center(
                              child: Text(
                                tr(
                                  'Không tìm thấy sản phẩm.',
                                  'No products found.',
                                  '未找到商品。',
                                ),
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: gridAspectRatio,
                                  ),
                              itemBuilder: (context, index) {
                                final p = items[index];
                                final fav = favorites.contains(p.id);
                                return ShopProductCard(
                                  product: p,
                                  isFavorite: fav,
                                  onOpenProduct: () => openProduct(p),
                                  onToggleFavorite: () => setState(() {
                                    if (fav) {
                                      favorites.remove(p.id);
                                    } else {
                                      favorites.add(p.id);
                                    }
                                  }),
                                  onAddToCart: () => addCart(p),
                                );
                              },
                            ),
                          ),
                        if (searchText.isEmpty &&
                            (category == 'Tất cả' ||
                                category == 'API DummyJSON'))
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 18,
                                bottom: 8,
                              ),
                              child: isLoadingMore
                                  ? Column(
                                      children: [
                                        const CircularProgressIndicator(),
                                        const SizedBox(height: 8),
                                        Text(
                                          tr(
                                            'Đang tải thêm sản phẩm...',
                                            'Loading more products...',
                                            '正在加载更多商品...',
                                          ),
                                        ),
                                      ],
                                    )
                                  : hasMoreApiProducts
                                  ? ElevatedButton.icon(
                                      onPressed: loadMoreProductsFromApi,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF17365D,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 22,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(Icons.expand_more),
                                      label: Text(
                                        totalApiProducts > 0
                                            ? 'Xem thêm (+$pageSize) • $loadedApiCount/$totalApiProducts'
                                            : 'Xem thêm (+$pageSize)',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Đã hiển thị tất cả $loadedApiCount sản phẩm từ API',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShopFavoritesPage extends StatefulWidget {
  final Set<int> favorites;
  final void Function(ShopProduct) onToggleFavorite;
  final void Function(ShopProduct) onOpenProduct;

  const ShopFavoritesPage({
    super.key,
    required this.favorites,
    required this.onToggleFavorite,
    required this.onOpenProduct,
  });

  @override
  State<ShopFavoritesPage> createState() => _ShopFavoritesPageState();
}

class _ShopFavoritesPageState extends State<ShopFavoritesPage> {
  @override
  Widget build(BuildContext context) {
    final items = productCache.values
        .where((product) => widget.favorites.contains(product.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Sản phẩm yêu thích', 'Favorite Products', '收藏的商品')),
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr(
                      'Bạn chưa có sản phẩm yêu thích.',
                      'You have no favorite products yet.',
                      '您还没有收藏的商品。',
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final product = items[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: SizedBox(
                      width: 56,
                      height: 56,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: buildProductImage(product.image),
                      ),
                    ),
                    title: Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      formatProductPrice(product),
                      style: const TextStyle(
                        color: Color(0xFFE65100),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => widget.onOpenProduct(product),
                    trailing: IconButton(
                      tooltip: tr('Bỏ yêu thích', 'Remove favorite', '取消收藏'),
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () {
                        widget.onToggleFavorite(product);
                        setState(() {});
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
