//Mô hình dữ liệu
class ShopReview {
  final String name;
  final double rating;
  final String date;
  final String comment;

  const ShopReview({
    required this.name,
    required this.rating,
    required this.date,
    required this.comment,
  });

  factory ShopReview.fromJson(Map<String, dynamic> json) {
    return ShopReview(
      name: json['reviewerName'] ?? 'Khách hàng',
      rating: (json['rating'] as num? ?? 5).toDouble(),
      date: (json['date'] ?? '').toString().split('T').first,
      comment: json['comment'] ?? '',
    );
  }
}

class ShopProduct {
  final int id;
  final String name;
  final String category;
  final String image;
  final List<String> images;
  final double price;
  final double oldPrice;
  final double rating;
  final int reviewCount;
  final String description;
  final List<ShopReview> reviews;

  const ShopProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    required this.images,
    required this.price,
    required this.oldPrice,
    required this.rating,
    required this.reviewCount,
    required this.description,
    required this.reviews,
  });

  // Sản phẩm từ API DummyJSON có id > 0 và đơn vị gốc là USD
  bool get isUsd => id > 0;

  // Chuyển JSON từ API DummyJSON thành đối tượng ShopProduct
  factory ShopProduct.fromJson(Map<String, dynamic> json) {
    final double currentPrice = (json['price'] as num? ?? 0).toDouble();
    final double discount = (json['discountPercentage'] as num? ?? 0)
        .toDouble();
    final double calculatedOldPrice = discount > 0 && discount < 100
        ? currentPrice / (1 - discount / 100)
        : currentPrice * 1.2;

    final List rawReviews = json['reviews'] as List? ?? [];
    final parsedReviews = rawReviews
        .map((r) => ShopReview.fromJson(r))
        .toList();

    final rawImages = json['images'] != null
        ? List<String>.from(json['images'])
        : <String>[];
    final thumb = (json['thumbnail'] ?? '').toString();

    return ShopProduct(
      id: json['id'] ?? 0,
      name: json['title'] ?? '',
      category: json['category'] ?? 'Khác',
      image: thumb,
      images: rawImages.isNotEmpty ? rawImages : [thumb],
      price: currentPrice,
      oldPrice: calculatedOldPrice,
      rating: (json['rating'] as num? ?? 0).toDouble(),
      reviewCount: parsedReviews.isNotEmpty
          ? parsedReviews.length
          : (json['stock'] ?? 10),
      description: json['description'] ?? '',
      reviews: parsedReviews,
    );
  }
}

// 6 sản phẩm mẫu ban đầu (ID âm để phân biệt với sản phẩm API)
const List<ShopProduct> localProducts = [
  ShopProduct(
    id: -1,
    name: 'Giày thể thao năng động',
    category: 'Thời trang',
    image: 'assets/products/shoe_user.jpg',
    images: [
      'assets/products/shoe_user.jpg',
      'assets/products/shoe_2.jpg',
      'assets/products/shoe_3.jpg',
    ],
    price: 2190000,
    oldPrice: 2890000,
    rating: 4.8,
    reviewCount: 120,
    description: 'Giày thể thao thiết kế hiện đại, đế êm, phù hợp đi học, đi chơi và luyện tập thể thao.',
    reviews: [
      ShopReview(
        name: 'Nguyễn Văn An',
        rating: 5,
        date: '20/10/2026',
        comment: 'Giày đẹp, đi êm chân, giao hàng nhanh.',
      ),
      ShopReview(
        name: 'Trần Thị Mai',
        rating: 4.5,
        date: '18/10/2026',
        comment: 'Sản phẩm tốt, màu sắc giống hình.',
      ),
    ],
  ),
  ShopProduct(
    id: -2,
    name: 'Tai nghe không dây',
    category: 'Điện tử',
    image: 'assets/products/headphones.jpg',
    images: [
      'assets/products/headphones.jpg',
      'assets/products/headphones_2.jpg',
      'assets/products/headphones_3.jpg',
    ],
    price: 890000,
    oldPrice: 1090000,
    rating: 4.5,
    reviewCount: 86,
    description: 'Tai nghe Bluetooth nhỏ gọn, âm thanh rõ ràng, phù hợp nghe nhạc và học tập.',
    reviews: [
      ShopReview(
        name: 'Phạm Quốc Bảo',
        rating: 5,
        date: '21/10/2026',
        comment: 'Âm thanh tốt, kết nối nhanh.',
      ),
    ],
  ),
  ShopProduct(
    id: -3,
    name: 'Đồng hồ phong cách',
    category: 'Phụ kiện',
    image: 'assets/products/watch.jpg',
    images: [
      'assets/products/watch.jpg',
      'assets/products/watch_2.jpg',
      'assets/products/watch_3.jpg',
    ],
    price: 1250000,
    oldPrice: 1590000,
    rating: 4.6,
    reviewCount: 54,
    description: 'Đồng hồ thiết kế thanh lịch, phù hợp sử dụng hằng ngày.',
    reviews: [
      ShopReview(
        name: 'Đặng Hoàng Nam',
        rating: 5,
        date: '22/10/2026',
        comment: 'Thiết kế đẹp, đeo nhẹ tay.',
      ),
    ],
  ),
  ShopProduct(
    id: -4,
    name: 'Máy ảnh du lịch',
    category: 'Điện tử',
    image: 'assets/products/camera.jpg',
    images: [
      'assets/products/camera.jpg',
      'assets/products/camera_2.jpg',
      'assets/products/camera_3.jpg',
    ],
    price: 5600000,
    oldPrice: 6200000,
    rating: 4.7,
    reviewCount: 39,
    description: 'Máy ảnh dành cho người yêu thích chụp ảnh và du lịch, thiết kế nhỏ gọn.',
    reviews: [
      ShopReview(
        name: 'Trần Đức Huy',
        rating: 5,
        date: '23/10/2026',
        comment: 'Chụp ảnh đẹp, sản phẩm đúng mô tả.',
      ),
    ],
  ),
  ShopProduct(
    id: -5,
    name: 'Ba lô đi học',
    category: 'Phụ kiện',
    image: 'assets/products/backpack.jpg',
    images: [
      'assets/products/backpack.jpg',
      'assets/products/backpack_2.jpg',
      'assets/products/backpack_3.jpg',
    ],
    price: 450000,
    oldPrice: 590000,
    rating: 4.4,
    reviewCount: 71,
    description: 'Ba lô trẻ trung, có không gian chứa đồ rộng, phù hợp đi học hoặc du lịch.',
    reviews: [
      ShopReview(
        name: 'Nguyễn Hải Yến',
        rating: 5,
        date: '21/10/2026',
        comment: 'Ba lô đẹp, đựng được nhiều đồ.',
      ),
    ],
  ),
  ShopProduct(
    id: -6,
    name: 'Áo khoác thường ngày',
    category: 'Thời trang',
    image: 'assets/products/jacket.jpg',
    images: [
      'assets/products/jacket.jpg',
      'assets/products/jacket_2.jpg',
      'assets/products/jacket_3.jpg',
    ],
    price: 720000,
    oldPrice: 950000,
    rating: 4.3,
    reviewCount: 44,
    description:
        'Áo khoác phong cách đơn giản, dễ phối đồ và phù hợp nhiều hoạt động.',
    reviews: [
      ShopReview(
        name: 'Đỗ Nhật Minh',
        rating: 5,
        date: '22/10/2026',
        comment: 'Áo đẹp, mặc thoải mái.',
      ),
    ],
  ),
];

// Bộ nhớ đệm giữ toàn bộ sản phẩm đã tải để Giỏ hàng & Yêu thích không bị mất khi tìm kiếm
final Map<int, ShopProduct> productCache = {
  for (final p in localProducts) p.id: p,
};

void cacheProducts(Iterable<ShopProduct> products) {
  for (final p in products) {
    productCache[p.id] = p;
  }
}

// Danh sách hiển thị hiện tại
List<ShopProduct> shopProducts = [...localProducts];
