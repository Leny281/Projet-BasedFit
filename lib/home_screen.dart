import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const NutritionPage(),
    const ProgrammePage(),
    const AccueilPage(),
    const ProfilPage(),
    const CommunautePage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accueil')),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, color: Colors.blue), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.food_bank, color: Colors.blue), label: 'Nutrition'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center, color: Colors.blue), label: 'Musculation'),
          BottomNavigationBarItem(icon: Icon(Icons.settings, color: Colors.blue), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.forum, color: Colors.blue), label: 'Communauté')
        ],
      ),
    );
  }
}

class AccueilPage extends StatelessWidget {
  const AccueilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star, size: 100, color: Colors.blue),
          SizedBox(height: 20),
          Text('Bienvenue sur l\'accueil !', style: TextStyle(fontSize: 24)),
          SizedBox(height: 10),
          Text('Utilisez les onglets en bas pour naviguer.'),
        ],
      ),
    );
  }
}

class NutritionPage extends StatelessWidget {
  const NutritionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star, size: 100, color: Colors.blue),
          SizedBox(height: 20),
          Text('Bienvenue sur le truc de bouffe la !', style: TextStyle(fontSize: 24)),
          SizedBox(height: 10),
          Text('Utilisez les onglets en bas pour naviguer.'),
        ],
      ),
    );
  }
}

class ProgrammePage extends StatelessWidget {
  const ProgrammePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star, size: 100, color: Colors.blue),
          SizedBox(height: 20),
          Text('Bienvenue sur creation programme', style: TextStyle(fontSize: 24)),
          SizedBox(height: 10),
          Text('Utilisez les onglets en bas pour naviguer.'),
        ],
      ),
    );
  }
}

class CommunautePage extends StatelessWidget {
  const CommunautePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star, size: 100, color: Colors.blue),
          SizedBox(height: 20),
          Text('Bienvenue sur creation programme', style: TextStyle(fontSize: 24)),
          SizedBox(height: 10),
          Text('Utilisez les onglets en bas pour naviguer.'),
        ],
      ),
    );
  }
}


class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
    );
  }
}
