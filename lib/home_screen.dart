import 'package:flutter/material.dart';

import 'programme_creation/create_workout_screen.dart';
import 'programme_creation/view_workout_screen.dart';
import 'data/workout_repository.dart';
import 'programme_creation/models.dart';

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
    _CommunityTab(),
    _ProfileTab(),
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
class _NutritionTab extends StatelessWidget {
  const _NutritionTab();
  @override
  Widget build(BuildContext context) => const Center(
      child: Text('Nutrition\nJournal + Scanner', textAlign: TextAlign.center));
}

class _MenuTab extends StatelessWidget {
  const _MenuTab();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Menu', textAlign: TextAlign.center));
}

class _CommunityTab extends StatelessWidget {
  const _CommunityTab();
  @override
  Widget build(BuildContext context) => const Center(
      child:
          Text('Communauté\nForums + Messages', textAlign: TextAlign.center));
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) => const Center(
      child: Text('Profil\nBadges + Stats', textAlign: TextAlign.center));
}