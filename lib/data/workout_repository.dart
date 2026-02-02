
import 'workout_database.dart';
import '../programme_creation/models.dart'; // mets ici tes classes Exercise, SelectedExercise, WorkoutProgram

class WorkoutRepository {
  final WorkoutDatabase _dbProvider = WorkoutDatabase.instance;

  Future<int> saveProgram(WorkoutProgram program) async {
    final db = await _dbProvider.database;

    // 1) Insérer ou mettre à jour le programme
    int programId;
    if (program.id == null) {
      programId = await db.insert(
        'programs',
        {
          'name': program.name,
          'duration': program.duration,
        },
      );
    } else {
      programId = program.id!;
      await db.update(
        'programs',
        {
          'name': program.name,
          'duration': program.duration,
        },
        where: 'id = ?',
        whereArgs: [programId],
      );
      // On supprime les anciens exercices pour les réinsérer proprement
      await db.delete(
        'program_exercises',
        where: 'program_id = ?',
        whereArgs: [programId],
      );
    }

    // 2) Insérer les exercices du programme
    for (final se in program.exercises) {
      await db.insert('program_exercises', {
        'program_id': programId,
        'exercise_id': se.exercise.id,
        'name': se.exercise.name,
        'image': se.exercise.image,
        'muscle_group': se.exercise.muscleGroup,
        'equipment': se.exercise.equipment,
        'is_favorite': se.exercise.isFavorite ? 1 : 0,
        'sets': se.sets,
        'reps': se.reps,
        'weight': se.weight,
        'rest': se.rest,
        'notes': se.notes,
      });
    }

    return programId;
  }

  Future<List<WorkoutProgram>> getAllPrograms() async {
    final db = await _dbProvider.database;

    final programsRows = await db.query('programs', orderBy: 'id DESC');

    final List<WorkoutProgram> result = [];
    for (final p in programsRows) {
      final programId = p['id'] as int;

      final exRows = await db.query(
        'program_exercises',
        where: 'program_id = ?',
        whereArgs: [programId],
      );

      final List<SelectedExercise> selectedExercises = exRows.map((row) {
        final exercise = Exercise(
          id: row['exercise_id'] as String,
          name: row['name'] as String,
          image: (row['image'] as String?) ?? '🏋️',
          muscleGroup: (row['muscle_group'] as String?) ?? '',
          equipment: (row['equipment'] as String?) ?? '',
          isFavorite: (row['is_favorite'] as int) == 1,
        );
        return SelectedExercise(
          exercise,
          sets: row['sets'] as int,
          reps: row['reps'] as int,
          weight: (row['weight'] as num).toDouble(),
          rest: row['rest'] as int,
          notes: (row['notes'] as String?) ?? '',
        );
      }).toList();

      result.add(
        WorkoutProgram(
          id: programId,
          name: p['name'] as String,
          duration: (p['duration'] as num).toDouble(),
          exercises: selectedExercises,
        ),
      );
    }

    return result;
  }

  Future<WorkoutProgram?> getProgram(int id) async {
    final db = await _dbProvider.database;

    final progrRows = await db.query(
      'programs',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (progrRows.isEmpty) return null;
    final p = progrRows.first;

    final exRows = await db.query(
      'program_exercises',
      where: 'program_id = ?',
      whereArgs: [id],
    );

    final List<SelectedExercise> selectedExercises = exRows.map((row) {
      final exercise = Exercise(
        id: row['exercise_id'] as String,
        name: row['name'] as String,
        image: (row['image'] as String?) ?? '🏋️',
        muscleGroup: (row['muscle_group'] as String?) ?? '',
        equipment: (row['equipment'] as String?) ?? '',
        isFavorite: (row['is_favorite'] as int) == 1,
      );
      return SelectedExercise(
        exercise,
        sets: row['sets'] as int,
        reps: row['reps'] as int,
        weight: (row['weight'] as num).toDouble(),
        rest: row['rest'] as int,
        notes: (row['notes'] as String?) ?? '',
      );
    }).toList();

    return WorkoutProgram(
      id: p['id'] as int,
      name: p['name'] as String,
      duration: (p['duration'] as num).toDouble(),
      exercises: selectedExercises,
    );
  }

  Future<void> deleteProgram(int id) async {
    final db = await _dbProvider.database;
    await db.delete(
      'programs',
      where: 'id = ?',
      whereArgs: [id],
    );
    // Les exercises liés sont supprimés via ON DELETE CASCADE
  }
}
