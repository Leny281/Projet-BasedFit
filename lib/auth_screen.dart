import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/auth_service.dart';
import 'data/app_database.dart';
import 'home_screen.dart';
import 'manager_home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  // --- Onglets membre / gérant ---
  late TabController _tabController;

  // --- Membre ---
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

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

  // --- Gérant ---
  final _managerFormKey = GlobalKey<FormState>();
  final _managerEmailController = TextEditingController();
  final _managerPasswordController = TextEditingController();
  final _managerFirstNameController = TextEditingController();
  final _managerLastNameController = TextEditingController();
  final _gymNameController = TextEditingController();
  bool _managerIsLoading = false;
  bool _managerObscurePassword = true;
  bool _isManagerRegister = false; // false = connexion, true = création compte

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _managerEmailController.dispose();
    _managerPasswordController.dispose();
    _managerFirstNameController.dispose();
    _managerLastNameController.dispose();
    _gymNameController.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[400]!, Colors.blue[700]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fitness_center,
                            size: 60, color: Colors.blue[700]),
                        const SizedBox(height: 12),
                        Text(
                          'BasedFit',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 20),

                         Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: Colors.blue[700],
                              borderRadius: BorderRadius.circular(12),
                              
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.grey[600],
                            dividerColor: Colors.transparent,
                            onTap: (_) => setState(() {}),
                            tabs: const [
                              Tab(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('Membre'),
                                ),
                              ),
                              Tab(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('Gérant'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: _tabController.index == 0
                              ? _buildMemberTab()
                              : _buildManagerTab(),
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


  // ───────────────────────── ONGLET MEMBRE ─────────────────────────

  Widget _buildMemberTab() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isLogin ? 'Connexion' : 'Créer un compte',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          if (!_isLogin) ..._buildRegisterFields(),
          if (_isLogin) ..._buildLoginFields(),
          const SizedBox(height: 20),
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
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _isLogin ? 'Se connecter' : 'S\'inscrire',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 12),
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
    );
  }

  // ───────────────────────── ONGLET GÉRANT ─────────────────────────

  Widget _buildManagerTab() {
    return Form(
      key: _managerFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                'Espace réservé aux gérants de salle',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mode inscription gérant
          if (_isManagerRegister) ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _managerFirstNameController,
                    decoration: InputDecoration(
                      labelText: 'Prénom',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _managerLastNameController,
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gymNameController,
              decoration: InputDecoration(
                labelText: 'Nom de la salle de sport',
                prefixIcon: const Icon(Icons.fitness_center),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Veuillez entrer le nom de la salle'
                  : null,
            ),
            const SizedBox(height: 12),
          ],

          TextFormField(
            controller: _managerEmailController,
            decoration: InputDecoration(
              labelText: 'Email gérant',
              prefixIcon: const Icon(Icons.badge),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Veuillez entrer votre email';
              if (!value.contains('@')) return 'Email invalide';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _managerPasswordController,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_managerObscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _managerObscurePassword = !_managerObscurePassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            obscureText: _managerObscurePassword,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Veuillez entrer votre mot de passe';
              if (_isManagerRegister && value.length < 6) return 'Minimum 6 caractères';
              return null;
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _managerIsLoading
                  ? null
                  : (_isManagerRegister ? _handleManagerRegister : _handleManagerLogin),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _managerIsLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _isManagerRegister ? 'Créer le compte gérant' : 'Accéder à l\'espace gérant',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() {
              _isManagerRegister = !_isManagerRegister;
              _managerFormKey.currentState?.reset();
            }),
            child: Text(
              _isManagerRegister
                  ? 'Déjà un compte gérant ? Se connecter'
                  : 'Créer un compte gérant',
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── CHAMPS FORMULAIRES ────────────────────────

  List<Widget> _buildLoginFields() {
    return [
      TextFormField(
        controller: _emailController,
        decoration: InputDecoration(
          labelText: 'Adresse email',
          prefixIcon: const Icon(Icons.email),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Veuillez entrer votre email';
          if (!value.contains('@')) return 'Email invalide';
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
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        obscureText: _obscurePassword,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Veuillez entrer votre mot de passe';
          return null;
        },
      ),
    ];
  }

  List<Widget> _buildRegisterFields() {
    return [
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'Prénom',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Requis' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Nom',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Requis' : null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _emailController,
        decoration: InputDecoration(
          labelText: 'Adresse email',
          prefixIcon: const Icon(Icons.email),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Veuillez entrer votre email';
          if (!value.contains('@')) return 'Email invalide';
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _phoneController,
        decoration: InputDecoration(
          labelText: 'Numéro de téléphone',
          prefixIcon: const Icon(Icons.phone),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: TextInputType.phone,
        validator: (value) =>
            (value == null || value.isEmpty) ? 'Veuillez entrer votre numéro' : null,
      ),
      const SizedBox(height: 16),
      InkWell(
        onTap: _selectDate,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date de naissance',
            prefixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _heightController,
              decoration: InputDecoration(
                labelText: 'Taille (cm)',
                prefixIcon: const Icon(Icons.height),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Requis';
                if (double.tryParse(value) == null) return 'Invalide';
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Requis';
                if (double.tryParse(value) == null) return 'Invalide';
                return null;
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _passwordController,
        decoration: InputDecoration(
          labelText: 'Mot de passe',
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        obscureText: _obscurePassword,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Veuillez entrer un mot de passe';
          if (value.length < 6) return 'Minimum 6 caractères';
          return null;
        },
      ),
    ];
  }

  // ─────────────────────────── LOGIQUE ──────────────────────────────

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isLogin && _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner votre date de naissance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

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
            content: Text(_isLogin
                ? 'Email ou mot de passe incorrect'
                : 'Cet email est déjà utilisé'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleManagerLogin() async {
    if (!_managerFormKey.currentState!.validate()) return;
    setState(() => _managerIsLoading = true);
    try {
      final email = _managerEmailController.text.trim();
      final hashedPassword = AppDatabase.hashPassword(_managerPasswordController.text);
      final db = await AppDatabase.instance.database;
      final result = await db.query(
        'users',
        where: 'email = ? AND password = ? AND is_admin = 1',
        whereArgs: [email, hashedPassword],
        limit: 1,
      );
      if (result.isNotEmpty && mounted) {
        final managerId = result.first['id'] as int;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ManagerHomeScreen(managerId: managerId),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Identifiants gérant incorrects'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _managerIsLoading = false);
    }
  }

  Future<void> _handleManagerRegister() async {
    if (!_managerFormKey.currentState!.validate()) return;
    setState(() => _managerIsLoading = true);
    try {
      final email = _managerEmailController.text.trim();
      final hashedPassword = AppDatabase.hashPassword(_managerPasswordController.text);
      final gymName = _gymNameController.text.trim();
      final db = await AppDatabase.instance.database;

      // Vérifier que l'email n'est pas déjà utilisé
      final existing = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cet email est déjà utilisé'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Créer le compte gérant
      final managerId = await db.insert('users', {
        'first_name': _managerFirstNameController.text.trim(),
        'last_name': _managerLastNameController.text.trim(),
        'email': email,
        'password': hashedPassword,
        'phone_number': '0000000000',
        'birth_date': '1990-01-01',
        'height': 170.0,
        'weight': 70.0,
        'goal': 'management',
        'is_admin': 1,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Créer la salle associée
      await db.insert('gyms', {
        'name': gymName,
        'manager_user_id': managerId,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ManagerHomeScreen(managerId: managerId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _managerIsLoading = false);
    }
  }
}