//Cài đặt hệ thống
import 'package:flutter/material.dart';

import 'api.dart';
import 'auth_pages.dart';
import 'config/app_config.dart';
import 'gd3.dart';

class SettingsPage extends StatefulWidget {
  final bool fromProfile;
  const SettingsPage({super.key, this.fromProfile = false});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (context, language, child) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: appThemeMode,
          builder: (context, themeMode, child) {
            final dark = themeMode == ThemeMode.dark;
            return Scaffold(
              appBar: AppBar(title: Text(tr('Cài đặt', 'Settings', '设置'))),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  sectionTitle(tr('BẢO MẬT', 'SECURITY', '安全')),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: Text(tr('Nhận thông báo', 'Notifications', '接收通知')),
                    value: notificationEnabled,
                    onChanged: (value) {
                      setState(() => notificationEnabled = value);
                      saveAppSettings();
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: Text(tr('Chế độ tối', 'Dark mode', '深色模式')),
                    value: dark,
                    onChanged: (value) {
                      appThemeMode.value = value
                          ? ThemeMode.dark
                          : ThemeMode.light;
                      saveAppSettings();
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.volume_up_outlined),
                    title: Text(tr('Âm thanh nhấn', 'Touch sound', '触摸音效')),
                    value: soundEnabled,
                    onChanged: (value) {
                      setState(() => soundEnabled = value);
                      saveAppSettings();
                    },
                  ),
                  const Divider(height: 32),
                  sectionTitle(tr('CÀI ĐẶT CHUNG', 'GENERAL SETTINGS', '通用设置')),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(tr('Trang cá nhân', 'Profile', '个人主页')),
                    subtitle: Text(
                      tr(
                        'Xem thông tin tài khoản',
                        'View account profile',
                        '查看个人资料',
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      if (widget.fromProfile) {
                        Navigator.pop(context);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfilePage(),
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(tr('Ngôn ngữ', 'Language', '语言')),
                    subtitle: Text(
                      language == 'vi'
                          ? 'Tiếng Việt'
                          : language == 'en'
                          ? 'English'
                          : '中文',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: showLanguageDialog,
                  ),
                  ValueListenableBuilder<double>(
                    valueListenable: appFontSize,
                    builder: (context, size, _) {
                      return ListTile(
                        leading: const Icon(Icons.text_fields),
                        title: Text(tr('Cỡ chữ', 'Font size', '字体大小')),
                        subtitle: Text('${size.toInt()} px'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: showFontDialog,
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(tr('Về ứng dụng', 'About app', '关于应用')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: showAbout,
                  ),
                  const Divider(height: 32),
                  OutlinedButton.icon(
                    onPressed: logout,
                    icon: const Icon(Icons.logout),
                    label: Text(tr('Đăng xuất', 'Log out', '退出登录')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF607D9B),
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  void showLanguageDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(tr('Chọn ngôn ngữ', 'Choose language', '选择语言')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              languageOption('vi', '🇻🇳 Tiếng Việt'),
              languageOption('en', '🇬🇧 English'),
              languageOption('zh', '🇨🇳 中文'),
            ],
          ),
        );
      },
    );
  }

  Widget languageOption(String code, String title) {
    return ListTile(
      title: Text(title),
      trailing: appLanguage.value == code
          ? const Icon(Icons.check, color: Color(0xFF17365D))
          : null,
      onTap: () {
        appLanguage.value = code;
        saveAppSettings();
        Navigator.pop(context);
      },
    );
  }

  void showFontDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(tr('Cỡ chữ', 'Font size', '字体大小')),
          content: ValueListenableBuilder<double>(
            valueListenable: appFontSize,
            builder: (context, size, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.noScaling),
                    child: Text(
                      '${tr('Xem trước cỡ chữ', 'Font size preview', '字体预览')} (${size.toInt()} px)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: size),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    min: 12,
                    max: 24,
                    divisions: 6,
                    value: size,
                    label: '${size.toInt()} px',
                    onChanged: (value) {
                      appFontSize.value = value;
                      saveAppSettings();
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(tr('Đóng', 'Close', '关闭')),
            ),
          ],
        );
      },
    );
  }

  void showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Shop Easy',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.shopping_bag, size: 40),
      children: [
        Text(
          tr(
            'Ứng dụng minh họa bài tập Flutter GD3 - GD11 & API DummyJSON.',
            'A Flutter demo for GD3 - GD11 & DummyJSON API.',
            '用于GD3-GD11练习和DummyJSON API的Flutter示例应用。',
          ),
        ),
      ],
    );
  }

  void logout() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(tr('Đăng xuất', 'Log out', '退出登录')),
          content: Text(
            tr(
              'Bạn có chắc chắn muốn đăng xuất?',
              'Are you sure you want to log out?',
              '确定要退出登录吗？',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(tr('Hủy', 'Cancel', '取消')),
            ),
            ElevatedButton(
              onPressed: () async {
                await saveAuthToken(null);
                if (!mounted) return;
                Navigator.pop(dialogContext);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              child: Text(tr('Đăng xuất', 'Log out', '退出登录')),
            ),
          ],
        );
      },
    );
  }
}
