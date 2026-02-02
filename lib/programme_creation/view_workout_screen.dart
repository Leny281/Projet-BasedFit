import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'models.dart';
import '../data/workout_repository.dart';
import 'create_workout_screen.dart';

/// Écran de visualisation d'un programme (lecture seule)
/// Affiche les exercices avec leurs images, sets, reps, etc.
class ViewWorkoutScreen extends StatefulWidget {
  final int programId;

  const ViewWorkoutScreen({
    super.key,
    required this.programId,
  });

  @override
  State<ViewWorkoutScreen> createState() => _ViewWorkoutScreenState();
}

class _ViewWorkoutScreenState extends State<ViewWorkoutScreen> {
  final WorkoutRepository _repo = WorkoutRepository();

  WorkoutProgram? _program;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProgram();
  }

  Future<void> _loadProgram() async {
    try {
      final program = await _repo.getProgram(widget.programId);
      if (!mounted) return;

      if (program == null) {
        setState(() {
          _loading = false;
          _error = 'Programme introuvable';
        });
        return;
      }

      setState(() {
        _program = program;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Erreur: $e';
      });
    }
  }

  Future<void> _openEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateWorkoutScreen(programId: widget.programId),
      ),
    );

    // Recharger si modifié
    if (result != null) {
      setState(() => _loading = true);
      _loadProgram();
    }
  }

  Future<void> _deleteProgram() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le programme'),
        content: Text('Voulez-vous vraiment supprimer "${_program?.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repo.deleteProgram(widget.programId);
      if (!mounted) return;
      Navigator.pop(context, true); // Retourner avec indication de suppression
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chargement...'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _program == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Erreur'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(_error ?? 'Programme introuvable'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    final program = _program!;

    return Scaffold(
      appBar: AppBar(
        title: Text(program.name),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier',
            onPressed: _openEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Supprimer',
            onPressed: _deleteProgram,
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête du programme
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  program.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.fitness_center,
                      label: '${program.exercises.length} exercices',
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: Icons.timer,
                      label: '${program.duration.toStringAsFixed(0)} min',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Liste des exercices
          Expanded(
            child: program.exercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun exercice',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _openEdit,
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter des exercices'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: program.exercises.length,
                    itemBuilder: (context, index) {
                      final se = program.exercises[index];
                      return _ExerciseCard(
                        selectedExercise: se,
                        index: index + 1,
                      );
                    },
                  ),
          ),

          // Bouton démarrer la séance
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implémenter le mode séance active
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mode séance bientôt disponible !'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow, size: 28),
                  label: const Text(
                    'Démarrer la séance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip d'information (exercices, durée)
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Carte d'exercice avec image et détails
class _ExerciseCard extends StatelessWidget {
  final SelectedExercise selectedExercise;
  final int index;

  const _ExerciseCard({
    required this.selectedExercise,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final exercise = selectedExercise.exercise;
    final hasImage = exercise.image.startsWith('http');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image de l'exercice
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: hasImage
                ? CachedNetworkImage(
                    imageUrl: exercise.image,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fitness_center,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            exercise.muscleGroup,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fitness_center,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          exercise.muscleGroup,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
          ),

          // Détails de l'exercice
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Numéro et nom
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        exercise.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Muscle et équipement
                Row(
                  children: [
                    if (exercise.muscleGroup.isNotEmpty) ...[
                      Icon(Icons.accessibility_new,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        exercise.muscleGroup,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                    if (exercise.muscleGroup.isNotEmpty &&
                        exercise.equipment.isNotEmpty)
                      const SizedBox(width: 16),
                    if (exercise.equipment.isNotEmpty) ...[
                      Icon(Icons.fitness_center,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        exercise.equipment,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // Paramètres (sets, reps, poids, repos)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ParamColumn(
                        label: 'Séries',
                        value: '${selectedExercise.sets}',
                        icon: Icons.repeat,
                      ),
                      _ParamColumn(
                        label: 'Reps',
                        value: '${selectedExercise.reps}',
                        icon: Icons.format_list_numbered,
                      ),
                      _ParamColumn(
                        label: 'Poids',
                        value: '${selectedExercise.weight.toStringAsFixed(1)} kg',
                        icon: Icons.monitor_weight,
                      ),
                      _ParamColumn(
                        label: 'Repos',
                        value: '${selectedExercise.rest}s',
                        icon: Icons.timer,
                      ),
                    ],
                  ),
                ),

                // Notes si présentes
                if (selectedExercise.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes, size: 18, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedExercise.notes,
                            style: TextStyle(color: Colors.amber[900]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Colonne de paramètre (séries, reps, etc.)
class _ParamColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ParamColumn({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}