import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'config/app_config.dart';
import 'gd6.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController(
    text: 'emilys',
  );
  final TextEditingController passwordController = TextEditingController(
    text: 'emilyspass',
  );
  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      showMessage(
        context,
        tr(
          'Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu.',
          'Please enter both username and password.',
          '请输入用户名和密码。',
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Kiểm tra tài khoản đăng ký cục bộ trước
      if (accounts[username] == password) {
        await saveAuthToken(null);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_local_user', username);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ShopHomePage()),
        );
        return;
      }

      // 2. Gọi API POST https://dummyjson.com/auth/login
      final response = await dio.post(
        '/auth/login',
        data: {'username': username, 'password': password, 'expiresInMins': 30},
      );

      final data = response.data as Map<String, dynamic>;
      final accessToken = data['accessToken']?.toString();
      final refreshToken = data['refreshToken']?.toString();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Không nhận được accessToken từ server.');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_local_user');
      await saveAuthToken(accessToken, refreshToken: refreshToken);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ShopHomePage()),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final serverMsg = e.response?.data is Map
          ? e.response?.data['message']?.toString()
          : null;
      showMessage(
        context,
        serverMsg ??
            tr(
              'Sai tài khoản hoặc lỗi kết nối máy chủ.',
              'Invalid credentials or network error.',
              '账号错误或网络连接失败。',
            ),
      );
    } catch (_) {
      if (!mounted) return;
      showMessage(context, tr('Đăng nhập thất bại.', 'Login failed.', '登录失败。'));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.shopping_bag_rounded,
                    size: 72,
                    color: Color(0xFF17365D),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ShopEasy',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr(
                      'Đăng nhập để tiếp tục mua sắm',
                      'Sign in to continue shopping',
                      '登录以继续购物',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: usernameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: tr('Tên đăng nhập', 'Username', '用户名'),
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1E222D)
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    onSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      labelText: tr('Mật khẩu', 'Password', '密码'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => obscurePassword = !obscurePassword),
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1E222D)
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17365D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              tr('Đăng nhập', 'Sign In', '登录'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    child: Text(
                      tr(
                        'Chưa có tài khoản? Đăng ký ngay',
                        'Don\'t have an account? Sign up',
                        '还没有账号？立即注册',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final fullName = fullNameController.text.trim();
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    if (fullName.isEmpty || username.isEmpty || password.isEmpty) {
      showMessage(
        context,
        tr(
          'Vui lòng điền đầy đủ thông tin bắt buộc.',
          'Please fill in all required fields.',
          '请填写所有必填项。',
        ),
      );
      return;
    }

    if (password != confirm) {
      showMessage(
        context,
        tr(
          'Mật khẩu xác nhận không khớp.',
          'Passwords do not match.',
          '两次输入的密码不一致。',
        ),
      );
      return;
    }

    if (accounts.containsKey(username)) {
      showMessage(
        context,
        tr('Tên đăng nhập đã tồn tại.', 'Username already exists.', '用户名已存在。'),
      );
      return;
    }

    accounts[username] = password;
    await saveRegisteredAccounts();

    // Lưu kèm họ tên và email của tài khoản vừa đăng ký
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_fullname_$username', fullName);
    await prefs.setString(
      'local_email_$username',
      email.isEmpty ? '$username@shopeasy.vn' : email,
    );

    if (!mounted) return;
    showMessage(
      context,
      tr(
        'Đăng ký thành công! Vui lòng đăng nhập.',
        'Registration successful! Please sign in.',
        '注册成功！请登录。',
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Đăng ký tài khoản', 'Sign Up', '注册账号'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: fullNameController,
              decoration: InputDecoration(
                labelText: tr('Họ và tên', 'Full name', '姓名'),
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: tr('Tên đăng nhập', 'Username', '用户名'),
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: tr('Mật khẩu', 'Password', '密码'),
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: tr('Nhập lại mật khẩu', 'Confirm password', '确认密码'),
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF17365D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  tr('Tạo tài khoản', 'Create Account', '创建账号'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
