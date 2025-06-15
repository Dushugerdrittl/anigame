import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game_state.dart'; // To potentially trigger registration state
import '../widgets/themed_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      // --- Placeholder for Registration Logic ---
      await Future.delayed(const Duration(seconds: 1));
      final gameState = Provider.of<GameState>(context, listen: false);

      // This will be replaced with actual auth logic.
      bool registrationSuccess = await gameState.registerUser(_usernameController.text, _passwordController.text);

      if (mounted) {
        setState(() => _isLoading = false);
        if (registrationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration Successful! Please login.')),
          );
          Navigator.of(context).pop(); // Go back to login screen
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration Failed: Username might already exist.')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      appBar: AppBar(
        leading: IconButton( // Custom back button for adjusted height
          icon: const Icon(Icons.arrow_back),
          iconSize: 20.0, // Smaller icon
          padding: const EdgeInsets.all(5.0), // Reduced padding
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text("Register"),
        toolbarHeight: 30, // Set AppBar height to 30
        automaticallyImplyLeading: false, // Disable default back button to use custom one
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text("Create Account", style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.verified_user_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.length < 4) {
                      return 'Username must be at least 4 characters';
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
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.verified_user_outlined),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: const Text('Register'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        onPressed: _registerUser,
                      ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Go back to login screen
                  },
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
