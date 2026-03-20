import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'programme_creation/view_workout_screen.dart';
import 'programme_creation/program_creation_choice_screen.dart';
import 'programme_creation/data/workout_repository.dart';
import 'programme_creation/models.dart';
import 'profile_screen.dart';
import 'services/auth_service.dart';
import 'community/community_screen.dart';
import 'models/user_model.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool darkMode;
  const HomeScreen({super.key, this.onToggleTheme, this.darkMode = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  List<Widget> get _tabs => [
    const _MenuTab(),
    const TrainingTab(),
    const _NutritionTab(),
    const CommunityScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BasedFit'),
        actions: [
          IconButton(
            icon: Icon(widget.darkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: widget.darkMode ? 'Mode clair' : 'Mode sombre',
            onPressed: widget.onToggleTheme,
          ),
        ],
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

  /// Ouvrir l'écran de choix de création (manuelle ou IA)
  Future<void> _openCreate() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProgramCreationChoiceScreen()),
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
  double? _goalTotal;
  double? _proteinGoal;
  double? _fatGoal;
  double? _carbGoal;
  double _proteinConsumed = 0;
  double _fatConsumed = 0;
  double _carbConsumed = 0;
  List<_NutritionEntry> _entries = [];
  bool _dailyLoaded = false;

  // Cache en mémoire pour les recherches
  final Map<String, List<_FoodItem>> _searchCache = {};

  
  double _maintenanceCalories(User user) {
    final bmr = (10 * user.weight) + (6.25 * user.height) - (5 * user.age);
    const activityFactor = 1.2; // activité légère par défaut
    return bmr * activityFactor;
  }

  double _goalCalories(User user) {
    final maintenance = _maintenanceCalories(user);
    switch (user.goal) {
      case 'Perte de poids':
        return (maintenance - 300).clamp(1200, double.infinity);
      case 'Prise de masse':
        return maintenance + 300;
      default:
        return maintenance;
    }
  }

  _MacroTargets _macroTargets(User user, double goalCalories) {
    final proteinByGoal = switch (user.goal) {
      'Perte de poids' => 2.0,
      'Prise de masse' => 1.8,
      _ => 1.6,
    };

    final protein = (user.weight * proteinByGoal).clamp(60, 260).toDouble();
    final fat = (user.weight * 0.9).clamp(40, 140).toDouble();
    final carbCalories = goalCalories - (protein * 4) - (fat * 9);
    final carbs = (carbCalories / 4).clamp(0, double.infinity).toDouble();

    return _MacroTargets(protein: protein, fat: fat, carbs: carbs);
  }

  String _dayKey(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  String _prefKey(String name) => 'nutrition_${name}_${_dayKey(DateTime.now())}';

  Future<void> _loadDaily(User user) async {
    if (_dailyLoaded) return;
    final prefs = await SharedPreferences.getInstance();

    final goalKey = _prefKey('goal');
    final remainingKey = _prefKey('remaining');
    final proteinGoalKey = _prefKey('protein_goal');
    final fatGoalKey = _prefKey('fat_goal');
    final carbGoalKey = _prefKey('carb_goal');
    final proteinConsumedKey = _prefKey('protein_consumed');
    final fatConsumedKey = _prefKey('fat_consumed');
    final carbConsumedKey = _prefKey('carb_consumed');
    final entriesKey = _prefKey('entries');

    final storedGoal = prefs.getDouble(goalKey);
    final storedRemaining = prefs.getDouble(remainingKey);
    final storedProteinGoal = prefs.getDouble(proteinGoalKey);
    final storedFatGoal = prefs.getDouble(fatGoalKey);
    final storedCarbGoal = prefs.getDouble(carbGoalKey);
    final storedProteinConsumed = prefs.getDouble(proteinConsumedKey);
    final storedFatConsumed = prefs.getDouble(fatConsumedKey);
    final storedCarbConsumed = prefs.getDouble(carbConsumedKey);
    final storedEntries = prefs.getString(entriesKey);

    final maintenance = _maintenanceCalories(user);
    final goalTotal = _goalCalories(user);
    final defaultMacros = _macroTargets(user, goalTotal);

    final entries = <_NutritionEntry>[];
    if (storedEntries != null && storedEntries.isNotEmpty) {
      try {
        final decoded = jsonDecode(storedEntries);
        if (decoded is List) {
          for (final raw in decoded) {
            if (raw is Map<String, dynamic>) {
              entries.add(_NutritionEntry.fromMap(raw));
            } else if (raw is Map) {
              entries.add(_NutritionEntry.fromMap(Map<String, dynamic>.from(raw)));
            }
          }
        }
      } catch (_) {
        // Ignore malformed history and keep loading app state.
      }
    }

    setState(() {
      _maintenance = maintenance;
      _goalTotal = storedGoal ?? goalTotal;
      _remaining = storedRemaining ?? _goalTotal;
      _proteinGoal = storedProteinGoal ?? defaultMacros.protein;
      _fatGoal = storedFatGoal ?? defaultMacros.fat;
      _carbGoal = storedCarbGoal ?? defaultMacros.carbs;
      _proteinConsumed = storedProteinConsumed ?? 0;
      _fatConsumed = storedFatConsumed ?? 0;
      _carbConsumed = storedCarbConsumed ?? 0;
      _entries = entries;
      _dailyLoaded = true;
    });

    await prefs.setDouble(goalKey, _goalTotal!);
    await prefs.setDouble(remainingKey, _remaining!);
    await prefs.setDouble(proteinGoalKey, _proteinGoal!);
    await prefs.setDouble(fatGoalKey, _fatGoal!);
    await prefs.setDouble(carbGoalKey, _carbGoal!);
    await prefs.setDouble(proteinConsumedKey, _proteinConsumed);
    await prefs.setDouble(fatConsumedKey, _fatConsumed);
    await prefs.setDouble(carbConsumedKey, _carbConsumed);
    await prefs.setString(
      entriesKey,
      jsonEncode(_entries.map((e) => e.toMap()).toList()),
    );
  }

  Future<void> _saveDaily() async {
    if (_goalTotal == null || _remaining == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefKey('goal'), _goalTotal!);
    await prefs.setDouble(_prefKey('remaining'), _remaining!);
    await prefs.setDouble(_prefKey('protein_goal'), _proteinGoal ?? 0);
    await prefs.setDouble(_prefKey('fat_goal'), _fatGoal ?? 0);
    await prefs.setDouble(_prefKey('carb_goal'), _carbGoal ?? 0);
    await prefs.setDouble(_prefKey('protein_consumed'), _proteinConsumed);
    await prefs.setDouble(_prefKey('fat_consumed'), _fatConsumed);
    await prefs.setDouble(_prefKey('carb_consumed'), _carbConsumed);
    await prefs.setString(
      _prefKey('entries'),
      jsonEncode(_entries.map((e) => e.toMap()).toList()),
    );
  }

  Future<void> _registerEntry(User user, _NutritionEntry entry) async {
    setState(() {
      _ensureCalories(user);
      _remaining = (_remaining! - entry.calories).clamp(0, double.infinity);
      _proteinConsumed += entry.protein;
      _fatConsumed += entry.fat;
      _carbConsumed += entry.carbs;
      _entries.insert(0, entry);
    });

    await _saveDaily();
  }

  Future<void> _deleteEntry(User user, _NutritionEntry entry) async {
    setState(() {
      _ensureCalories(user);
      _entries.removeWhere((e) => e.id == entry.id);
      _remaining = (_remaining! + entry.calories)
          .clamp(0, _goalTotal ?? double.infinity);
      _proteinConsumed = (_proteinConsumed - entry.protein).clamp(0, double.infinity);
      _fatConsumed = (_fatConsumed - entry.fat).clamp(0, double.infinity);
      _carbConsumed = (_carbConsumed - entry.carbs).clamp(0, double.infinity);
    });

    await _saveDaily();
  }

  Future<void> _updateEntry(
    User user,
    _NutritionEntry previous,
    _NutritionEntry updated,
  ) async {
    setState(() {
      _ensureCalories(user);

      _remaining = (_remaining! + previous.calories - updated.calories)
          .clamp(0, _goalTotal ?? double.infinity);
      _proteinConsumed =
          (_proteinConsumed - previous.protein + updated.protein)
              .clamp(0, double.infinity);
      _fatConsumed = (_fatConsumed - previous.fat + updated.fat)
          .clamp(0, double.infinity);
      _carbConsumed = (_carbConsumed - previous.carbs + updated.carbs)
          .clamp(0, double.infinity);

      final index = _entries.indexWhere((e) => e.id == previous.id);
      if (index != -1) {
        _entries[index] = updated;
      }
    });

    await _saveDaily();
  }

  Future<void> _editEntryQuantity(User user, _NutritionEntry entry) async {
    final per100Kcal = entry.kcalPer100g;
    if (per100Kcal == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seules les entrées alimentaires peuvent modifier la quantité.',
          ),
        ),
      );
      return;
    }

    final currentGrams = entry.quantityGrams ?? 100;
    final updatedGrams = await _askPortionGrams(
      context,
      initialValue: currentGrams,
      title: 'Modifier la quantité',
      confirmLabel: 'Mettre à jour',
    );
    if (updatedGrams == null) return;

    final ratio = updatedGrams / 100;
    final updated = entry.copyWith(
      quantityGrams: updatedGrams,
      calories: per100Kcal * ratio,
      protein: (entry.proteinPer100g ?? 0) * ratio,
      fat: (entry.fatPer100g ?? 0) * ratio,
      carbs: (entry.carbPer100g ?? 0) * ratio,
      label: '${entry.itemName} (${updatedGrams.toStringAsFixed(0)} g)',
    );

    await _updateEntry(user, entry, updated);
  }

  void _ensureCalories(User user) {
    final maintenance = _maintenanceCalories(user);
    final goalTotal = _goalCalories(user);
    final macros = _macroTargets(user, goalTotal);
    if (_maintenance == null || _remaining == null || _goalTotal == null) {
      _maintenance = maintenance;
      _goalTotal = goalTotal;
      _remaining = _remaining ?? goalTotal;
      _proteinGoal = _proteinGoal ?? macros.protein;
      _fatGoal = _fatGoal ?? macros.fat;
      _carbGoal = _carbGoal ?? macros.carbs;
      return;
    }

    _proteinGoal = _proteinGoal ?? macros.protein;
    _fatGoal = _fatGoal ?? macros.fat;
    _carbGoal = _carbGoal ?? macros.carbs;
  }

  Future<void> _addCalories(BuildContext context, User user) async {
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final fatController = TextEditingController();
    final carbController = TextEditingController();

    final entry = await showDialog<_QuickNutritionEntry>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajout rapide'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Calories consommées',
                  prefixIcon: Icon(Icons.restaurant),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: proteinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Protéines (g) - optionnel',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: fatController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Lipides (g) - optionnel',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: carbController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Glucides (g) - optionnel',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final calories = double.tryParse(caloriesController.text.trim());
              if (calories == null || calories <= 0) {
                return;
              }

              final protein = double.tryParse(proteinController.text.trim()) ?? 0;
              final fat = double.tryParse(fatController.text.trim()) ?? 0;
              final carbs = double.tryParse(carbController.text.trim()) ?? 0;

              Navigator.pop(
                context,
                _QuickNutritionEntry(
                  calories: calories,
                  protein: protein < 0 ? 0 : protein,
                  fat: fat < 0 ? 0 : fat,
                  carbs: carbs < 0 ? 0 : carbs,
                ),
              );
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (entry == null) return;

    await _registerEntry(
      user,
      _NutritionEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        itemName: 'Ajout rapide',
        label: 'Ajout rapide',
        calories: entry.calories,
        protein: entry.protein,
        fat: entry.fat,
        carbs: entry.carbs,
        source: 'quick',
        createdAt: DateTime.now(),
      ),
    );
  }

/// ──────────────────────────────────────────────
  /// RECHERCHE RAPIDE — requête légère + cache
  /// ──────────────────────────────────────────────
  Future<List<_FoodItem>> _searchFoods(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    // 1) Cache mémoire
    if (_searchCache.containsKey(q)) {
      return _searchCache[q]!;
    }

    // 2) Requête légère : peu de champs, peu de résultats
    final uri = Uri.https(
      'world.openfoodfacts.net',          // serveur miroir, souvent plus rapide
      '/cgi/search.pl',
      {
        'search_terms': q,
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '10',               // 10 au lieu de 20 = 2× plus rapide
        'fields': 'product_name,nutriments',
        'sort_by': 'popularity',          // produits populaires en premier
      },
    );

    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'BasedFit/1.0 (Flutter)',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return [];

      final products = body['products'];
      if (products is! List) return [];

      final items = <_FoodItem>[];

      for (final p in products) {
        if (p is! Map) continue;

        // Nom
        final name = (p['product_name'] ?? '').toString().trim();
        if (name.isEmpty) continue;

        // Calories
        final n = p['nutriments'];
        if (n is! Map) continue;

        final raw = n['energy-kcal_100g'] ?? n['energy-kcal'];
        if (raw == null) continue;

        final kcal = raw is num ? raw.toDouble() : double.tryParse('$raw');
        if (kcal == null || kcal <= 0) continue;

        final protein = _toDouble(n['proteins_100g']);
        final fat = _toDouble(n['fat_100g']);
        final carbs = _toDouble(n['carbohydrates_100g']);

        items.add(
          _FoodItem(
            name: name,
            kcalPer100g: kcal,
            proteinPer100g: protein,
            fatPer100g: fat,
            carbPer100g: carbs,
          ),
        );
      }

      _searchCache[q] = items;
      return items;
    } catch (_) {
      return [];
    }
  }

  /// ──────────────────────────────────────────────
  /// SCAN CODE-BARRES
  /// ──────────────────────────────────────────────
  Future<_FoodItem?> _fetchFoodByBarcode(String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty) return null;

    final uri = Uri.https(
      'world.openfoodfacts.net',
      '/api/v2/product/$code.json',
      {'fields': 'product_name,product_name_fr,nutriments'},
    );

    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'BasedFit/1.0 (Flutter)',
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;

      final product = body['product'];
      if (product is! Map) return null;

      final name = _pickName(product);
      if (name == null) return null;

      final n = product['nutriments'];
      if (n is! Map) return null;

      final raw = n['energy-kcal_100g'] ?? n['energy-kcal'];
      if (raw == null) return null;

      final kcal = raw is num ? raw.toDouble() : double.tryParse('$raw');
      if (kcal == null || kcal <= 0) return null;

      final protein = _toDouble(n['proteins_100g']);
      final fat = _toDouble(n['fat_100g']);
      final carbs = _toDouble(n['carbohydrates_100g']);

      return _FoodItem(
        name: name,
        kcalPer100g: kcal,
        proteinPer100g: protein,
        fatPer100g: fat,
        carbPer100g: carbs,
      );
    } catch (_) {
      return null;
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  String? _pickName(Map product) {
    for (final key in ['product_name', 'product_name_fr', 'product_name_en']) {
      final v = (product[key] ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  /// ──────────────────────────────────────────────
  /// POPUP DE RECHERCHE — simple et réactive
  /// ──────────────────────────────────────────────
  Future<_FoodItem?> _showFoodSearch(BuildContext context) async {
    final controller = TextEditingController();
    Timer? debounce;
    List<_FoodItem> results = [];
    bool loading = false;
    int token = 0;

    return showModalBottomSheet<_FoodItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {

          Future<void> search() async {
            final q = controller.text.trim();
            if (q.isEmpty) {
              setModalState(() { results = []; loading = false; });
              return;
            }

            final myToken = ++token;
            setModalState(() => loading = true);

            final data = await _searchFoods(q);

            // Ignorer si une nouvelle recherche a été lancée entre-temps
            if (myToken != token) return;

            setModalState(() { results = data; loading = false; });
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Titre
                const Text(
                  'Rechercher un aliment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Champ de recherche
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Ex : pomme, riz, yaourt…',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: (_) {
                    debounce?.cancel();
                    debounce = Timer(
                      const Duration(milliseconds: 600),
                      search,
                    );
                  },
                  onSubmitted: (_) {
                    debounce?.cancel();
                    search();
                  },
                ),
                const SizedBox(height: 12),

                // État : chargement
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Recherche…'),
                      ],
                    ),
                  )

                // État : aucun résultat
                else if (!loading && results.isEmpty && controller.text.trim().isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Aucun résultat.', style: TextStyle(color: Colors.grey)),
                  )

                // État : résultats
                else if (results.isNotEmpty)
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final item = results[i];
                        return ListTile(
                          leading: const Icon(Icons.restaurant, color: Colors.green),
                          title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${item.kcalPer100g.toStringAsFixed(0)} kcal / 100g'),
                          onTap: () => Navigator.pop(ctx, item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      debounce?.cancel();
      controller.dispose();
    });
  }

  Future<double?> _askPortionGrams(
    BuildContext context, {
    double initialValue = 100,
    String title = 'Quantité consommée',
    String confirmLabel = 'Ajouter',
  }) async {
    final controller = TextEditingController(
      text: initialValue.toStringAsFixed(initialValue % 1 == 0 ? 0 : 1),
    );
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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
            child: Text(confirmLabel),
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
    final proteins = (selected.proteinPer100g ?? 0) * (grams / 100);
    final fats = (selected.fatPer100g ?? 0) * (grams / 100);
    final carbs = (selected.carbPer100g ?? 0) * (grams / 100);

    await _registerEntry(
      user,
      _NutritionEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        itemName: selected.name,
        label: '${selected.name} (${grams.toStringAsFixed(0)} g)',
        calories: calories,
        protein: proteins,
        fat: fats,
        carbs: carbs,
        source: 'food',
        quantityGrams: grams,
        kcalPer100g: selected.kcalPer100g,
        proteinPer100g: selected.proteinPer100g,
        fatPer100g: selected.fatPer100g,
        carbPer100g: selected.carbPer100g,
        createdAt: DateTime.now(),
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${selected.name} ajouté • -${calories.toStringAsFixed(0)} kcal'
          '${(proteins + fats + carbs) > 0 ? ' • P ${proteins.toStringAsFixed(1)}g | L ${fats.toStringAsFixed(1)}g | G ${carbs.toStringAsFixed(1)}g' : ''}',
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
      final proteins = (food.proteinPer100g ?? 0) * (grams / 100);
      final fats = (food.fatPer100g ?? 0) * (grams / 100);
      final carbs = (food.carbPer100g ?? 0) * (grams / 100);

      await _registerEntry(
        user,
        _NutritionEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          itemName: food.name,
          label: '${food.name} (${grams.toStringAsFixed(0)} g)',
          calories: calories,
          protein: proteins,
          fat: fats,
          carbs: carbs,
          source: 'barcode',
          quantityGrams: grams,
          kcalPer100g: food.kcalPer100g,
          proteinPer100g: food.proteinPer100g,
          fatPer100g: food.fatPer100g,
          carbPer100g: food.carbPer100g,
          createdAt: DateTime.now(),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${food.name} ajouté • -${calories.toStringAsFixed(0)} kcal'
            '${(proteins + fats + carbs) > 0 ? ' • P ${proteins.toStringAsFixed(1)}g | L ${fats.toStringAsFixed(1)}g | G ${carbs.toStringAsFixed(1)}g' : ''}',
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
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildMacroRow(
                    label: 'Protéines',
                    consumed: _proteinConsumed,
                    goal: _proteinGoal ?? 0,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 10),
                  _buildMacroRow(
                    label: 'Lipides',
                    consumed: _fatConsumed,
                    goal: _fatGoal ?? 0,
                    color: Colors.amber[800]!,
                  ),
                  const SizedBox(height: 10),
                  _buildMacroRow(
                    label: 'Glucides',
                    consumed: _carbConsumed,
                    goal: _carbGoal ?? 0,
                    color: Colors.deepPurple,
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
            const SizedBox(height: 14),
            _buildEntriesHistory(user),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesHistory(User user) {
    if (_entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Historique du jour vide. Ajoutez un aliment ou un ajout rapide.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historique du jour',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          itemCount: _entries.length,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final entry = _entries[index];
            final createdAt =
                '${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}';

            return InkWell(
              onTap: () => _editEntryQuantity(user, entry),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${entry.calories.toStringAsFixed(0)} kcal • P ${entry.protein.toStringAsFixed(1)}g • L ${entry.fat.toStringAsFixed(1)}g • G ${entry.carbs.toStringAsFixed(1)}g',
                            style: TextStyle(color: Colors.grey[700], fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.kcalPer100g == null
                                ? '$createdAt • non modifiable en quantité'
                                : '$createdAt • toucher pour modifier la quantité',
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Supprimer',
                      onPressed: () => _deleteEntry(user, entry),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMacroRow({
    required String label,
    required double consumed,
    required double goal,
    required Color color,
  }) {
    final safeGoal = goal <= 0 ? 1 : goal;
    final progress = (consumed / safeGoal).clamp(0.0, 1.0);
    final remaining = (goal - consumed).clamp(0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '${consumed.toStringAsFixed(1)} / ${goal.toStringAsFixed(1)} g',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progress,
            color: color,
            backgroundColor: Colors.grey[300],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${remaining.toStringAsFixed(1)} g restants',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
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

    if (!_dailyLoaded) {
      _loadDaily(user);
      return const Center(child: CircularProgressIndicator());
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
  Widget build(BuildContext context) => const _MenuCaloriesOverview();
}

class _MenuCaloriesOverview extends StatefulWidget {
  const _MenuCaloriesOverview();

  @override
  State<_MenuCaloriesOverview> createState() => _MenuCaloriesOverviewState();
}

class _MenuCaloriesOverviewState extends State<_MenuCaloriesOverview> {
  double? _goalTotal;
  double? _remaining;
  double _proteinConsumed = 0;
  double _fatConsumed = 0;
  double _carbConsumed = 0;
  double _proteinGoal = 0;
  double _fatGoal = 0;
  double _carbGoal = 0;
  bool _loading = true;

  double _maintenanceCalories(User user) {
    final bmr = (10 * user.weight) + (6.25 * user.height) - (5 * user.age);
    const activityFactor = 1.2;
    return bmr * activityFactor;
  }

  double _goalCalories(User user) {
    final maintenance = _maintenanceCalories(user);
    switch (user.goal) {
      case 'Perte de poids':
        return (maintenance - 300).clamp(1200, double.infinity);
      case 'Prise de masse':
        return maintenance + 300;
      default:
        return maintenance;
    }
  }

  String _dayKey(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  String _prefKey(String name) => 'nutrition_${name}_${_dayKey(DateTime.now())}';

  Future<void> _load(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final goalKey = _prefKey('goal');
    final remainingKey = _prefKey('remaining');

    final storedGoal = prefs.getDouble(goalKey);
    final storedRemaining = prefs.getDouble(remainingKey);
    final storedProteinConsumed = prefs.getDouble(_prefKey('protein_consumed'));
    final storedFatConsumed = prefs.getDouble(_prefKey('fat_consumed'));
    final storedCarbConsumed = prefs.getDouble(_prefKey('carb_consumed'));
    final storedProteinGoal = prefs.getDouble(_prefKey('protein_goal'));
    final storedFatGoal = prefs.getDouble(_prefKey('fat_goal'));
    final storedCarbGoal = prefs.getDouble(_prefKey('carb_goal'));

    final goalTotal = storedGoal ?? _goalCalories(user);
    final remaining = storedRemaining ?? goalTotal;

    if (!mounted) return;
    setState(() {
      _goalTotal = goalTotal;
      _remaining = remaining;
      _proteinConsumed = storedProteinConsumed ?? 0;
      _fatConsumed = storedFatConsumed ?? 0;
      _carbConsumed = storedCarbConsumed ?? 0;
      _proteinGoal = storedProteinGoal ?? 0;
      _fatGoal = storedFatGoal ?? 0;
      _carbGoal = storedCarbGoal ?? 0;
      _loading = false;
    });
  }

  Widget _buildMacroSummaryRow({
    required String label,
    required double consumed,
    required double goal,
    required Color color,
  }) {
    final safeGoal = goal <= 0 ? 1 : goal;
    final progress = (consumed / safeGoal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              '${consumed.toStringAsFixed(1)} / ${goal.toStringAsFixed(1)} g',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          minHeight: 7,
          value: progress,
          color: color,
          backgroundColor: Colors.grey[300],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) {
      return const Center(
        child: Text('Connectez-vous pour voir vos calories.'),
      );
    }

    if (_loading) {
      _load(user);
      return const Center(child: CircularProgressIndicator());
    }

    final goal = (_goalTotal ?? 0).round();
    final remaining = (_remaining ?? 0).round();
    final consumed = (goal - remaining).clamp(0, goal);
    final progress = goal == 0 ? 0.0 : consumed / goal;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      children: [
        const Center(
          child: Text(
            'Menu',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calories du jour',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final gaugeWidth = constraints.maxWidth;
                    final fillWidth = (gaugeWidth * progress.clamp(0.0, 1.0));

                    return Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              height: 22,
                              width: gaugeWidth,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            Container(
                              height: 22,
                              width: fillWidth,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$remaining kcal restantes',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Objectif: $goal kcal',
                      style: TextStyle(color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Consommées: ${goal - remaining} kcal',
                      style: TextStyle(color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Macros du jour',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildMacroSummaryRow(
                      label: 'Protéines',
                      consumed: _proteinConsumed,
                      goal: _proteinGoal,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildMacroSummaryRow(
                      label: 'Lipides',
                      consumed: _fatConsumed,
                      goal: _fatGoal,
                      color: Colors.amber[800]!,
                    ),
                    const SizedBox(height: 8),
                    _buildMacroSummaryRow(
                      label: 'Glucides',
                      consumed: _carbConsumed,
                      goal: _carbGoal,
                      color: Colors.deepPurple,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FoodItem {
  final String name;
  final double kcalPer100g;
  final double? proteinPer100g;
  final double? fatPer100g;
  final double? carbPer100g;

  const _FoodItem({
    required this.name,
    required this.kcalPer100g,
    this.proteinPer100g,
    this.fatPer100g,
    this.carbPer100g,
  });
}

class _MacroTargets {
  final double protein;
  final double fat;
  final double carbs;

  const _MacroTargets({
    required this.protein,
    required this.fat,
    required this.carbs,
  });
}

class _QuickNutritionEntry {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;

  const _QuickNutritionEntry({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });
}

class _NutritionEntry {
  final String id;
  final String itemName;
  final String label;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final String source;
  final double? quantityGrams;
  final double? kcalPer100g;
  final double? proteinPer100g;
  final double? fatPer100g;
  final double? carbPer100g;
  final DateTime createdAt;

  const _NutritionEntry({
    required this.id,
    required this.itemName,
    required this.label,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.source,
    this.quantityGrams,
    this.kcalPer100g,
    this.proteinPer100g,
    this.fatPer100g,
    this.carbPer100g,
    required this.createdAt,
  });

  _NutritionEntry copyWith({
    String? id,
    String? itemName,
    String? label,
    double? calories,
    double? protein,
    double? fat,
    double? carbs,
    String? source,
    double? quantityGrams,
    double? kcalPer100g,
    double? proteinPer100g,
    double? fatPer100g,
    double? carbPer100g,
    DateTime? createdAt,
  }) {
    return _NutritionEntry(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      label: label ?? this.label,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      source: source ?? this.source,
      quantityGrams: quantityGrams ?? this.quantityGrams,
      kcalPer100g: kcalPer100g ?? this.kcalPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      carbPer100g: carbPer100g ?? this.carbPer100g,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_name': itemName,
      'label': label,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'source': source,
      'quantity_grams': quantityGrams,
      'kcal_100g': kcalPer100g,
      'protein_100g': proteinPer100g,
      'fat_100g': fatPer100g,
      'carb_100g': carbPer100g,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory _NutritionEntry.fromMap(Map<String, dynamic> map) {
    final label = map['label']?.toString() ?? 'Entrée';
    final fallbackItemName = label.contains(' (')
        ? label.split(' (').first
        : label;

    return _NutritionEntry(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      itemName: map['item_name']?.toString() ?? fallbackItemName,
      label: label,
      calories: (map['calories'] as num?)?.toDouble() ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
      source: map['source']?.toString() ?? 'unknown',
      quantityGrams: (map['quantity_grams'] as num?)?.toDouble(),
      kcalPer100g: (map['kcal_100g'] as num?)?.toDouble(),
      proteinPer100g: (map['protein_100g'] as num?)?.toDouble(),
      fatPer100g: (map['fat_100g'] as num?)?.toDouble(),
      carbPer100g: (map['carb_100g'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
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