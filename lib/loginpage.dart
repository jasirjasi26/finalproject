import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'homepage.dart';

// Uncomment this when your home page exists:
// import 'eco_collect_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController numberController = TextEditingController();

  bool isRegister = false;
  bool isLoading = false;

  Future<void> loginOrRegister() async {
    final String name = nameController.text.trim();
    final String number = numberController.text.trim();
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    // Validation
    if (isRegister) {
      if (name.isEmpty ||
          number.isEmpty ||
          email.isEmpty ||
          password.isEmpty) {
        showSnackBar('Please fill all fields');
        return;
      }
    } else {
      if (email.isEmpty || password.isEmpty) {
        showSnackBar('Please enter email and password');
        return;
      }
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (isRegister) {
        // Create Firebase Authentication account
        final UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final User? user = userCredential.user;

        if (user == null) {
          showSnackBar('Registration failed');
          return;
        }

        // Save user information to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'name': name,
          'number': number,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;

        showSnackBar('Registration successful! Please login.');

        setState(() {
          isRegister = false;
        });

        clearControllers();
      } else {
        // Login
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("email", email);

        if (!mounted) return;

        showSnackBar(email.toLowerCase() == 'admin@gmail.com' ? 'Welcome Admin!' : 'Welcome back!');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const EcoCollectHomePage(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'weak-password':
          message = 'The password is too weak.';
          break;

        case 'email-already-in-use':
          message = 'An account already exists with this email.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'user-not-found':
          message = 'No account found with this email.';
          break;

        case 'wrong-password':
        case 'invalid-credential':
          message = 'Incorrect email or password.';
          break;

        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;

        default:
          message = e.message ?? 'Authentication failed.';
      }

      if (mounted) {
        showSnackBar(message);
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        showSnackBar(e.message ?? 'Firebase error occurred.');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar('An unexpected error occurred.');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void clearControllers() {
    nameController.clear();
    numberController.clear();
    emailController.clear();
    passwordController.clear();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    numberController.dispose();
    super.dispose();
  }

  InputDecoration fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: Colors.green,
          ),
        )
            : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 40,
            ),
            child: Column(
              children: [
                const SizedBox(height: 50),

                // Logo
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.recycling,
                      color: Colors.green,
                      size: 42,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'EcoCollect',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 50),

                // Registration fields
                if (isRegister) ...[
                  TextFormField(
                    controller: nameController,
                    textInputAction: TextInputAction.next,
                    decoration: fieldDecoration('Name'),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: numberController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: fieldDecoration('Phone Number'),
                  ),

                  const SizedBox(height: 20),
                ],

                // Email
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: fieldDecoration('Email'),
                ),

                const SizedBox(height: 20),

                // Password
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => loginOrRegister(),
                  decoration: fieldDecoration('Password'),
                ),

                const SizedBox(height: 40),

                // Login/Register button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: loginOrRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      isRegister ? 'Register' : 'Login',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // Switch Login/Register
                InkWell(
                  onTap: () {
                    setState(() {
                      isRegister = !isRegister;
                      clearControllers();
                    });
                  },
                  child: Text(
                    isRegister
                        ? 'Already have an account? Login'
                        : "Don't have an account? Register",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}