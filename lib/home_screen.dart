import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

import 'programme_creation/create_workout_screen.dart';
import 'programme_creation/view_workout_screen.dart';
import 'programme_creation/data/workout_repository.dart';
import 'programme_creation/models.dart';
import 'profile_screen.dart';
import 'services/auth_service.dart';
import 'community/community_screen.dart';
import 'models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    _MenuTab(),
    TrainingTab(),
    _NutritionTab(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BasedFit'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Menu'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center), label: 'Training'),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant), label: 'Nutrition'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Communauté'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

/// Onglet Entraînement connecté à la DB (programmes affichés + cliquables)
class TrainingTab extends StatefulWidget {
  const TrainingTab({super.key});

  @override
  State<TrainingTab> createState() => _TrainingTabState();
}

class _TrainingTabState extends State<TrainingTab> {
  final WorkoutRepository _repo = WorkoutRepository();
  Future<List<WorkoutProgram>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _repo.getAllPrograms();
    setState(() {});
  }

  /// Ouvrir l'écran de création d'un nouveau programme
  Future<void> _openCreate() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateWorkoutScreen()),
    );
    if (res != null) _reload();
  }

  /// Ouvrir l'écran de visualisation d'un programme existant (lecture seule)
  Future<void> _openView(int programId) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewWorkoutScreen(programId: programId),
      ),
    );
    // Recharger si le programme a été modifié ou supprimé
    if (res != null) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WorkoutProgram>>(
      future: _future,
      builder: (context, snap) {
        final programs = snap.data ?? const <WorkoutProgram>[];
        final latest = programs.isNotEmpty ? programs.first : null;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          children: [
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Entraînement',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // "Séance du jour" = dernier programme sauvegardé (cliquable -> visualisation)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap:
                    (latest?.id == null) ? null : () => _openView(latest!.id!),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          size: 32,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Séance du jour',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              latest == null
                                  ? 'Aucun programme'
                                  : '${latest.name} • ${latest.exercises.length} exos • ${latest.duration.toStringAsFixed(0)} min',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Bouton démarrer la séance
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed:
                    (latest?.id == null) ? null : () => _openView(latest!.id!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text(
                  'Commencer séance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bouton créer un entraînement
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _openCreate,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(
                  'Créer un entraînement',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Titre section programmes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mes programmes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (programs.isNotEmpty)
                  Text(
                    '${programs.length} programme${programs.length > 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Liste des programmes
            if (snap.connectionState != ConnectionState.done)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snap.hasError)
              _ErrorCard(message: 'Erreur: ${snap.error}')
            else if (programs.isEmpty)
              _EmptyCard(onCreatePressed: _openCreate)
            else
              ...programs.map((p) => _ProgramCard(
                    program: p,
                    onTap: () {
                      if (p.id != null) _openView(p.id!);
                    },
                  )),
          ],
        );
      },
    );
  }
}

/// Carte de programme
class _ProgramCard extends StatelessWidget {
  final WorkoutProgram program;
  final VoidCallback onTap;

  const _ProgramCard({
    required this.program,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Trouver les groupes musculaires uniques
    final muscles = program.exercises
        .map((e) => e.exercise.muscleGroup)
        .where((m) => m.isNotEmpty)
        .toSet()
        .take(3)
        .join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.fitness_center, color: Colors.blue),
              ),
              const SizedBox(width: 16),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${program.exercises.length} exercices • ${program.duration.toStringAsFixed(0)} min',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    if (muscles.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        muscles,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Flèche
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte vide (aucun programme)
class _EmptyCard extends StatelessWidget {
  final VoidCallback onCreatePressed;

  const _EmptyCard({required this.onCreatePressed});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun programme',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez votre premier programme d\'entraînement',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onCreatePressed,
              icon: const Icon(Icons.add),
              label: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte d'erreur
class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.red[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[400]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholders autres onglets
class _NutritionTab extends StatefulWidget {
  const _NutritionTab();

  @override
  State<_NutritionTab> createState() => _NutritionTabState();
}

class _NutritionTabState extends State<_NutritionTab> {
  double? _maintenance;
  double? _remaining;

  double _maintenanceCalories(User user) {
    final bmr = (10 * user.weight) + (6.25 * user.height) - (5 * user.age);
    const activityFactor = 1.2; // activité légère par défaut
    return bmr * activityFactor;
  }

  void _ensureCalories(User user) {
    final maintenance = _maintenanceCalories(user);
    if (_maintenance == null || _remaining == null) {
      _maintenance = maintenance;
      _remaining = maintenance;
      return;
    }
  }

  Future<void> _addCalories(BuildContext context, User user) async {
    final controller = TextEditingController();

    final added = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajout rapide'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Calories consommées',
            prefixIcon: Icon(Icons.restaurant),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value == null || value <= 0) {
                return;
              }
              Navigator.pop(context, value);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (added == null) return;

    setState(() {
      _ensureCalories(user);
      _remaining = (_remaining! - added).clamp(0, double.infinity);
    });
  }

  Future<List<_FoodItem>> _searchFoods(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse('https://world.openfoodfacts.org/cgi/search.pl')
        .replace(queryParameters: {
      'search_terms': query.trim(),
      'search_simple': '1',
      'action': 'process',
      'json': '1',
      'page_size': '20',
      'fields': 'product_name,nutriments',
    });

    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erreur API: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final products = (data['products'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();

    final results = <_FoodItem>[];
    for (final product in products) {
      final name = (product['product_name'] as String?)?.trim();
      if (name == null || name.isEmpty) continue;

      final nutriments = product['nutriments'] as Map<String, dynamic>?;
      if (nutriments == null) continue;

      final kcalValue = nutriments['energy-kcal_100g'] ??
          nutriments['energy-kcal'] ??
          nutriments['energy-kcal_serving'];

      final kcal = kcalValue is num
          ? kcalValue.toDouble()
          : double.tryParse(kcalValue?.toString() ?? '');

      if (kcal == null || kcal <= 0) continue;

      results.add(_FoodItem(name: name, kcalPer100g: kcal));
    }

    return results;
  }

  Future<_FoodItem?> _fetchFoodByBarcode(String barcode) async {
    final uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$barcode.json')
        .replace(queryParameters: {
      'fields': 'product_name,product_name_fr,product_name_en,nutriments',
    });

    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erreur API: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final product = data['product'] as Map<String, dynamic>?;
    if (product == null) return null;

    final name = ((product['product_name'] as String?)?.trim().isNotEmpty ?? false)
        ? (product['product_name'] as String).trim()
        : ((product['product_name_fr'] as String?)?.trim().isNotEmpty ?? false)
            ? (product['product_name_fr'] as String).trim()
            : ((product['product_name_en'] as String?)?.trim().isNotEmpty ?? false)
                ? (product['product_name_en'] as String).trim()
                : null;

    if (name == null || name.isEmpty) return null;

    final nutriments = product['nutriments'] as Map<String, dynamic>?;
    if (nutriments == null) return null;

    final kcalValue = nutriments['energy-kcal_100g'] ??
        nutriments['energy-kcal'] ??
        nutriments['energy-kcal_serving'];

    final kcal = kcalValue is num
        ? kcalValue.toDouble()
        : double.tryParse(kcalValue?.toString() ?? '');

    if (kcal == null || kcal <= 0) return null;

    return _FoodItem(name: name, kcalPer100g: kcal);
  }

  Future<_FoodItem?> _showFoodSearch(BuildContext context) async {
    final controller = TextEditingController();
    List<_FoodItem> results = [];
    bool loading = false;
    String? error;
    Timer? debounce;
    int searchToken = 0;

    Future<void> runSearch(StateSetter setModalState) async {
      final query = controller.text.trim();
      if (query.isEmpty) return;

      final currentToken = ++searchToken;

      setModalState(() {
        loading = true;
        error = null;
      });

      try {
        final data = await _searchFoods(query);
        if (currentToken != searchToken) return;
        setModalState(() {
          results = data;
          loading = false;
        });
      } catch (e) {
        if (currentToken != searchToken) return;
        setModalState(() {
          loading = false;
          error = 'Impossible de charger les aliments.';
        });
      }
    }

    return showModalBottomSheet<_FoodItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.search),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Ajouter un aliment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un aliment',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: (_) {
                    debounce?.cancel();
                    debounce = Timer(
                      const Duration(milliseconds: 400),
                      () => runSearch(setModalState),
                    );
                  },
                  onSubmitted: (_) => runSearch(setModalState),
                ),
                const SizedBox(height: 12),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  )
                else if (error != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(error!, style: TextStyle(color: Colors.red[700])),
                  )
                else if (results.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Aucun résultat'),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = results[index];
                        return ListTile(
                          title: Text(item.name),
                          subtitle:
                              Text('${item.kcalPer100g.toStringAsFixed(0)} kcal / 100g'),
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<double?> _askPortionGrams(BuildContext context) async {
    final controller = TextEditingController(text: '100');
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quantité consommée'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Grammes',
            suffixText: 'g',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final grams = double.tryParse(controller.text.trim());
              if (grams == null || grams <= 0) return;
              Navigator.pop(context, grams);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _addFoodFromApi(BuildContext context, User user) async {
    final selected = await _showFoodSearch(context);
    if (selected == null) return;

    final grams = await _askPortionGrams(context);
    if (grams == null) return;

    final calories = selected.kcalPer100g * (grams / 100);

    setState(() {
      _ensureCalories(user);
      _remaining = (_remaining! - calories).clamp(0, double.infinity);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${selected.name} ajouté • -${calories.toStringAsFixed(0)} kcal',
        ),
      ),
    );
  }

  Future<void> _scanBarcodeAndAdd(BuildContext context, User user) async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _FoodScannerScreen()),
    );

    if (barcode == null || barcode.isEmpty) return;

    try {
      final food = await _fetchFoodByBarcode(barcode);
      if (food == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produit introuvable pour ce code-barres.'),
          ),
        );
        return;
      }

      final grams = await _askPortionGrams(context);
      if (grams == null) return;

      final calories = food.kcalPer100g * (grams / 100);

      setState(() {
        _ensureCalories(user);
        _remaining = (_remaining! - calories).clamp(0, double.infinity);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${food.name} ajouté • -${calories.toStringAsFixed(0)} kcal',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la lecture du code-barres.'),
        ),
      );
    }
  }

  Widget _buildCalorieCard(BuildContext context, User user) {
    _ensureCalories(user);

    final maintenance = _maintenance!.round();
    final remaining = _remaining!.round();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_fire_department,
                      color: Colors.orange),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Calories de maintien',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    '$maintenance',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'kcal / jour',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Calories restantes',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$remaining kcal',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Estimation basée sur votre âge, taille et poids (activité légère).',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _addCalories(context, user),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter des calories'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _addFoodFromApi(context, user),
                icon: const Icon(Icons.search),
                label: const Text('Ajouter un aliment'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _scanBarcodeAndAdd(context, user),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scanner un code-barres'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          'Connectez-vous pour voir vos calories de maintien.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      children: [
        const Center(
          child: Text(
            'Nutrition',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),
        _buildCalorieCard(context, user),
      ],
    );
  }
}

class _MenuTab extends StatelessWidget {
  const _MenuTab();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Menu', textAlign: TextAlign.center));
}

class _FoodItem {
  final String name;
  final double kcalPer100g;

  const _FoodItem({
    required this.name,
    required this.kcalPer100g,
  });
}

class _FoodScannerScreen extends StatefulWidget {
  const _FoodScannerScreen();

  @override
  State<_FoodScannerScreen> createState() => _FoodScannerScreenState();
}

class _FoodScannerScreenState extends State<_FoodScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _found = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner un code-barres'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_found) return;
              if (capture.barcodes.isEmpty) return;
              final barcode = capture.barcodes.first.rawValue;
              if (barcode == null || barcode.isEmpty) return;
              _found = true;
              Navigator.pop(context, barcode);
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Placez le code-barres dans le cadre',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}