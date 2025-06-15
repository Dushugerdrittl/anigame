import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game_state.dart'; // To potentially trigger login state
import '../widgets/themed_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      // --- Placeholder for Authentication Logic ---
      // In a real app, you'd call your auth service here.
      // For now, let's simulate a delay and a simple check.
      await Future.delayed(const Duration(seconds: 1));
      final gameState = Provider.of<GameState>(context, listen: false);

      // Example: Simple hardcoded login for now, or check against SharedPreferences
      // This will be replaced with actual auth logic.
      bool loginSuccess = await gameState.loginUser(_usernameController.text, _passwordController.text);

      if (mounted) {
        setState(() => _isLoading = false);
        if (loginSuccess) {
          Navigator.of(context).pushReplacementNamed('/'); // Navigate to HomeScreen
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login Failed: Invalid credentials.')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      appBar: AppBar(
        title: const Text("Login"),
        toolbarHeight: 30, // Set AppBar height to 30
      ),      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("Welcome Back!", style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.login),
                        label: const Text('Login'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        onPressed: _loginUser,
                      ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text('Don\'t have an account? Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
