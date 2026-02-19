import 'package:flutter/material.dart';
import '../services/ai_program_service.dart';
import 'create_workout_screen.dart';

/// Écran de questionnaire pour la génération de programme par IA
class AiQuestionnaireScreen extends StatefulWidget {
  const AiQuestionnaireScreen({super.key});

  @override
  State<AiQuestionnaireScreen> createState() => _AiQuestionnaireScreenState();
}

class _AiQuestionnaireScreenState extends State<AiQuestionnaireScreen> {
  final PageController _pageController = PageController();
  final AiProgramService _aiService = AiProgramService();
  
  int _currentPage = 0;
  bool _isGenerating = false;

  // Réponses du questionnaire
  String? _goal;
  String? _level;
  int? _daysPerWeek;
  List<String> _equipment = [];
  List<String> _targetMuscles = [];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _generateProgram() async {
    if (_goal == null || _level == null || _daysPerWeek == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez répondre à toutes les questions obligatoires'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      print('🚀 Démarrage de la génération du programme...');
      
      final program = await _aiService.generateProgram(
        goal: _goal!,
        level: _level!,
        daysPerWeek: _daysPerWeek!,
        equipment: _equipment,
        targetMuscles: _targetMuscles,
      );

      print('✅ Programme généré: ${program.name}');
      print('   Exercices: ${program.exercises.length}');
      
      if (!mounted) return;

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Programme "${program.name}" créé avec ${program.exercises.length} exercices !'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Naviguer vers l'écran d'édition avec le programme généré
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CreateWorkoutScreen(existingProgram: program),
        ),
      );
    } catch (e, stackTrace) {
      print('❌ Erreur lors de la génération: $e');
      print('Stack trace: $stackTrace');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: _generateProgram,
          ),
        ),
      );
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant IA'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          // Indicateur de progression
          LinearProgressIndicator(
            value: (_currentPage + 1) / 5,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
          ),
          
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              children: [
                _buildGoalPage(),
                _buildLevelPage(),
                _buildDaysPage(),
                _buildEquipmentPage(),
                _buildTargetMusclesPage(),
              ],
            ),
          ),
          
          // Boutons de navigation
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildGoalPage() {
    return _QuestionPage(
      question: 'Quel est votre objectif principal ?',
      icon: Icons.flag,
      children: [
        _OptionCard(
          title: 'Perte de poids',
          icon: Icons.trending_down,
          isSelected: _goal == 'perte_poids',
          onTap: () => setState(() => _goal = 'perte_poids'),
        ),
        _OptionCard(
          title: 'Prise de masse musculaire',
          icon: Icons.fitness_center,
          isSelected: _goal == 'prise_masse',
          onTap: () => setState(() => _goal = 'prise_masse'),
        ),
        _OptionCard(
          title: 'Maintien / Tonification',
          icon: Icons.balance,
          isSelected: _goal == 'maintien',
          onTap: () => setState(() => _goal = 'maintien'),
        ),
        _OptionCard(
          title: 'Sèche',
          icon: Icons.water_drop,
          isSelected: _goal == 'seche',
          onTap: () => setState(() => _goal = 'seche'),
        ),
      ],
    );
  }

  Widget _buildLevelPage() {
    return _QuestionPage(
      question: 'Quel est votre niveau d\'entraînement ?',
      icon: Icons.bar_chart,
      children: [
        _OptionCard(
          title: 'Débutant',
          subtitle: 'Moins de 6 mois d\'expérience',
          icon: Icons.navigation,
          isSelected: _level == 'debutant',
          onTap: () => setState(() => _level = 'debutant'),
        ),
        _OptionCard(
          title: 'Intermédiaire',
          subtitle: '6 mois à 2 ans d\'expérience',
          icon: Icons.trending_up,
          isSelected: _level == 'intermediaire',
          onTap: () => setState(() => _level = 'intermediaire'),
        ),
        _OptionCard(
          title: 'Avancé',
          subtitle: 'Plus de 2 ans d\'expérience',
          icon: Icons.emoji_events,
          isSelected: _level == 'avance',
          onTap: () => setState(() => _level = 'avance'),
        ),
      ],
    );
  }

  Widget _buildDaysPage() {
    return _QuestionPage(
      question: 'Combien de jours par semaine pouvez-vous vous entraîner ?',
      icon: Icons.calendar_today,
      children: List.generate(7, (index) {
        final days = index + 1;
        return _OptionCard(
          title: '$days jour${days > 1 ? 's' : ''} par semaine',
          icon: Icons.event,
          isSelected: _daysPerWeek == days,
          onTap: () => setState(() => _daysPerWeek = days),
        );
      }),
    );
  }

  Widget _buildEquipmentPage() {
    final equipmentOptions = [
      {'key': 'poids_corps', 'title': 'Poids du corps', 'icon': Icons.accessibility_new},
      {'key': 'halteres', 'title': 'Haltères', 'icon': Icons.fitness_center},
      {'key': 'barres', 'title': 'Barres', 'icon': Icons.horizontal_rule},
      {'key': 'machines', 'title': 'Machines', 'icon': Icons.settings},
      {'key': 'elastiques', 'title': 'Élastiques', 'icon': Icons.settings_ethernet},
      {'key': 'kettlebells', 'title': 'Kettlebells', 'icon': Icons.sports_handball},
    ];

    return _QuestionPage(
      question: 'Quel équipement avez-vous à disposition ?',
      subtitle: 'Sélectionnez tout ce qui s\'applique',
      icon: Icons.construction,
      children: equipmentOptions.map((option) {
        final key = option['key'] as String;
        final title = option['title'] as String;
        final icon = option['icon'] as IconData;
        
        return _OptionCard(
          title: title,
          icon: icon,
          isSelected: _equipment.contains(key),
          onTap: () {
            setState(() {
              if (_equipment.contains(key)) {
                _equipment.remove(key);
              } else {
                _equipment.add(key);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildTargetMusclesPage() {
    final muscleOptions = [
      {'key': 'pectoraux', 'title': 'Pectoraux', 'icon': Icons.favorite},
      {'key': 'dos', 'title': 'Dos', 'icon': Icons.accessibility},
      {'key': 'epaules', 'title': 'Épaules', 'icon': Icons.pan_tool},
      {'key': 'bras', 'title': 'Bras', 'icon': Icons.sports_martial_arts},
      {'key': 'jambes', 'title': 'Jambes', 'icon': Icons.directions_walk},
      {'key': 'abdominaux', 'title': 'Abdominaux', 'icon': Icons.person},
      {'key': 'fullbody', 'title': 'Corps entier', 'icon': Icons.accessibility_new},
    ];

    return _QuestionPage(
      question: 'Quelles zones musculaires souhaitez-vous cibler ?',
      subtitle: 'Sélectionnez tout ce qui s\'applique',
      icon: Icons.psychology,
      children: muscleOptions.map((option) {
        final key = option['key'] as String;
        final title = option['title'] as String;
        final icon = option['icon'] as IconData;
        
        return _OptionCard(
          title: title,
          icon: icon,
          isSelected: _targetMuscles.contains(key),
          onTap: () {
            setState(() {
              if (_targetMuscles.contains(key)) {
                _targetMuscles.remove(key);
              } else {
                _targetMuscles.add(key);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isGenerating ? null : _previousPage,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Précédent'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : (_currentPage < 4 ? _nextPage : _generateProgram),
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(_currentPage < 4 ? Icons.arrow_forward : Icons.auto_awesome),
              label: Text(_isGenerating
                  ? 'Génération...'
                  : _currentPage < 4
                      ? 'Suivant'
                      : 'Générer mon programme'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionPage extends StatelessWidget {
  final String question;
  final String? subtitle;
  final IconData icon;
  final List<Widget> children;

  const _QuestionPage({
    required this.question,
    this.subtitle,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.purple),
          const SizedBox(height: 24),
          Text(
            question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
          const SizedBox(height: 32),
          ...children,
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: isSelected ? 6 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.purple : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: isSelected ? Colors.purple : Colors.grey[600],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.purple : Colors.black,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.purple,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
