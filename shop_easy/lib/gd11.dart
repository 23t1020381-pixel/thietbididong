//Thống kê quản trị
import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'models/product_model.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  String _formatRevenue(double totalVnd) {
    if (totalVnd >= 1000000) {
      final millions = totalVnd / 1000000;
      return '${millions.toStringAsFixed(1).replaceAll('.', ',')} triệu';
    }
    return formatVnd(totalVnd);
  }

  @override
  Widget build(BuildContext context) {
    final fontScale = (appFontSize.value / 16).clamp(0.85, 1.5);

    return ValueListenableBuilder<List<AppOrder>>(
      valueListenable: recentOrders,
      builder: (context, orders, child) {
        final extraOrdersCount = (orders.length - 4).clamp(0, 999999);
        final totalOrdersCount = 128 + extraOrdersCount;

        final newRevenueVnd = orders
            .take(extraOrdersCount)
            .fold<double>(0, (sum, o) => sum + o.totalVnd);
        final totalRevenueVnd = 25600000 + newRevenueVnd;

        final metrics = <_DashboardMetric>[
          _DashboardMetric(
            tr('Đơn hàng', 'Orders', '订单'),
            '$totalOrdersCount',
            Icons.shopping_bag_outlined,
            const Color(0xFF2878D0),
          ),
          _DashboardMetric(
            tr('Doanh thu', 'Revenue', '营收'),
            _formatRevenue(totalRevenueVnd),
            Icons.payments_outlined,
            const Color(0xFF159B72),
          ),
          _DashboardMetric(
            tr('Khách hàng', 'Customers', '客户'),
            '${accounts.length}',
            Icons.people_outline,
            const Color(0xFFE18A25),
          ),
          _DashboardMetric(
            tr('Sản phẩm', 'Products', '商品'),
            '${productCache.length}',
            Icons.inventory_2_outlined,
            const Color(0xFF8A61C2),
          ),
        ];

        return Scaffold(
          appBar: AppBar(title: Text(tr('Tổng quan', 'Dashboard', '仪表盘'))),
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    tr('Thống kê cửa hàng', 'Store Statistics', '店铺统计'),
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.crossAxisExtent >= 600 ? 4 : 2;
                    final baseRatio = columns == 4 ? 1.45 : 1.35;
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: (baseRatio / fontScale).clamp(
                          0.95,
                          1.5,
                        ),
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _DashboardMetricCard(metric: metrics[index]),
                        childCount: metrics.length,
                      ),
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr('Đơn hàng gần đây', 'Recent Orders', '最近订单'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () => showMessage(
                          context,
                          tr(
                            'Đang hiển thị ${orders.length} đơn hàng gần nhất.',
                            'Showing ${orders.length} most recent orders.',
                            '正在显示最近 ${orders.length} 笔订单。',
                          ),
                        ),
                        child: Text(tr('Xem tất cả', 'View all', '查看全部')),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _DashboardOrderTile(order: orders[index]),
                    childCount: orders.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Text(
                    tr(
                      'Số liệu đơn hàng, doanh thu và khách hàng tự động cập nhật khi bạn đăng ký tài khoản hoặc thanh toán giỏ hàng.',
                      'Orders, revenue, and customer metrics automatically update when you register accounts or checkout.',
                      '注册账户或结算购物车时，订单、营收和客户数据将自动更新。',
                    ),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardMetric {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _DashboardMetric(this.label, this.value, this.icon, this.color);
}

class _DashboardMetricCard extends StatelessWidget {
  final _DashboardMetric metric;
  const _DashboardMetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: metric.color.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(metric.icon, color: metric.color, size: 21),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                metric.value,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              metric.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardOrderTile extends StatelessWidget {
  final AppOrder order;
  const _DashboardOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final badgeColor = Color(order.colorValue);
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF17365D).withValues(alpha: 0.10),
          child: const Icon(
            Icons.receipt_long_outlined,
            color: Color(0xFF17365D),
          ),
        ),
        title: Text(
          '${order.code} • ${formatVnd(order.totalVnd)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${order.customer} • ${order.date}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            order.status,
            style: TextStyle(
              color: badgeColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
