import 'dart:convert';
import 'dart:io';

import '../programme_creation/models.dart';

class ExerciseCatalogService {
  // free-exercise-db hébergé sur GitHub (800+ exercices avec images garanties)
  static const String _baseUrl =
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json';

  // Base URL pour les images
  static const String _imageBaseUrl =
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises';

  /// Récupère les exercices depuis free-exercise-db (GitHub).
  /// Tous les exercices ont des images garanties.
  Future<List<Exercise>> fetchExercises({int limit = 120}) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(_baseUrl);

      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}');
      }

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body);

      if (json is! List) {
        throw const FormatException('Expected JSON array');
      }

      final exercises = <Exercise>[];

      for (final item in json) {
        if (item is! Map) continue;

        final id = (item['id'] ?? '').toString();
        final name = (item['name'] ?? 'Exercice').toString();

        // Images: construire l'URL complète
        String imageUrl = '';
        final imagesAny = item['images'];
        if (imagesAny is List && imagesAny.isNotEmpty) {
          // Format: "Exercise_Name/0.jpg" -> URL complète
          final imagePath = imagesAny.first.toString();
          imageUrl = '$_imageBaseUrl/$imagePath';
        }

        // Muscles primaires (on prend le premier comme groupe musculaire principal)
        String muscleGroup = '';
        final primaryMuscles = item['primaryMuscles'];
        if (primaryMuscles is List && primaryMuscles.isNotEmpty) {
          muscleGroup = _translateMuscle(primaryMuscles.first.toString());
        }

        // Équipement
        String equipment = '';
        final equipmentAny = item['equipment'];
        if (equipmentAny != null && equipmentAny.toString().isNotEmpty) {
          equipment = _translateEquipment(equipmentAny.toString());
        }

        // Niveau de difficulté (optionnel, pour enrichir plus tard)
        final level = (item['level'] ?? '').toString();

        // Catégorie (strength, cardio, etc.)
        final category = (item['category'] ?? '').toString();

        if (id.isEmpty || name.trim().isEmpty) continue;

        exercises.add(
          Exercise(
            id: id,
            name: name,
            image: imageUrl,
            muscleGroup: muscleGroup,
            equipment: equipment,
            isFavorite: false,
          ),
        );

        // Limiter le nombre d'exercices
        if (exercises.length >= limit) break;
      }

      if (exercises.isEmpty) {
        throw const FormatException('Empty catalog');
      }

      return exercises;
    } finally {
      client.close(force: true);
    }
  }

  /// Traduit les noms de muscles en français
  static String _translateMuscle(String muscle) {
    const translations = {
      'abdominals': 'Abdominaux',
      'abductors': 'Abducteurs',
      'adductors': 'Adducteurs',
      'biceps': 'Biceps',
      'calves': 'Mollets',
      'chest': 'Pectoraux',
      'forearms': 'Avant-bras',
      'glutes': 'Fessiers',
      'hamstrings': 'Ischio-jambiers',
      'lats': 'Dorsaux',
      'lower back': 'Bas du dos',
      'middle back': 'Milieu du dos',
      'neck': 'Cou',
      'quadriceps': 'Quadriceps',
      'shoulders': 'Épaules',
      'traps': 'Trapèzes',
      'triceps': 'Triceps',
    };
    return translations[muscle.toLowerCase()] ?? muscle;
  }

  /// Traduit les noms d'équipement en français
  static String _translateEquipment(String equipment) {
    const translations = {
      'barbell': 'Barre',
      'dumbbell': 'Haltères',
      'cable': 'Câble',
      'machine': 'Machine',
      'body only': 'Poids du corps',
      'kettlebells': 'Kettlebell',
      'bands': 'Élastiques',
      'medicine ball': 'Medecine ball',
      'exercise ball': 'Swiss ball',
      'foam roll': 'Rouleau mousse',
      'e-z curl bar': 'Barre EZ',
      'other': 'Autre',
      'none': 'Aucun',
    };
    return translations[equipment.toLowerCase()] ?? equipment;
  }

  /// Fallback local si l'API GitHub est indisponible
  /// Ces exercices ont des images provenant du même repo
  static List<Exercise> fallbackExercises() {
    return [
      Exercise(
        id: '3_4_Sit-Up',
        name: '3/4 Sit-Up',
        image: '$_imageBaseUrl/3_4_Sit-Up/0.jpg',
        muscleGroup: 'Abdominaux',
        equipment: 'Poids du corps',
      ),
      Exercise(
        id: 'Ab_Crunch_Machine',
        name: 'Ab Crunch Machine',
        image: '$_imageBaseUrl/Ab_Crunch_Machine/0.jpg',
        muscleGroup: 'Abdominaux',
        equipment: 'Machine',
      ),
      Exercise(
        id: 'Ab_Roller',
        name: 'Ab Roller',
        image: '$_imageBaseUrl/Ab_Roller/0.jpg',
        muscleGroup: 'Abdominaux',
        equipment: 'Autre',
      ),
      Exercise(
        id: 'Barbell_Bench_Press_-_Medium_Grip',
        name: 'Barbell Bench Press - Medium Grip',
        image: '$_imageBaseUrl/Barbell_Bench_Press_-_Medium_Grip/0.jpg',
        muscleGroup: 'Pectoraux',
        equipment: 'Barre',
      ),
      Exercise(
        id: 'Barbell_Curl',
        name: 'Barbell Curl',
        image: '$_imageBaseUrl/Barbell_Curl/0.jpg',
        muscleGroup: 'Biceps',
        equipment: 'Barre',
      ),
      Exercise(
        id: 'Barbell_Deadlift',
        name: 'Barbell Deadlift',
        image: '$_imageBaseUrl/Barbell_Deadlift/0.jpg',
        muscleGroup: 'Bas du dos',
        equipment: 'Barre',
      ),
      Exercise(
        id: 'Barbell_Full_Squat',
        name: 'Barbell Full Squat',
        image: '$_imageBaseUrl/Barbell_Full_Squat/0.jpg',
        muscleGroup: 'Quadriceps',
        equipment: 'Barre',
      ),
      Exercise(
        id: 'Barbell_Incline_Bench_Press_-_Medium_Grip',
        name: 'Barbell Incline Bench Press',
        image: '$_imageBaseUrl/Barbell_Incline_Bench_Press_-_Medium_Grip/0.jpg',
        muscleGroup: 'Pectoraux',
        equipment: 'Barre',
      ),
      Exercise(
        id: 'Barbell_Shoulder_Press',
        name: 'Barbell Shoulder Press',
        image: '$_imageBaseUrl/Barbell_Shoulder_Press/0.jpg',
        muscleGroup: 'Épaules',
        equipment: 'Barre',
      ),
      Exercise(
        id: 'Bent_Over_Barbell_Row',
        name: 'Bent Over Barbell Row',
        image: '$_imageBaseUrl/Bent_Over_Barbell_Row/0.jpg',
        muscleGroup: 'Milieu du dos',
        equipment: 'Barre',
      ),
      Exercise(
        id: 'Cable_Crossover',
        name: 'Cable Crossover',
        image: '$_imageBaseUrl/Cable_Crossover/0.jpg',
        muscleGroup: 'Pectoraux',
        equipment: 'Câble',
      ),
      Exercise(
        id: 'Chin-Up',
        name: 'Chin-Up',
        image: '$_imageBaseUrl/Chin-Up/0.jpg',
        muscleGroup: 'Dorsaux',
        equipment: 'Poids du corps',
      ),
      Exercise(
        id: 'Close-Grip_Barbell_Bench_Press',
        name: 'Close-Grip Barbell Bench Press',
        image: '$_imageBaseUrl/Close-Grip_Barbell_Bench_Press/0.jpg',
        muscleGroup: 'Triceps',
        equipment: 'Barre',
      ),
      Exercise(
        id: 'Dips_-_Triceps_Version',
        name: 'Dips - Triceps',
        image: '$_imageBaseUrl/Dips_-_Triceps_Version/0.jpg',
        muscleGroup: 'Triceps',
        equipment: 'Poids du corps',
      ),
      Exercise(
        id: 'Dumbbell_Bicep_Curl',
        name: 'Dumbbell Bicep Curl',
        image: '$_imageBaseUrl/Dumbbell_Bicep_Curl/0.jpg',
        muscleGroup: 'Biceps',
        equipment: 'Haltères',
      ),
      Exercise(
        id: 'Dumbbell_Flyes',
        name: 'Dumbbell Flyes',
        image: '$_imageBaseUrl/Dumbbell_Flyes/0.jpg',
        muscleGroup: 'Pectoraux',
        equipment: 'Haltères',
      ),
      Exercise(
        id: 'Dumbbell_Lunges',
        name: 'Dumbbell Lunges',
        image: '$_imageBaseUrl/Dumbbell_Lunges/0.jpg',
        muscleGroup: 'Quadriceps',
        equipment: 'Haltères',
      ),
      Exercise(
        id: 'Dumbbell_Shoulder_Press',
        name: 'Dumbbell Shoulder Press',
        image: '$_imageBaseUrl/Dumbbell_Shoulder_Press/0.jpg',
        muscleGroup: 'Épaules',
        equipment: 'Haltères',
      ),
      Exercise(
        id: 'Hammer_Curls',
        name: 'Hammer Curls',
        image: '$_imageBaseUrl/Hammer_Curls/0.jpg',
        muscleGroup: 'Biceps',
        equipment: 'Haltères',
      ),
      Exercise(
        id: 'Lat_Pulldown',
        name: 'Lat Pulldown',
        image: '$_imageBaseUrl/Wide-Grip_Lat_Pulldown/0.jpg',
        muscleGroup: 'Dorsaux',
        equipment: 'Câble',
      ),
      Exercise(
        id: 'Leg_Extensions',
        name: 'Leg Extensions',
        image: '$_imageBaseUrl/Leg_Extensions/0.jpg',
        muscleGroup: 'Quadriceps',
        equipment: 'Machine',
      ),
      Exercise(
        id: 'Leg_Press',
        name: 'Leg Press',
        image: '$_imageBaseUrl/Leg_Press/0.jpg',
        muscleGroup: 'Quadriceps',
        equipment: 'Machine',
      ),
      Exercise(
        id: 'Lying_Leg_Curls',
        name: 'Lying Leg Curls',
        image: '$_imageBaseUrl/Lying_Leg_Curls/0.jpg',
        muscleGroup: 'Ischio-jambiers',
        equipment: 'Machine',
      ),
      Exercise(
        id: 'Plank',
        name: 'Plank',
        image: '$_imageBaseUrl/Plank/0.jpg',
        muscleGroup: 'Abdominaux',
        equipment: 'Poids du corps',
      ),
      Exercise(
        id: 'Pull-ups',
        name: 'Pull-ups',
        image: '$_imageBaseUrl/Pullups/0.jpg',
        muscleGroup: 'Dorsaux',
        equipment: 'Poids du corps',
      ),
      Exercise(
        id: 'Pushups',
        name: 'Pushups',
        image: '$_imageBaseUrl/Pushups/0.jpg',
        muscleGroup: 'Pectoraux',
        equipment: 'Poids du corps',
      ),
      Exercise(
        id: 'Romanian_Deadlift',
        name: 'Romanian Deadlift',
        image: '$_imageBaseUrl/Romanian_Deadlift_With_Dumbbells/0.jpg',
        muscleGroup: 'Ischio-jambiers',
        equipment: 'Barre',
      ),
      Exercise(
        id: 'Seated_Cable_Rows',
        name: 'Seated Cable Rows',
        image: '$_imageBaseUrl/Seated_Cable_Rows/0.jpg',
        muscleGroup: 'Milieu du dos',
        equipment: 'Câble',
      ),
      Exercise(
        id: 'Side_Lateral_Raise',
        name: 'Side Lateral Raise',
        image: '$_imageBaseUrl/Side_Lateral_Raise/0.jpg',
        muscleGroup: 'Épaules',
        equipment: 'Haltères',
      ),
      Exercise(
        id: 'Standing_Calf_Raises',
        name: 'Standing Calf Raises',
        image: '$_imageBaseUrl/Standing_Calf_Raises/0.jpg',
        muscleGroup: 'Mollets',
        equipment: 'Machine',
      ),
      Exercise(
        id: 'Tricep_Dumbbell_Kickback',
        name: 'Tricep Dumbbell Kickback',
        image: '$_imageBaseUrl/Tricep_Dumbbell_Kickback/0.jpg',
        muscleGroup: 'Triceps',
        equipment: 'Haltères',
      ),
      Exercise(
        id: 'Triceps_Pushdown',
        name: 'Triceps Pushdown',
        image: '$_imageBaseUrl/Triceps_Pushdown/0.jpg',
        muscleGroup: 'Triceps',
        equipment: 'Câble',
      ),
    ];
  }
}