import 'package:flutter/material.dart';
import 'create_workout_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    
    const _TrainingTab(),    // Onglet 1: Entraînement
    const _NutritionTab(),   // Onglet 2: Nutrition
    const _CommunityTab(),   // Onglet 3: Communauté
    const _ProfileTab(),     // Onglet 4: Profil
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
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Training'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Nutrition'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Communauté'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

// Onglet Entraînement (avec bouton création EF-ENT-PROG-1)
class _TrainingTab extends StatelessWidget {
  const _TrainingTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 50),
        const Text(
          'Entraînement',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const Card(
                child: ListTile(
                  leading: Icon(Icons.play_arrow, size: 40),
                  title: Text('Sèance du jour'),
                  subtitle: Text('Haut du corps - 45min'),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: null, // TODO: Nav sèance
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Commencer séance'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateWorkoutScreen()),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Créer un entraînement'), // 👈 TON BOUTON !
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Placeholders autres onglets (specs manuelles)
class _NutritionTab extends StatelessWidget {
  const _NutritionTab();
  @override Widget build(BuildContext context) => const Center(child: Text('Nutrition\nJournal + Scanner', textAlign: TextAlign.center));
}

class _CommunityTab extends StatelessWidget {
  const _CommunityTab();
  @override Widget build(BuildContext context) => const Center(child: Text('Communauté\nForums + Messages', textAlign: TextAlign.center));
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override Widget build(BuildContext context) => const Center(child: Text('Profil\nBadges + Stats', textAlign: TextAlign.center));
}
