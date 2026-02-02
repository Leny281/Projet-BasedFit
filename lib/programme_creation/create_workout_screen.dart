import 'package:flutter/material.dart';

import 'models.dart';
import '../data/workout_repository.dart';
import '../data/workout_database.dart';
import '../data/exercise_catalog_service.dart';
import 'exercise_params_editor.dart';

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
  bool _hasUnsavedChanges = false;

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
      // Fallback local si l'API est indisponible
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

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
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
        const SnackBar(
          content: Text('Exercice déjà présent'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _selectedExercises.add(SelectedExercise(exercise));
    });
    _markAsChanged();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${exercise.name} ajouté'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removeExercise(int index) {
    final exercise = _selectedExercises[index];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text('Supprimer "${exercise.exercise.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedExercises.removeAt(index);
              });
              _markAsChanged();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _updateExercise(int index, SelectedExercise updated) {
    setState(() {
      _selectedExercises[index] = updated;
    });
    _markAsChanged();
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _selectedExercises.removeAt(oldIndex);
      _selectedExercises.insert(newIndex, item);
    });
    _markAsChanged();
  }

  double _calculateDuration() {
    return _selectedExercises.fold(
      0.0,
      (total, se) => total + (se.sets * (se.reps * 0.05 + se.rest / 60 + 0.5)),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifications non sauvegardées'),
        content: const Text(
          'Vous avez des modifications non sauvegardées. Voulez-vous vraiment quitter ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _saveProgram() async {
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ajoutez au moins un exercice"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_programNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donnez un nom au programme'),
          backgroundColor: Colors.orange,
        ),
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

      setState(() => _hasUnsavedChanges = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Programme "${program.name}" sauvegardé !'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur sauvegarde: $e'),
          backgroundColor: Colors.red,
        ),
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
          height: 90,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 90,
            alignment: Alignment.center,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image),
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 90,
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

    // Fallback si pas d'URL: icône
    return Container(
      height: 90,
      alignment: Alignment.center,
      color: Colors.grey.shade100,
      child: const Icon(Icons.fitness_center, size: 36),
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

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Modifier le programme' : "Création d'entraînement"),
          backgroundColor: Theme.of(context).primaryColor,
          actions: [
            if (_hasUnsavedChanges)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Non sauvegardé',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
              ),
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
            // Nom du programme
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _programNameController,
                onChanged: (_) => _markAsChanged(),
                decoration: InputDecoration(
                  labelText: 'Nom du programme',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.edit),
                ),
              ),
            ),

            // Résumé
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(
                    icon: Icons.fitness_center,
                    label: 'Exercices',
                    value: '${_selectedExercises.length}',
                  ),
                  _SummaryItem(
                    icon: Icons.repeat,
                    label: 'Séries totales',
                    value: '${_selectedExercises.fold(0, (sum, e) => sum + e.sets)}',
                  ),
                  _SummaryItem(
                    icon: Icons.timer,
                    label: 'Durée estimée',
                    value: '${_calculateDuration().toStringAsFixed(0)} min',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Liste des exercices sélectionnés
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.list_alt, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          "Ma liste d'exercices",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Spacer(),
                        if (_selectedExercises.isNotEmpty)
                          Text(
                            '${_selectedExercises.length} exercice${_selectedExercises.length > 1 ? 's' : ''}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _selectedExercises.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Ajoutez des exercices depuis la bibliothèque',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            itemCount: _selectedExercises.length,
                            onReorder: _reorderExercises,
                            itemBuilder: (context, index) {
                              final se = _selectedExercises[index];
                              return ExerciseParamsEditor(
                                key: ValueKey(se.exercise.id),
                                selectedExercise: se,
                                index: index + 1,
                                onChanged: (updated) => _updateExercise(index, updated),
                                onDelete: () => _removeExercise(index),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            // Divider
            Container(
              height: 8,
              color: Colors.grey[200],
            ),

            // Recherche + filtres
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un exercice...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _page = 0);
                                  _applyFilters();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onChanged: (_) {
                        setState(() => _page = 0);
                        _applyFilters();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Badge(
                      isLabelVisible: _muscleFilter.isNotEmpty ||
                          _equipmentFilter.isNotEmpty ||
                          _favoritesOnly,
                      child: const Icon(Icons.filter_list),
                    ),
                    onPressed: _catalogLoading ? null : _showFilters,
                    tooltip: 'Filtres',
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _resetFilters,
                    tooltip: 'Réinitialiser',
                  ),
                ],
              ),
            ),

            // Bibliothèque d'exercices
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.library_books, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          "Bibliothèque",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        if (_catalogLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Text(
                            '$_matchingExercisesCount exercices',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  if (_catalogError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, size: 16, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _catalogError!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _filteredExercises.length +
                          (_filteredExercises.length < _matchingExercisesCount ? 1 : 0),
                      itemBuilder: (context, index) {
                        final isLoadMoreTile = index == _filteredExercises.length &&
                            _filteredExercises.length < _matchingExercisesCount;

                        if (isLoadMoreTile) {
                          return Center(
                            child: TextButton.icon(
                              onPressed: _loadMore,
                              icon: const Icon(Icons.expand_more),
                              label: const Text('Charger plus'),
                            ),
                          );
                        }

                        final exercise = _filteredExercises[index];
                        final isDuplicate = _hasDuplicate(exercise);

                        return Card(
                          elevation: isDuplicate ? 0 : 2,
                          color: isDuplicate ? Colors.grey[100] : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isDuplicate
                                ? BorderSide(color: Colors.green[300]!, width: 2)
                                : BorderSide.none,
                          ),
                          child: InkWell(
                            onTap: isDuplicate ? null : () => _addExercise(exercise),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Stack(
                                      children: [
                                        _exerciseImage(exercise),
                                        if (isDuplicate)
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    exercise.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    exercise.muscleGroup,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    height: 32,
                                    child: ElevatedButton(
                                      onPressed: isDuplicate ? null : () => _addExercise(exercise),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            isDuplicate ? Colors.grey[300] : Theme.of(context).primaryColor,
                                        foregroundColor: isDuplicate ? Colors.grey[600] : Colors.white,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        isDuplicate ? '✓ Ajouté' : '+ Ajouter',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
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

            // Bouton sauvegarde
            Container(
              padding: const EdgeInsets.all(12),
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
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _saveProgram,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _saving
                          ? 'Sauvegarde...'
                          : (isEditing ? 'Enregistrer les modifications' : 'Sauvegarder le programme'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

/// Widget résumé
class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
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

          const Text(
            'Filtres',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Muscle
          const Text(
            'Groupe musculaire',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _muscle.isEmpty ? null : _muscle,
            hint: const Text('Tous les muscles'),
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Tous les muscles')),
              ...widget.muscleOptions.map(
                (e) => DropdownMenuItem(value: e, child: Text(e)),
              ),
            ],
            onChanged: (v) => setState(() => _muscle = v ?? ''),
          ),

          const SizedBox(height: 16),

          // Équipement
          const Text(
            'Équipement',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _equipment.isEmpty ? null : _equipment,
            hint: const Text('Tout équipement'),
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Tout équipement')),
              ...widget.equipmentOptions.map(
                (e) => DropdownMenuItem(value: e, child: Text(e)),
              ),
            ],
            onChanged: (v) => setState(() => _equipment = v ?? ''),
          ),

          const SizedBox(height: 12),

          // Favoris
          SwitchListTile(
            title: const Text('Favoris uniquement'),
            value: _favorites,
            onChanged: (v) => setState(() => _favorites = v),
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 20),

          // Boutons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _muscle = '';
                      _equipment = '';
                      _favorites = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Réinitialiser'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_muscle, _equipment, _favorites);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}