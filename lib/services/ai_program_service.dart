import 'dart:convert';
import 'package:http/http.dart' as http;
import '../programme_creation/models.dart';
import '../programme_creation/data/exercise_catalog_service.dart';

/// Service pour la génération automatique de programmes d'entraînement par IA
class AiProgramService {
  // Note: Pour la production, stockez cette clé dans un fichier de configuration sécurisé
  // ou utilisez une variable d'environnement
  static const String _apiKey = 'YOUR_API_KEY_HERE'; // À remplacer
  static const String _apiEndpoint = 'https://api.openai.com/v1/chat/completions';
  
  final ExerciseCatalogService _catalog = ExerciseCatalogService();

  /// Génère un programme d'entraînement personnalisé basé sur les préférences de l'utilisateur
  Future<WorkoutProgram> generateProgram({
    required String goal,
    required String level,
    required int daysPerWeek,
    required List<String> equipment,
    required List<String> targetMuscles,
  }) async {
    print('🤖 Génération de programme IA...');
    print('Goal: $goal, Level: $level, Days: $daysPerWeek');
    print('Equipment: $equipment');
    print('Muscles: $targetMuscles');
    
    // 1. Récupérer les exercices disponibles
    final allExercises = await _catalog.fetchExercises();
    print('✅ ${allExercises.length} exercices chargés depuis l\'API');
    
    // 2. Filtrer les exercices selon l'équipement disponible
    List<Exercise> availableExercises;
    if (equipment.isEmpty) {
      // Si aucun équipement sélectionné, utiliser tous les exercices
      availableExercises = allExercises;
      print('ℹ️ Aucun équipement spécifié, utilisation de tous les exercices');
    } else {
      availableExercises = _filterExercisesByEquipment(allExercises, equipment);
      print('✅ ${availableExercises.length} exercices après filtrage par équipement');
    }
    
    // Si le filtrage a tout retiré, utiliser tous les exercices
    if (availableExercises.isEmpty) {
      print('⚠️ Le filtrage a retiré tous les exercices, utilisation de tous');
      availableExercises = allExercises;
    }
    
    // 3. Essayer l'API IA si configurée, sinon utiliser le fallback
    if (_apiKey == 'YOUR_API_KEY_HERE') {
      print('ℹ️ Clé API non configurée, utilisation du mode fallback');
      return _generateFallbackProgram(
        goal: goal,
        level: level,
        daysPerWeek: daysPerWeek,
        availableExercises: availableExercises,
        targetMuscles: targetMuscles,
      );
    }
    
    // 4. Tenter d'utiliser l'API IA
    try {
      print('🔄 Appel de l\'API OpenAI...');
      final prompt = _buildPrompt(
        goal: goal,
        level: level,
        daysPerWeek: daysPerWeek,
        equipment: equipment,
        targetMuscles: targetMuscles,
        availableExercises: availableExercises,
      );
      
      final aiResponse = await _callAiApi(prompt);
      print('✅ Réponse reçue de l\'API');
      
      final program = _parseAiResponse(aiResponse, availableExercises);
      print('✅ Programme généré avec succès par IA');
      
      return program;
    } catch (e) {
      print('⚠️ Erreur API: $e');
      print('🔄 Utilisation du mode fallback...');
      
      return _generateFallbackProgram(
        goal: goal,
        level: level,
        daysPerWeek: daysPerWeek,
        availableExercises: availableExercises,
        targetMuscles: targetMuscles,
      );
    }
  }

  /// Filtre les exercices selon l'équipement disponible
  List<Exercise> _filterExercisesByEquipment(
    List<Exercise> exercises,
    List<String> equipment,
  ) {
    if (equipment.isEmpty) return exercises;
    
    // Mapping des équipements
    final equipmentMapping = {
      'poids_corps': ['bodyweight', 'body only', 'none'],
      'halteres': ['dumbbell', 'dumbbells'],
      'barres': ['barbell', 'ez curl bar'],
      'machines': ['machine', 'cable'],
      'elastiques': ['bands', 'exercise band'],
      'kettlebells': ['kettlebells'],
    };
    
    final allowedEquipment = <String>{};
    for (final eq in equipment) {
      allowedEquipment.addAll(equipmentMapping[eq] ?? []);
    }
    
    return exercises.where((ex) {
      final equipmentLower = ex.equipment.toLowerCase();
      return allowedEquipment.any((allowed) => equipmentLower.contains(allowed));
    }).toList();
  }

  /// Construit le prompt pour l'IA
  String _buildPrompt({
    required String goal,
    required String level,
    required int daysPerWeek,
    required List<String> equipment,
    required List<String> targetMuscles,
    required List<Exercise> availableExercises,
  }) {
    final goalText = _translateGoal(goal);
    final levelText = _translateLevel(level);
    final musclesText = targetMuscles.isEmpty ? 'Corps entier' : targetMuscles.join(', ');
    
    // Créer une liste simplifiée des exercices disponibles (limitée pour ne pas dépasser le token limit)
    final exercisesList = availableExercises.take(50).map((ex) {
      return '${ex.name} (${ex.muscleGroup}, ${ex.equipment})';
    }).join(', ');
    
    return '''
Crée un programme d'entraînement personnalisé avec les paramètres suivants:
- Objectif: $goalText
- Niveau: $levelText
- Nombre de jours par semaine: $daysPerWeek
- Zones musculaires ciblées: $musclesText
- Équipement disponible: ${equipment.join(', ')}

Exercices disponibles (utilise uniquement ces exercices): $exercisesList

Réponds UNIQUEMENT avec un JSON au format suivant (sans texte avant ou après):
{
  "name": "Nom du programme",
  "exercises": [
    {
      "exerciseName": "Nom exact de l'exercice",
      "sets": nombre de séries,
      "reps": nombre de répétitions,
      "weight": poids suggéré en kg,
      "rest": temps de repos en secondes,
      "notes": "conseils pour cet exercice"
    }
  ]
}

Règles:
- Pour débutant: 2-3 séries, poids légers
- Pour intermédiaire: 3-4 séries, poids modérés
- Pour avancé: 4-5 séries, poids élevés
- Équilibre les groupes musculaires
- Adapte le volume au nombre de jours
''';
  }

  /// Appelle l'API IA (OpenAI GPT)
  Future<String> _callAiApi(String prompt) async {
    // Si pas de clé API configurée, lever une exception
    if (_apiKey == 'YOUR_API_KEY_HERE') {
      throw Exception('Clé API non configurée');
    }
    
    final response = await http.post(
      Uri.parse(_apiEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': 'Tu es un coach sportif expert en création de programmes d\'entraînement personnalisés.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.7,
        'max_tokens': 1500,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur API: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  }

  /// Parse la réponse de l'IA et crée un WorkoutProgram
  WorkoutProgram _parseAiResponse(String aiResponse, List<Exercise> availableExercises) {
    try {
      // Nettoyer la réponse (enlever markdown, espaces, etc.)
      String cleanedResponse = aiResponse.trim();
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      }
      if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      
      final data = jsonDecode(cleanedResponse.trim());
      
      final programName = data['name'] as String;
      final exercisesData = data['exercises'] as List;
      
      final selectedExercises = <SelectedExercise>[];
      
      for (final exData in exercisesData) {
        final exerciseName = exData['exerciseName'] as String;
        
        // Trouver l'exercice correspondant
        final exercise = availableExercises.firstWhere(
          (ex) => ex.name.toLowerCase() == exerciseName.toLowerCase(),
          orElse: () => availableExercises.first, // Fallback
        );
        
        selectedExercises.add(
          SelectedExercise(
            exercise,
            sets: exData['sets'] as int,
            reps: exData['reps'] as int,
            weight: (exData['weight'] as num).toDouble(),
            rest: exData['rest'] as int,
            notes: exData['notes'] as String? ?? '',
          ),
        );
      }
      
      final program = WorkoutProgram(
        name: programName,
        duration: 0, // Sera calculé automatiquement
        exercises: selectedExercises,
      );
      
      // Calculer la durée basée sur les exercices
      final calculatedDuration = program.calculateDuration();
      
      return program.copyWith(duration: calculatedDuration);
    } catch (e) {
      // Si le parsing échoue, utiliser le fallback
      throw Exception('Erreur de parsing: $e');
    }
  }

  /// Génère un programme de secours si l'IA ne fonctionne pas
  WorkoutProgram _generateFallbackProgram({
    required String goal,
    required String level,
    required int daysPerWeek,
    required List<Exercise> availableExercises,
    required List<String> targetMuscles,
  }) {
    print('🎯 Génération du programme fallback...');
    
    if (availableExercises.isEmpty) {
      throw Exception('Aucun exercice disponible pour créer un programme');
    }
    
    // Déterminer les paramètres selon le niveau
    final (sets, reps, rest) = switch (level) {
      'debutant' => (3, 12, 90),
      'intermediaire' => (3, 10, 60),
      'avance' => (4, 8, 45),
      _ => (3, 10, 60),
    };
    
    print('📊 Paramètres: $sets séries x $reps reps, $rest sec repos');
    
    // Filtrer par muscles ciblés si spécifié
    List<Exercise> filteredByMuscle = availableExercises;
    if (targetMuscles.isNotEmpty && !targetMuscles.contains('fullbody')) {
      filteredByMuscle = availableExercises.where((ex) {
        final muscle = ex.muscleGroup.toLowerCase();
        return targetMuscles.any((target) => muscle.contains(target.toLowerCase()) || 
                                              target.toLowerCase().contains(muscle));
      }).toList();
      
      if (filteredByMuscle.isEmpty) {
        print('⚠️ Aucun exercice pour les muscles ciblés, utilisation de tous');
        filteredByMuscle = availableExercises;
      } else {
        print('✅ ${filteredByMuscle.length} exercices pour muscles ciblés');
      }
    }
    
    // Sélectionner des exercices variés
    final selectedExercises = <SelectedExercise>[];
    final muscleGroups = <String>{};
    final maxExercises = daysPerWeek * 4; // 4 exercices par jour
    
    // Prendre les premiers exercices de chaque groupe musculaire
    for (final exercise in filteredByMuscle) {
      if (selectedExercises.length >= maxExercises) break;
      
      // Essayer d'avoir une variété de groupes musculaires
      if (!muscleGroups.contains(exercise.muscleGroup) || 
          muscleGroups.length >= 6) {
        muscleGroups.add(exercise.muscleGroup);
        
        selectedExercises.add(
          SelectedExercise(
            exercise,
            sets: sets,
            reps: reps,
            weight: 0,
            rest: rest,
            notes: 'Programme généré automatiquement - Ajustez selon votre niveau',
          ),
        );
      }
    }
    
    // Si on n'a pas assez d'exercices, ajouter des exercices supplémentaires
    if (selectedExercises.length < 3) {
      print('⚠️ Pas assez d\'exercices variés, ajout d\'exercices supplémentaires');
      for (final exercise in filteredByMuscle) {
        if (selectedExercises.length >= maxExercises) break;
        
        // Vérifier si l'exercice n'est pas déjà dans la liste
        if (!selectedExercises.any((se) => se.exercise.id == exercise.id)) {
          selectedExercises.add(
            SelectedExercise(
              exercise,
              sets: sets,
              reps: reps,
              weight: 0,
              rest: rest,
              notes: 'Programme généré automatiquement - Ajustez selon votre niveau',
            ),
          );
        }
      }
    }
    
    final programName = switch (goal) {
      'perte_poids' => 'Programme Perte de Poids IA',
      'prise_masse' => 'Programme Prise de Masse IA',
      'maintien' => 'Programme Maintien IA',
      'seche' => 'Programme Sèche IA',
      _ => 'Programme Personnalisé IA',
    };
    
    print('✅ Programme créé: $programName avec ${selectedExercises.length} exercices');
    
    final program = WorkoutProgram(
      name: programName,
      duration: 0,
      exercises: selectedExercises,
    );
    
    // Calculer la durée basée sur les exercices
    final calculatedDuration = program.calculateDuration();
    print('⏱️ Durée estimée: ${calculatedDuration.toStringAsFixed(0)} minutes');
    
    return program.copyWith(duration: calculatedDuration);
  }

  String _translateGoal(String goal) {
    return switch (goal) {
      'perte_poids' => 'Perte de poids',
      'prise_masse' => 'Prise de masse musculaire',
      'maintien' => 'Maintien/Tonification',
      'seche' => 'Sèche',
      _ => goal,
    };
  }

  String _translateLevel(String level) {
    return switch (level) {
      'debutant' => 'Débutant',
      'intermediaire' => 'Intermédiaire',
      'avance' => 'Avancé',
      _ => level,
    };
  }
}
