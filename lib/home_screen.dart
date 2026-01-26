import 'package:flutter/material.dart';

import 'create_workout_screen.dart';
import 'data/workout_repository.dart';
import 'models.dart';

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
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Training'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Nutrition'),
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

  Future<void> _openCreate() async {
    // Si tu modifies CreateWorkoutScreen pour faire Navigator.pop(context, id) après sauvegarde,
    // _reload() se déclenchera automatiquement.
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateWorkoutScreen()),
    );
    if (res != null) _reload();
  }

  Future<void> _openEdit(int programId) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateWorkoutScreen(programId: programId)),
    );
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

            // "Séance du jour" = dernier programme sauvegardé (cliquable)
            Card(
              child: ListTile(
                leading: const Icon(Icons.play_arrow, size: 40),
                title: const Text('Séance du jour'),
                subtitle: Text(
                  latest == null
                      ? 'Aucun programme'
                      : '${latest.name} - ${latest.duration.toStringAsFixed(0)}min',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: (latest?.id == null) ? null : () => _openEdit(latest!.id!),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: (latest?.id == null) ? null : () => _openEdit(latest!.id!),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Commencer séance'),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _openCreate,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Créer un entraînement'),
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              'Mes programmes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (snap.connectionState != ConnectionState.done)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snap.hasError)
              Text('Erreur: ${snap.error}')
            else if (programs.isEmpty)
              const Text('Aucun programme sauvegardé pour le moment.')
            else
              ...programs.map((p) {
                return Card(
                  child: ListTile(
                    title: Text(p.name),
                    subtitle: Text('${p.exercises.length} exercices • ${p.duration.toStringAsFixed(0)} min'),
                    trailing: const Icon(Icons.edit),
                    onTap: (p.id == null) ? null : () => _openEdit(p.id!),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

// Placeholders autres onglets (specs manuelles)
class _NutritionTab extends StatelessWidget {
  const _NutritionTab();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Nutrition\nJournal + Scanner', textAlign: TextAlign.center));
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
  Widget build(BuildContext context) =>
      const Center(child: Text('Communauté\nForums + Messages', textAlign: TextAlign.center));
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Profil\nBadges + Stats', textAlign: TextAlign.center));
}
