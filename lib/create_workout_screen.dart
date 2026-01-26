import 'package:flutter/material.dart';

import 'models.dart';
import 'data/workout_repository.dart';
import 'data/workout_database.dart';

class CreateWorkoutScreen extends StatefulWidget {
  final WorkoutProgram? existingProgram;
  final int? programId;

  const CreateWorkoutScreen({
    super.key,
    this.existingProgram,
    this.programId,
  }) : assert(existingProgram == null || programId == null,
            'Pass either existingProgram OR programId, not both.');

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  final WorkoutRepository _repo = WorkoutRepository();

  final List<Exercise> _allExercises = List.generate(
    500,
    (i) => Exercise(
      id: i.toString(),
      name: 'Exercice ${i + 1}',
      image: '🏋️',
      muscleGroup: ['Jambes', 'Dos', 'Pecs'][i % 3],
      equipment: ['Barre', 'Machine', 'Libre'][i % 3],
      isFavorite: i % 10 == 0,
    ),
  );

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _programNameController = TextEditingController();

  List<Exercise> _filteredExercises = [];
  int _matchingExercisesCount = 0;

  List<SelectedExercise> _selectedExercises = [];

  String _muscleFilter = '';
  String _equipmentFilter = '';
  bool _favoritesOnly = false;

  bool _initialLoading = true;
  bool _saving = false;

  int _page = 0;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 0) IMPORTANT: force l'init DB (et donne une erreur claire si pas init côté desktop)
    try {
      await WorkoutDatabase.instance.database;
    } catch (e) {
      if (!mounted) return;
      setState(() => _initialLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur BDD: $e\n\n'
            'Si tu es sur Windows/Linux/Mac: initialise sqflite_common_ffi dans main.dart.',
          ),
          duration: const Duration(seconds: 8),
        ),
      );
      // On laisse quand même l’écran s’afficher (sans crash), mais la sauvegarde ne marchera pas.
      _applyFilters();
      return;
    }

    // 1) Pré-remplir si édition directe
    if (widget.existingProgram != null) {
      _programNameController.text = widget.existingProgram!.name;
      _selectedExercises = List.from(widget.existingProgram!.exercises);
      setState(() => _initialLoading = false);
      _applyFilters();
      return;
    }

    // 2) Charger depuis la DB si programId fourni
    if (widget.programId != null) {
      await _loadProgramFromDb(widget.programId!);
      return;
    }

    // 3) Nouveau programme
    setState(() => _initialLoading = false);
    _applyFilters();
  }

  Future<void> _loadProgramFromDb(int id) async {
    try {
      final program = await _repo.getProgram(id);
      if (!mounted) return;

      if (program == null) {
        setState(() => _initialLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Programme introuvable')),
        );
        _applyFilters();
        return;
      }

      setState(() {
        _programNameController.text = program.name;
        _selectedExercises = List.from(program.exercises);
        _initialLoading = false;
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() => _initialLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement programme: $e')),
      );
      _applyFilters();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _programNameController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();

    final matching = _allExercises.where((exo) {
      final matchesName = exo.name.toLowerCase().contains(query);
      final matchesMuscle = _muscleFilter.isEmpty || exo.muscleGroup == _muscleFilter;
      final matchesEquipment = _equipmentFilter.isEmpty || exo.equipment == _equipmentFilter;
      final matchesFav = !_favoritesOnly || exo.isFavorite;
      return matchesName && matchesMuscle && matchesEquipment && matchesFav;
    }).toList();

    final maxCount = ((_page + 1) * _pageSize);
    final pageItems = matching.take(maxCount).toList();

    setState(() {
      _matchingExercisesCount = matching.length;
      _filteredExercises = pageItems;
    });
  }

  void _loadMore() {
    setState(() => _page++);
    _applyFilters();
  }

  void _resetFilters() {
    setState(() {
      _muscleFilter = '';
      _equipmentFilter = '';
      _favoritesOnly = false;
      _searchController.clear();
      _page = 0;
    });
    _applyFilters();
  }

  bool _hasDuplicate(Exercise exercise) =>
      _selectedExercises.any((se) => se.exercise.id == exercise.id);

  void _addExercise(Exercise exercise) {
    if (_hasDuplicate(exercise)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercice déjà présent')),
      );
      return;
    }
    setState(() {
      _selectedExercises.add(SelectedExercise(exercise));
    });
  }

  void _removeExercise(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer'),
        content: const Text('Supprimer cet exercice ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _selectedExercises.removeWhere((se) => se.exercise.id == id));
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  double _calculateDuration() {
    return _selectedExercises.fold(
      0.0,
      (total, se) => total + (se.sets * (se.reps * 0.3 + se.rest / 60)),
    );
  }

  Future<void> _saveProgram() async {
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pas d\'exercice sélectionné')),
      );
      return;
    }
    if (_programNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom du programme requis')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final program = WorkoutProgram(
        id: widget.existingProgram?.id ?? widget.programId,
        name: _programNameController.text.trim(),
        duration: _calculateDuration(),
        exercises: List.from(_selectedExercises),
      );

      final id = await _repo.saveProgram(program);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Programme "${program.name}" sauvegardé (id: $id) ! Durée: ${program.duration.toStringAsFixed(0)} min',
          ),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Programme "${program.name}" sauvegardé (id: $id)')),
      );

      // IMPORTANT: retourner à l’onglet Entraînement
      Navigator.pop(context, id);
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur sauvegarde: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingProgram != null || widget.programId != null;

    if (_initialLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Ouverture du programme...' : 'Création d\'entraînement'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le programme' : 'Création d\'entraînement'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _programNameController,
              decoration: const InputDecoration(
                labelText: 'Nom du programme',
                border: OutlineInputBorder(),
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Ma liste d\'exercices (${_selectedExercises.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: ReorderableListView(
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _selectedExercises.removeAt(oldIndex);
                        _selectedExercises.insert(newIndex, item);
                      });
                    },
                    children: _selectedExercises.map((se) {
                      return ListTile(
                        key: ValueKey(se.exercise.id),
                        title: Text(se.exercise.name),
                        subtitle: Text(
                          'Sets: ${se.sets} | Reps: ${se.reps} | Poids: ${se.weight}kg',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeExercise(se.exercise.id),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _page = 0);
                          _applyFilters();
                        },
                      ),
                    ),
                    onChanged: (_) {
                      setState(() => _page = 0);
                      _applyFilters();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilters,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _resetFilters,
                ),
              ],
            ),
          ),

          Expanded(
            flex: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Bibliothèque d\'exercices',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _filteredExercises.length +
                        (_filteredExercises.length < _matchingExercisesCount ? 1 : 0),
                    itemBuilder: (context, index) {
                      final isLoadMoreTile =
                          index == _filteredExercises.length &&
                          _filteredExercises.length < _matchingExercisesCount;

                      if (isLoadMoreTile) {
                        return Center(
                          child: TextButton(
                            onPressed: _loadMore,
                            child: const Text('Charger plus'),
                          ),
                        );
                      }

                      final exercise = _filteredExercises[index];
                      final isDuplicate = _hasDuplicate(exercise);

                      return Card(
                        margin: const EdgeInsets.all(4),
                        elevation: isDuplicate ? 8 : 2,
                        child: InkWell(
                          onTap: () {},
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(exercise.image, style: const TextStyle(fontSize: 40)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  exercise.name,
                                  style: Theme.of(context).textTheme.titleSmall,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${exercise.muscleGroup} - ${exercise.equipment}',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: isDuplicate ? null : () => _addExercise(exercise),
                                child: Text(isDuplicate ? 'Ajouté' : 'Ajouter'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _saveProgram,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(isEditing ? 'Enregistrer' : 'Aperçu & Sauvegarder'),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Durée estimée: ${_calculateDuration().toStringAsFixed(0)} min',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) => FilterModal(
        muscleFilter: _muscleFilter,
        equipmentFilter: _equipmentFilter,
        favoritesOnly: _favoritesOnly,
        onApply: (muscle, equipment, favorites) {
          setState(() {
            _muscleFilter = muscle;
            _equipmentFilter = equipment;
            _favoritesOnly = favorites;
            _page = 0;
          });
          _applyFilters();
        },
      ),
    );
  }
}

class FilterModal extends StatefulWidget {
  final String muscleFilter;
  final String equipmentFilter;
  final bool favoritesOnly;
  final Function(String, String, bool) onApply;

  const FilterModal({
    super.key,
    required this.muscleFilter,
    required this.equipmentFilter,
    required this.favoritesOnly,
    required this.onApply,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late String _muscle;
  late String _equipment;
  late bool _favorites;

  @override
  void initState() {
    super.initState();
    _muscle = widget.muscleFilter;
    _equipment = widget.equipmentFilter;
    _favorites = widget.favoritesOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Filtres',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _muscle.isEmpty ? null : _muscle,
            hint: const Text('Groupe musculaire'),
            items: ['Jambes', 'Dos', 'Pecs']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _muscle = v ?? ''),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _equipment.isEmpty ? null : _equipment,
            hint: const Text('Équipement'),
            items: ['Barre', 'Machine', 'Libre']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _equipment = v ?? ''),
          ),
          CheckboxListTile(
            title: const Text('Favoris seulement'),
            value: _favorites,
            onChanged: (v) => setState(() => _favorites = v ?? false),
          ),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_muscle, _equipment, _favorites);
                    Navigator.pop(context);
                  },
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
