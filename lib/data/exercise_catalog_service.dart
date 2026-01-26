import 'dart:convert';
import 'dart:io';

import '../models.dart';

class ExerciseCatalogService {
  static const String _baseUrl = 'https://wger.de/api/v2';

  /// Récupère de "vrais" exercices depuis l'API wger (publique).
  ///
  /// Remarque: si la structure JSON change (ou si l’API est bloquée), on retombe sur fallbackExercises().
  Future<List<Exercise>> fetchExercises({int limit = 100, int language = 2}) async {
    final client = HttpClient();
    try {
      // Endpoint "exerciseinfo" souvent utilisé côté wger pour avoir des infos enrichies (images incluses).
      final uri = Uri.parse('$_baseUrl/exerciseinfo/?limit=$limit&language=$language');

      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}');
      }

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body);

      if (json is! Map<String, dynamic>) {
        throw const FormatException('Unexpected JSON root');
      }

      final resultsAny = json['results'];
      if (resultsAny is! List) {
        throw const FormatException('Missing results[]');
      }

      final exercises = <Exercise>[];

      for (final item in resultsAny) {
        if (item is! Map) continue;

        final id = (item['id'] ?? '').toString();
        final name = (item['name'] ?? item['name_original'] ?? 'Exercice').toString();

        // Images: on essaie de récupérer la première URL disponible
        String imageUrl = '';
        final imagesAny = item['images'];
        if (imagesAny is List && imagesAny.isNotEmpty) {
          final first = imagesAny.first;
          if (first is Map) {
            imageUrl = (first['image'] ?? first['url'] ?? '').toString();
          }
        }

        // Catégorie (on l’utilise comme "muscleGroup" pour rester compatible avec ton modèle actuel)
        String muscleGroup = '';
        final categoryAny = item['category'];
        if (categoryAny is Map) {
          muscleGroup = (categoryAny['name'] ?? '').toString();
        }

        // Equipment: premier item de la liste si dispo
        String equipment = '';
        final equipmentAny = item['equipment'];
        if (equipmentAny is List && equipmentAny.isNotEmpty) {
          final first = equipmentAny.first;
          if (first is Map) {
            equipment = (first['name'] ?? '').toString();
          } else {
            equipment = first.toString();
          }
        }

        if (id.isEmpty || name.trim().isEmpty) continue;

        exercises.add(
          Exercise(
            id: id,
            name: name,
            image: imageUrl, // URL d'image
            muscleGroup: muscleGroup,
            equipment: equipment,
            isFavorite: false,
          ),
        );
      }

      if (exercises.isEmpty) {
        throw const FormatException('Empty catalog');
      }

      return exercises;
    } finally {
      client.close(force: true);
    }
  }

  /// Fallback local (si offline / API KO) : vrais exercices + images (URLs).
  static List<Exercise> fallbackExercises() {
    // Tu peux remplacer ces URLs par tes assets plus tard.
    return [
      Exercise(
        id: 'fallback_squat',
        name: 'Back Squat',
        image: 'https://source.unsplash.com/featured/?barbell,squat',
        muscleGroup: 'Jambes',
        equipment: 'Barre',
      ),
      Exercise(
        id: 'fallback_bench',
        name: 'Bench Press',
        image: 'https://source.unsplash.com/featured/?benchpress,gym',
        muscleGroup: 'Pecs',
        equipment: 'Barre',
      ),
      Exercise(
        id: 'fallback_deadlift',
        name: 'Deadlift',
        image: 'https://source.unsplash.com/featured/?deadlift,barbell',
        muscleGroup: 'Dos',
        equipment: 'Barre',
      ),
      Exercise(
        id: 'fallback_pullup',
        name: 'Pull-Up',
        image: 'https://source.unsplash.com/featured/?pullup,calisthenics',
        muscleGroup: 'Dos',
        equipment: 'Libre',
      ),
      Exercise(
        id: 'fallback_dips',
        name: 'Dips',
        image: 'https://source.unsplash.com/featured/?dips,calisthenics',
        muscleGroup: 'Pecs',
        equipment: 'Libre',
      ),
      Exercise(
        id: 'fallback_legpress',
        name: 'Leg Press',
        image: 'https://source.unsplash.com/featured/?legpress,machine',
        muscleGroup: 'Jambes',
        equipment: 'Machine',
      ),
      Exercise(
        id: 'fallback_latpulldown',
        name: 'Lat Pulldown',
        image: 'https://source.unsplash.com/featured/?latpulldown,cable',
        muscleGroup: 'Dos',
        equipment: 'Machine',
      ),
      Exercise(
        id: 'fallback_shoulderpress',
        name: 'Shoulder Press',
        image: 'https://source.unsplash.com/featured/?shoulderpress,dumbbell',
        muscleGroup: 'Épaules',
        equipment: 'Libre',
      ),
      Exercise(
        id: 'fallback_bicepscurl',
        name: 'Biceps Curl',
        image: 'https://source.unsplash.com/featured/?biceps,curl,dumbbell',
        muscleGroup: 'Bras',
        equipment: 'Libre',
      ),
      Exercise(
        id: 'fallback_tricepspushdown',
        name: 'Triceps Pushdown',
        image: 'https://source.unsplash.com/featured/?triceps,cable',
        muscleGroup: 'Bras',
        equipment: 'Machine',
      ),
    ];
  }
}
