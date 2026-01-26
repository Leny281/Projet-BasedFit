import 'package:flutter/material.dart';

import 'models.dart';
import 'data/workout_repository.dart';
import 'data/workout_database.dart';
import 'data/exercise_catalog_service.dart';

class CreateWorkoutScreen extends StatefulWidget {
  final WorkoutProgram? existingProgram;
  final int? programId;

  const CreateWorkoutScreen({
    super.key,
    this.existingProgram,
    this.programId,
  }) : assert(
          existingProgram == null || programId == null,
          'Pass either existingProgram OR programId, not both.',
        );

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  final WorkoutRepository _repo = WorkoutRepository();
  final ExerciseCatalogService _catalog = ExerciseCatalogService();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _programNameController = TextEditingController();

  List<Exercise> _allExercises = [];
  List<Exercise> _filteredExercises = [];
  int _matchingExercisesCount = 0;

  List<SelectedExercise> _selectedExercises = [];

  String _muscleFilter = '';
  String _equipmentFilter = '';
  bool _favoritesOnly = false;

  bool _initialLoading = true;
  bool _catalogLoading = true;
  String? _catalogError;

  bool _saving = false;

  int _page = 0;
  final int _pageSize = 20;

  List<String> _muscleOptions = [];
  List<String> _equipmentOptions = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 0) Init DB
    try {
      await WorkoutDatabase.instance.database;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initialLoading = false;
        _catalogLoading = false;
        _catalogError = 'Erreur BDD: $e';
      });
      return;
    }

    // 1) Charger le catalogue d'exercices (API) + fallback local si besoin
    await _loadExerciseCatalog();

    // 2) Pré-remplir si édition directe
    if (widget.existingProgram != null) {
      _programNameController.text = widget.existingProgram!.name;
      _selectedExercises = List.from(widget.existingProgram!.exercises);
      if (!mounted) return;
      setState(() => _initialLoading = false);
      _applyFilters();
      return;
    }

    // 3) Charger depuis la DB si programId fourni
    if (widget.programId != null) {
      await _loadProgramFromDb(widget.programId!);
      return;
    }

    // 4) Nouveau programme
    if (!mounted) return;
    setState(() => _initialLoading = false);
    _applyFilters();
  }

  Future<void> _loadExerciseCatalog() async {
    try {
      final exercises = await _catalog.fetchExercises(limit: 120);

      // Options dynamiques (menus filtres)
      final muscles = <String>{};
      final equipments = <String>{};
      for (final e in exercises) {
        if (e.muscleGroup.trim().isNotEmpty) muscles.add(e.muscleGroup.trim());
        if (e.equipment.trim().isNotEmpty) equipments.add(e.equipment.trim());
      }

      if (!mounted) return;
      setState(() {
        _allExercises = exercises;
        _muscleOptions = muscles.toList()..sort();
        _equipmentOptions = equipments.toList()..sort();
        _catalogLoading = false;
        _catalogError = null;
      });

      _applyFilters();
    } catch (e) {
      // Fallback local si l’API est indisponible
      final exercises = ExerciseCatalogService.fallbackExercises();

      final muscles = <String>{};
      final equipments = <String>{};
      for (final exo in exercises) {
        if (exo.muscleGroup.trim().isNotEmpty) muscles.add(exo.muscleGroup.trim());
        if (exo.equipment.trim().isNotEmpty) equipments.add(exo.equipment.trim());
      }

      if (!mounted) return;
      setState(() {
        _allExercises = exercises;
        _muscleOptions = muscles.toList()..sort();
        _equipmentOptions = equipments.toList()..sort();
        _catalogLoading = false;
        _catalogError = 'Catalogue en mode hors-ligne (API indisponible).';
      });

      _applyFilters();
    }
  }

  Future<void> _loadProgramFromDb(int id) async {
    try {
      final program = await _repo.getProgram(id);

      if (!mounted) return;

      if (program == null) {
        setState(() {
          _initialLoading = false;
        });
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
              setState(() {
                _selectedExercises.removeWhere((se) => se.exercise.id == id);
              });
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
        const SnackBar(content: Text("Pas d'exercice sélectionné")),
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
        SnackBar(content: Text('Programme "${program.name}" sauvegardé (id: $id)')),
      );

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

  Widget _exerciseImage(Exercise exercise) {
    final value = exercise.image.trim();

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          value,
          height: 95,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 95,
            alignment: Alignment.center,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image),
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 95,
              alignment: Alignment.center,
              color: Colors.grey.shade100,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      );
    }

    // Fallback si pas d’URL: icône
    return Container(
      height: 95,
      alignment: Alignment.center,
      color: Colors.grey.shade100,
      child: const Icon(Icons.fitness_center, size: 40),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingProgram != null || widget.programId != null;

    if (_initialLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Ouverture du programme...' : "Création d'entraînement"),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier le programme' : "Création d'entraînement"),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            tooltip: 'Recharger le catalogue',
            onPressed: _catalogLoading
                ? null
                : () async {
                    setState(() {
                      _catalogLoading = true;
                      _catalogError = null;
                      _page = 0;
                    });
                    await _loadExerciseCatalog();
                  },
            icon: const Icon(Icons.cloud_download),
          ),
        ],
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

          // Liste sélectionnée
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Ma liste d'exercices (${_selectedExercises.length})",
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

          // Recherche + filtres
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
                  onPressed: _catalogLoading ? null : _showFilters,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _resetFilters,
                ),
              ],
            ),
          ),

          // Bibliothèque d'exercices
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "Bibliothèque d'exercices",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_catalogLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text('Chargement du catalogue...'),
                        )
                      else if (_catalogError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _catalogError!,
                            style: TextStyle(color: Colors.orange.shade800),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.78,
                    ),
                    itemCount:
                        _filteredExercises.length + (_filteredExercises.length < _matchingExercisesCount ? 1 : 0),
                    itemBuilder: (context, index) {
                      final isLoadMoreTile = index == _filteredExercises.length &&
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
                          onTap: isDuplicate ? null : () => _addExercise(exercise),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _exerciseImage(exercise),
                                const SizedBox(height: 10),
                                Text(
                                  exercise.name,
                                  style: Theme.of(context).textTheme.titleSmall,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${exercise.muscleGroup}${exercise.equipment.isEmpty ? '' : ' • ${exercise.equipment}'}',
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                ElevatedButton(
                                  onPressed: isDuplicate ? null : () => _addExercise(exercise),
                                  child: Text(isDuplicate ? 'Ajouté' : 'Ajouter'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Sauvegarde
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
        muscleOptions: _muscleOptions,
        equipmentOptions: _equipmentOptions,
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

  final List<String> muscleOptions;
  final List<String> equipmentOptions;

  final Function(String, String, bool) onApply;

  const FilterModal({
    super.key,
    required this.muscleFilter,
    required this.equipmentFilter,
    required this.favoritesOnly,
    required this.muscleOptions,
    required this.equipmentOptions,
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
            items: widget.muscleOptions
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _muscle = v ?? ''),
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _equipment.isEmpty ? null : _equipment,
            hint: const Text('Équipement'),
            items: widget.equipmentOptions
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
