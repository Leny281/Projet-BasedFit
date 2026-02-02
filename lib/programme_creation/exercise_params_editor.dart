import 'package:flutter/material.dart';
import 'models.dart';

/// Widget pour éditer les paramètres d'un exercice sélectionné
/// (séries, répétitions, poids, repos, notes)
class ExerciseParamsEditor extends StatefulWidget {
  final SelectedExercise selectedExercise;
  final ValueChanged<SelectedExercise> onChanged;
  final VoidCallback onDelete;
  final int index;

  const ExerciseParamsEditor({
    super.key,
    required this.selectedExercise,
    required this.onChanged,
    required this.onDelete,
    required this.index,
  });

  @override
  State<ExerciseParamsEditor> createState() => _ExerciseParamsEditorState();
}

class _ExerciseParamsEditorState extends State<ExerciseParamsEditor> {
  late TextEditingController _notesController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.selectedExercise.notes);
  }

  @override
  void didUpdateWidget(ExerciseParamsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedExercise.notes != widget.selectedExercise.notes) {
      _notesController.text = widget.selectedExercise.notes;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _updateSets(int delta) {
    final newValue = (widget.selectedExercise.sets + delta).clamp(1, 20);
    if (newValue != widget.selectedExercise.sets) {
      widget.onChanged(widget.selectedExercise.copyWith(sets: newValue));
    }
  }

  void _updateReps(int delta) {
    final newValue = (widget.selectedExercise.reps + delta).clamp(1, 100);
    if (newValue != widget.selectedExercise.reps) {
      widget.onChanged(widget.selectedExercise.copyWith(reps: newValue));
    }
  }

  void _updateWeight(double delta) {
    final newValue = (widget.selectedExercise.weight + delta).clamp(0.0, 500.0);
    if (newValue != widget.selectedExercise.weight) {
      widget.onChanged(widget.selectedExercise.copyWith(weight: newValue));
    }
  }

  void _updateRest(int delta) {
    final newValue = (widget.selectedExercise.rest + delta).clamp(0, 600);
    if (newValue != widget.selectedExercise.rest) {
      widget.onChanged(widget.selectedExercise.copyWith(rest: newValue));
    }
  }

  void _updateNotes(String notes) {
    widget.onChanged(widget.selectedExercise.copyWith(notes: notes));
  }

  void _showDetailedEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DetailedEditorSheet(
        selectedExercise: widget.selectedExercise,
        onChanged: widget.onChanged,
        notesController: _notesController,
        onNotesChanged: _updateNotes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.selectedExercise.exercise;
    final se = widget.selectedExercise;
    final hasImage = exercise.image.startsWith('http');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // En-tête avec image et nom
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Numéro d'ordre
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Image miniature
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: hasImage
                        ? Image.network(
                            exercise.image,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _PlaceholderImage(),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return _PlaceholderImage(loading: true);
                            },
                          )
                        : _PlaceholderImage(),
                  ),
                  const SizedBox(width: 12),

                  // Nom et infos rapides
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${se.sets} séries × ${se.reps} reps • ${se.weight > 0 ? "${se.weight.toStringAsFixed(1)} kg" : "Poids du corps"}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Boutons d'action
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: _showDetailedEditor,
                    tooltip: 'Modifier les détails',
                    color: Theme.of(context).primaryColor,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: widget.onDelete,
                    tooltip: 'Supprimer',
                    color: Colors.red[400],
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),

          // Paramètres rapides (visible quand expanded)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _QuickParamsEditor(
              sets: se.sets,
              reps: se.reps,
              weight: se.weight,
              rest: se.rest,
              onSetsChanged: _updateSets,
              onRepsChanged: _updateReps,
              onWeightChanged: _updateWeight,
              onRestChanged: _updateRest,
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),

          // Indicateur de notes
          if (se.notes.isNotEmpty && !_isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.notes, size: 16, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      se.notes,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[900],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Image placeholder quand pas d'image disponible
class _PlaceholderImage extends StatelessWidget {
  final bool loading;

  const _PlaceholderImage({this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.fitness_center, color: Colors.grey[400], size: 24),
      ),
    );
  }
}

/// Éditeur rapide des paramètres (inline)
class _QuickParamsEditor extends StatelessWidget {
  final int sets;
  final int reps;
  final double weight;
  final int rest;
  final ValueChanged<int> onSetsChanged;
  final ValueChanged<int> onRepsChanged;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRestChanged;

  const _QuickParamsEditor({
    required this.sets,
    required this.reps,
    required this.weight,
    required this.rest,
    required this.onSetsChanged,
    required this.onRepsChanged,
    required this.onWeightChanged,
    required this.onRestChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          const Divider(),
          Row(
            children: [
              Expanded(
                child: _ParamControl(
                  label: 'Séries',
                  value: '$sets',
                  icon: Icons.repeat,
                  onDecrement: () => onSetsChanged(-1),
                  onIncrement: () => onSetsChanged(1),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ParamControl(
                  label: 'Reps',
                  value: '$reps',
                  icon: Icons.format_list_numbered,
                  onDecrement: () => onRepsChanged(-1),
                  onIncrement: () => onRepsChanged(1),
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ParamControl(
                  label: 'Poids (kg)',
                  value: weight.toStringAsFixed(1),
                  icon: Icons.monitor_weight,
                  onDecrement: () => onWeightChanged(-2.5),
                  onIncrement: () => onWeightChanged(2.5),
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ParamControl(
                  label: 'Repos (s)',
                  value: '$rest',
                  icon: Icons.timer,
                  onDecrement: () => onRestChanged(-15),
                  onIncrement: () => onRestChanged(15),
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Contrôle individuel d'un paramètre avec +/-
class _ParamControl extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final Color color;

  const _ParamControl({
    required this.label,
    required this.value,
    required this.icon,
    required this.onDecrement,
    required this.onIncrement,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              _MiniButton(
                icon: Icons.add,
                onPressed: onIncrement,
                color: color,
              ),
              const SizedBox(height: 2),
              _MiniButton(
                icon: Icons.remove,
                onPressed: onDecrement,
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Petit bouton +/-
class _MiniButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _MiniButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

/// Bottom sheet pour édition détaillée
class _DetailedEditorSheet extends StatefulWidget {
  final SelectedExercise selectedExercise;
  final ValueChanged<SelectedExercise> onChanged;
  final TextEditingController notesController;
  final ValueChanged<String> onNotesChanged;

  const _DetailedEditorSheet({
    required this.selectedExercise,
    required this.onChanged,
    required this.notesController,
    required this.onNotesChanged,
  });

  @override
  State<_DetailedEditorSheet> createState() => _DetailedEditorSheetState();
}

class _DetailedEditorSheetState extends State<_DetailedEditorSheet> {
  late int _sets;
  late int _reps;
  late double _weight;
  late int _rest;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _sets = widget.selectedExercise.sets;
    _reps = widget.selectedExercise.reps;
    _weight = widget.selectedExercise.weight;
    _rest = widget.selectedExercise.rest;
    _notesController = TextEditingController(text: widget.selectedExercise.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    widget.onChanged(widget.selectedExercise.copyWith(
      sets: _sets,
      reps: _reps,
      weight: _weight,
      rest: _rest,
      notes: _notesController.text,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.selectedExercise.exercise;
    final hasImage = exercise.image.startsWith('http');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Titre avec image
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: hasImage
                          ? Image.network(
                              exercise.image,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _LargePlaceholder(),
                            )
                          : _LargePlaceholder(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (exercise.muscleGroup.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.accessibility_new,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  exercise.muscleGroup,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          if (exercise.equipment.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.fitness_center,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  exercise.equipment,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Paramètres avec sliders
                const Text(
                  'Paramètres',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Séries
                _SliderParam(
                  label: 'Séries',
                  value: _sets.toDouble(),
                  min: 1,
                  max: 20,
                  divisions: 19,
                  unit: '',
                  icon: Icons.repeat,
                  color: Colors.blue,
                  onChanged: (v) => setState(() => _sets = v.round()),
                ),

                // Répétitions
                _SliderParam(
                  label: 'Répétitions',
                  value: _reps.toDouble(),
                  min: 1,
                  max: 50,
                  divisions: 49,
                  unit: '',
                  icon: Icons.format_list_numbered,
                  color: Colors.green,
                  onChanged: (v) => setState(() => _reps = v.round()),
                ),

                // Poids
                _SliderParam(
                  label: 'Poids',
                  value: _weight,
                  min: 0,
                  max: 200,
                  divisions: 80,
                  unit: 'kg',
                  icon: Icons.monitor_weight,
                  color: Colors.orange,
                  onChanged: (v) => setState(() => _weight = (v * 2).round() / 2),
                  decimals: 1,
                ),

                // Repos
                _SliderParam(
                  label: 'Temps de repos',
                  value: _rest.toDouble(),
                  min: 0,
                  max: 300,
                  divisions: 20,
                  unit: 's',
                  icon: Icons.timer,
                  color: Colors.purple,
                  onChanged: (v) => setState(() => _rest = (v / 15).round() * 15),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Notes
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Ajouter des notes (technique, sensations, etc.)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.notes),
                  ),
                ),

                const SizedBox(height: 24),

                // Bouton sauvegarder
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text(
                      'Enregistrer',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Large placeholder pour le bottom sheet
class _LargePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.fitness_center, color: Colors.grey[400], size: 32),
    );
  }
}

/// Slider avec label et valeur
class _SliderParam extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String unit;
  final IconData icon;
  final Color color;
  final ValueChanged<double> onChanged;
  final int decimals;

  const _SliderParam({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.unit,
    required this.icon,
    required this.color,
    required this.onChanged,
    this.decimals = 0,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = decimals > 0
        ? value.toStringAsFixed(decimals)
        : value.round().toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$displayValue $unit'.trim(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.2),
              thumbColor: color,
              overlayColor: color.withOpacity(0.1),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}