import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'config/app_config.dart';
import 'gd4.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? apiProfileData;
  String? localFullName;
  String? localUsername;
  String? localEmail;
  bool isLoading = false;
  bool isFollowing = false;
  int followersCount = 1280;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (userAccessToken != null && userAccessToken!.isNotEmpty) {
      await fetchUserProfile();
    } else {
      final prefs = await SharedPreferences.getInstance();
      final savedUsername = prefs.getString('current_local_user');
      if (!mounted) return;
      if (savedUsername != null && savedUsername.isNotEmpty) {
        setState(() {
          localUsername = savedUsername;
          localFullName = prefs.getString('local_fullname_$savedUsername');
          localEmail = prefs.getString('local_email_$savedUsername');
        });
      }
    }
  }

  Future<void> fetchUserProfile() async {
    if (userAccessToken == null || userAccessToken!.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final response = await dio.get('/auth/me');
      if (!mounted) return;
      setState(() {
        apiProfileData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  String _formatAddress(dynamic addressData) {
    if (addressData is Map) {
      final parts = [
        addressData['address'],
        addressData['city'],
        addressData['state'],
      ].where((e) => e != null && e.toString().trim().isNotEmpty).toList();
      if (parts.isNotEmpty) return parts.join(', ');
    }
    return tr('Huế, Việt Nam', 'Hue, Vietnam', '顺化，越南');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardSurfaceColor = isDark ? const Color(0xFF1E222D) : Colors.white;
    final data = apiProfileData;

    final String fullName = data != null
        ? '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim()
        : (localFullName != null && localFullName!.isNotEmpty)
        ? localFullName!
        : tr('Nguyễn Văn An', 'Nguyen Van An', '阮文安');

    final String jobTitle =
        (data?['company'] is Map && data!['company']['title'] != null)
        ? data['company']['title'].toString()
        : tr('Thành viên ShopEasy', 'ShopEasy Member', 'ShopEasy 会员');

    final String? avatarUrl = data?['image']?.toString();
    final String email =
        data?['email']?.toString() ??
        ((localEmail != null && localEmail!.isNotEmpty)
            ? localEmail!
            : (localUsername != null
                  ? '$localUsername@shopeasy.vn'
                  : 'user@shopeasy.vn'));
    final String phone = data?['phone']?.toString() ?? '0901 234 567';
    final String birthDate = data?['birthDate']?.toString() ?? '2004-01-01';
    final String bloodGroup = data?['bloodGroup']?.toString() ?? 'O+';
    final String university =
        data?['university']?.toString() ??
        tr(
          'Đại học Khoa học, Đại học Huế',
          'University of Sciences, Hue University',
          '顺化科学大学',
        );
    final String address = _formatAddress(data?['address']);

    const double coverHeight = 135.0;
    const double outerAvatarRadius = 48.0;
    const double innerAvatarRadius = 43.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Hồ sơ cá nhân', 'Profile', '个人资料')),
        actions: [
          IconButton(
            tooltip: tr('Cài đặt', 'Settings', '设置'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsPage(fromProfile: true),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      elevation: 3,
                      shadowColor: Colors.black.withValues(alpha: 0.12),
                      color: cardSurfaceColor,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: coverHeight,
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF17365D),
                                      Color(0xFF2878D0),
                                      Color(0xFF4CA1AF),
                                    ],
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: -20,
                                      top: -20,
                                      child: CircleAvatar(
                                        radius: 55,
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.08),
                                      ),
                                    ),
                                    Positioned(
                                      left: 24,
                                      bottom: 16,
                                      child: CircleAvatar(
                                        radius: 26,
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.08),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  outerAvatarRadius + 12,
                                  20,
                                  20,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      fullName,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      jobTitle,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    const Divider(height: 1),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildStatColumn(
                                            value: '48',
                                            label: tr(
                                              'Bài viết',
                                              'Posts',
                                              '帖子',
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildStatColumn(
                                            value: '$followersCount',
                                            label: tr(
                                              'Người theo dõi',
                                              'Followers',
                                              '粉丝',
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildStatColumn(
                                            value: '315',
                                            label: tr(
                                              'Đang theo dõi',
                                              'Following',
                                              '关注',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    const Divider(height: 1),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: SizedBox(
                                            height: 44,
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                setState(() {
                                                  isFollowing = !isFollowing;
                                                  followersCount += isFollowing
                                                      ? 1
                                                      : -1;
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isFollowing
                                                    ? Colors.grey.shade700
                                                    : const Color(0xFF1D6CE0),
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              icon: Icon(
                                                isFollowing
                                                    ? Icons.check
                                                    : Icons.person_add_alt_1,
                                                size: 18,
                                              ),
                                              label: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  isFollowing
                                                      ? tr(
                                                          'Đang theo dõi',
                                                          'Following',
                                                          '已关注',
                                                        )
                                                      : tr(
                                                          'Theo dõi',
                                                          'Follow',
                                                          '关注',
                                                        ),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          flex: 2,
                                          child: SizedBox(
                                            height: 44,
                                            child: OutlinedButton.icon(
                                              onPressed: () {
                                                showMessage(
                                                  context,
                                                  tr(
                                                    'Mở hộp thoại nhắn tin với $fullName',
                                                    'Opening chat with $fullName',
                                                    '打开与 $fullName 的聊天',
                                                  ),
                                                );
                                              },
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF17365D),
                                                side: BorderSide(
                                                  color: Colors.grey.withValues(
                                                    alpha: 0.45,
                                                  ),
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              icon: const Icon(
                                                Icons.chat_bubble_outline,
                                                size: 17,
                                              ),
                                              label: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  tr(
                                                    'Nhắn tin',
                                                    'Message',
                                                    '私信',
                                                  ),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            top: coverHeight - outerAvatarRadius,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: CircleAvatar(
                                radius: outerAvatarRadius,
                                backgroundColor: cardSurfaceColor,
                                child: CircleAvatar(
                                  radius: innerAvatarRadius,
                                  backgroundColor: const Color(0xFF1D6CE0),
                                  backgroundImage:
                                      (avatarUrl != null &&
                                          avatarUrl.isNotEmpty)
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child:
                                      (avatarUrl == null || avatarUrl.isEmpty)
                                      ? const Icon(
                                          Icons.person,
                                          size: 44,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      elevation: 0,
                      color: cardSurfaceColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.email_outlined, 'Email', email),
                          const Divider(height: 1),
                          _buildInfoRow(
                            Icons.phone_outlined,
                            tr('Số điện thoại', 'Phone', '电话'),
                            phone,
                          ),
                          const Divider(height: 1),
                          _buildInfoRow(
                            Icons.cake_outlined,
                            tr(
                              'Ngày sinh / Nhóm máu',
                              'Birth / Blood',
                              '生日 / 血型',
                            ),
                            '$birthDate  •  $bloodGroup',
                          ),
                          const Divider(height: 1),
                          _buildInfoRow(
                            Icons.school_outlined,
                            tr('Trường học', 'University', '大学'),
                            university,
                          ),
                          const Divider(height: 1),
                          _buildInfoRow(
                            Icons.location_on_outlined,
                            tr('Địa chỉ', 'Address', '地址'),
                            address,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatColumn({required String value, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: const Color(0xFF17365D)),
      title: Text(
        label,
        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}
