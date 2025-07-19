import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/theme/colors.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _password.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.primary(themeProvider.isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.primary(themeProvider.isDarkMode),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(
                          "https://images.unsplash.com/photo-1531256456869-ce942a665e80"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Login to Your Account",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainFontColor(themeProvider.isDarkMode),
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                    "Email", _email, Icons.email, themeProvider.isDarkMode),
                const SizedBox(height: 20),
                _buildTextField(
                    "Password", _password, Icons.lock, themeProvider.isDarkMode,
                    obscureText: true),
                const SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator(
                    color: AppColors.buttonColor(themeProvider.isDarkMode))
                    : GestureDetector(
                  onTap: _login,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.buttonColor(themeProvider.isDarkMode),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        "Login",
                        style: TextStyle(
                          color: AppColors.white(themeProvider.isDarkMode),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: AppColors.black(themeProvider.isDarkMode)
                            .withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: Text(
                        "Register",
                        style: TextStyle(
                          color: AppColors.buttonColor(themeProvider.isDarkMode),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon, bool isDarkMode,
      {bool obscureText = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white(isDarkMode),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey(isDarkMode).withOpacity(0.03),
            spreadRadius: 10,
            blurRadius: 3,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: AppColors.grey(isDarkMode).withOpacity(0.7),
              ),
            ),
            TextField(
              controller: controller,
              cursorColor: AppColors.black(isDarkMode),
              obscureText: obscureText,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppColors.black(isDarkMode),
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: AppColors.black(isDarkMode)),
                hintText: label,
                border: InputBorder.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}