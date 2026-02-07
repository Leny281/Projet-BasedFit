import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/auth_service.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Contrôleurs pour les champs
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime? _selectedDate;

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[400]!,
              Colors.blue[700]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo et titre
                        Icon(
                          Icons.fitness_center,
                          size: 64,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'BasedFit',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin ? 'Connexion' : 'Créer un compte',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Formulaire
                        if (!_isLogin) ..._buildRegisterFields(),
                        if (_isLogin) ..._buildLoginFields(),

                        const SizedBox(height: 24),

                        // Bouton principal
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isLogin ? 'Se connecter' : 'S\'inscrire',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Basculer entre connexion et inscription
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _formKey.currentState?.reset();
                            });
                          },
                          child: Text(
                            _isLogin
                                ? 'Pas encore de compte ? S\'inscrire'
                                : 'Déjà un compte ? Se connecter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLoginFields() {
    return [
      TextFormField(
        controller: _emailController,
        decoration: InputDecoration(
          labelText: 'Adresse email',
          prefixIcon: const Icon(Icons.email),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer votre email';
          }
          if (!value.contains('@')) {
            return 'Email invalide';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _passwordController,
        decoration: InputDecoration(
          labelText: 'Mot de passe',
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        obscureText: _obscurePassword,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer votre mot de passe';
          }
          return null;
        },
      ),
    ];
  }

  List<Widget> _buildRegisterFields() {
    return [
      // Nom et Prénom
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'Prénom',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Requis';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Nom',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Requis';
                }
                return null;
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Email
      TextFormField(
        controller: _emailController,
        decoration: InputDecoration(
          labelText: 'Adresse email',
          prefixIcon: const Icon(Icons.email),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer votre email';
          }
          if (!value.contains('@')) {
            return 'Email invalide';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),

      // Téléphone
      TextFormField(
        controller: _phoneController,
        decoration: InputDecoration(
          labelText: 'Numéro de téléphone',
          prefixIcon: const Icon(Icons.phone),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        keyboardType: TextInputType.phone,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer votre numéro';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),

      // Date de naissance
      InkWell(
        onTap: _selectDate,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date de naissance',
            prefixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _selectedDate != null
                ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                : 'Sélectionner une date',
            style: TextStyle(
              color: _selectedDate != null ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Taille et Poids
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _heightController,
              decoration: InputDecoration(
                labelText: 'Taille (cm)',
                prefixIcon: const Icon(Icons.height),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Requis';
                }
                if (double.tryParse(value) == null) {
                  return 'Invalide';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: 'Poids (kg)',
                prefixIcon: const Icon(Icons.monitor_weight),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Requis';
                }
                if (double.tryParse(value) == null) {
                  return 'Invalide';
                }
                return null;
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Mot de passe
      TextFormField(
        controller: _passwordController,
        decoration: InputDecoration(
          labelText: 'Mot de passe',
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        obscureText: _obscurePassword,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer un mot de passe';
          }
          if (value.length < 6) {
            return 'Minimum 6 caractères';
          }
          return null;
        },
      ),
    ];
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isLogin && _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner votre date de naissance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (_isLogin) {
        success = await _authService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        success = await _authService.register(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          birthDate: _selectedDate!,
          height: double.parse(_heightController.text),
          weight: double.parse(_weightController.text),
          password: _passwordController.text,
        );
      }

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isLogin
                  ? 'Email ou mot de passe incorrect'
                  : 'Cet email est déjà utilisé',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
