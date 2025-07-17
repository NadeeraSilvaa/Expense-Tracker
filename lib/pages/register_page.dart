import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/pages/home_page.dart';
import 'package:finance_app/pages/login_page.dart';
import 'package:finance_app/theme/colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_name.text.isEmpty ||
    _email.text.isEmpty ||
    _password.text.isEmpty ||
    _confirmPassword.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_email.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email address")),
      );
      return;
    }
    if (_password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }
    if (_password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
          email: _email.text, password: _password.text);
      String uid = userCredential.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _name.text,
        'email': _email.text,
      });
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomePage()));
    } on FirebaseAuthException catch (e) {
      String message = e.code == 'email-already-in-use'
          ? 'Email already in use'
          : 'Registration failed';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 50),
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(
                          "https://images.unsplash.com/photo-1531256456869-ce942a665e80"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                _buildTextField("Name", _name, Icons.person_outline),
                const SizedBox(height: 20),
                _buildTextField("Email Address", _email, Icons.email_outlined),
                const SizedBox(height: 20),
                _buildTextField("Password", _password, Icons.lock_outline_rounded,
                    obscureText: true),
                const SizedBox(height: 20),
                _buildTextField(
                    "Confirm Password", _confirmPassword, Icons.lock_outline_rounded,
                    obscureText: true),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : GestureDetector(
                  onTap: _register,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 25),
                    decoration: BoxDecoration(
                      color: buttoncolor,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Center(
                      child: Text(
                        "Register",
                        style: TextStyle(
                          color: white,
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
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: black,
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage())),
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: blue,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {bool obscureText = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 25),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: grey.withOpacity(0.03),
            spreadRadius: 10,
            blurRadius: 3,
          ),
        ],
      ),
      child: Padding(
        padding:
        const EdgeInsets.only(left: 20, top: 15, bottom: 5, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Color(0xff67727d),
              ),
            ),
            TextField(
              controller: controller,
              obscureText: obscureText,
              cursorColor: black,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: black,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(icon),
                prefixIconColor: black,
                hintText: label,
                border: InputBorder.none,
                suffixIcon:
                obscureText ? const Icon(Icons.remove_red_eye_outlined) : null,
                suffixIconColor: obscureText ? black : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}