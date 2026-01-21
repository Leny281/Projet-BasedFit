import 'package:flutter/material.dart';
import 'dart:math'; // Pour mock durée

class Exercise {
  final String id;
  final String name;
  final String image;
  final String muscleGroup;
  final String equipment;
  final bool isFavorite;

  Exercise({
    required this.id,
    required this.name,
    required this.image,
    required this.muscleGroup,
    required this.equipment,
    this.isFavorite = false,
  });
}

class SelectedExercise {
  Exercise exercise;
  int sets;
  int reps;
  double weight;
  int rest;
  String notes;

  SelectedExercise(this.exercise, {
    this.sets = 3,
    this.reps = 10,
    this.weight = 0,
    this.rest = 60,
    this.notes = '',
  });
}

class CreateWorkoutScreen extends StatefulWidget {
  const CreateWorkoutScreen({super.key});

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
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
  
  List<Exercise> _filteredExercises = [];
  List<SelectedExercise> _selectedExercises = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _programNameController = TextEditingController();
  String _muscleFilter = '';
  String _equipmentFilter = '';
  bool _favoritesOnly = false;
  bool _loading = false;
  int _page = 0;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  void _loadPage() {
    setState(() {
      _filteredExercises = _allExercises.skip(_page * _pageSize).take(_pageSize).toList();
    });
  }

  void _applyFilters() {
    var filtered = _allExercises.where((exo) {
      return exo.name.toLowerCase().contains(_searchController.text.toLowerCase()) &&
             (_muscleFilter.isEmpty || exo.muscleGroup == _muscleFilter) &&
             (_equipmentFilter.isEmpty || exo.equipment == _equipmentFilter) &&
             (!_favoritesOnly || exo.isFavorite);
    }).toList();
    setState(() => _filteredExercises = filtered.take((_page + 1) * _pageSize).toList());
  }

  bool _hasDuplicate(Exercise exercise) => 
    _selectedExercises.any((se) => se.exercise.id == exercise.id);

  void _addExercise(Exercise exercise) {
    if (_hasDuplicate(exercise)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercice déjà présent')), // EF-ENT-PROG-40
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
        content: const Text('Supprimer cet exercice ?'), // EF-ENT-PROG-41
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
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
    return _selectedExercises.fold(0.0, (total, se) => 
      total + (se.sets * (se.reps * 0.3 + se.rest / 60)));
  }

  void _saveProgram() {
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pas d\'exercice sélectionné')), // EF-ENT-PROG-5
      );
      return;
    }
    if (_programNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom du programme requis')),
      );
      return;
    }

    setState(() => _loading = true);
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Programme "${_programNameController.text}" sauvegardé ! Durée: ${_calculateDuration().toStringAsFixed(0)} min')), // EF-ENT-PROG-24
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Création d\'entraînement'), // EF-ENT-PROG-3
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          // Nom programme EF-ENT-PROG-28
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
          
          // Liste sélectionnés EF-ENT-PROG-19 (Drag & Drop simplifié)
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Ma liste d\'exercices (${_selectedExercises.length})', // EF-ENT-PROG-19
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
                    children: _selectedExercises.asMap().entries.map((entry) {
                      final index = entry.key;
                      final se = entry.value;
                      return ListTile(
                        key: ValueKey(se.exercise.id),
                        title: Text(se.exercise.name),
                        subtitle: Text('Sets: ${se.sets} | Reps: ${se.reps} | Poids: ${se.weight}kg'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeExercise(se.exercise.id), // EF-ENT-PROG-41
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Filtres & Recherche EF-ENT-PROG-7,33,47
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(
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
                              _applyFilters();
                            },
                          ),
                        ),
                        onChanged: (_) => _applyFilters(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () => _showFilters(), // Modal filtres
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        _muscleFilter = '';
                        _equipmentFilter = '';
                        _favoritesOnly = false;
                        _searchController.clear();
                        _applyFilters();
                      }, // EF-ENT-PROG-47
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bibliothèque exercices EF-ENT-PROG-6 (2/ligne)
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
                      crossAxisCount: 2, // EF-ENT-PROG-6
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _filteredExercises.length + (_page * _pageSize < _allExercises.length ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _filteredExercises.length) {
                        return Center(
                          child: TextButton(
                            onPressed: _loadPage, // EF-ENT-PROG-49
                            child: const Text('Charger plus'),
                          ),
                        );
                      }
                      final exercise = _filteredExercises[index];
                      return Card(
                        margin: const EdgeInsets.all(4),
                        elevation: _hasDuplicate(exercise) ? 8 : 2, // EF-ENT-PROG-34 (grisé)
                        child: InkWell(
                          onTap: () => {/* Détails EF-ENT-PROG-14 */},
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(exercise.image, style: const TextStyle(fontSize: 40)), 
                              Text(exercise.name, style: Theme.of(context).textTheme.titleSmall),
                              Text('${exercise.muscleGroup} - ${exercise.equipment}'),
                              ElevatedButton(
                                onPressed: () => _addExercise(exercise), // EF-ENT-PROG-12
                                child: const Text('Ajouter'),
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

          // Boutons sauvegarde EF-ENT-PROG-23,44
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _saveProgram,
                    icon: _loading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.preview),
                    label: const Text('Aperçu & Sauvegarder'), // EF-ENT-PROG-46
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Durée estimée: ${_calculateDuration().toStringAsFixed(0)} min', // EF-ENT-PROG-29
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
          _muscleFilter = muscle;
          _equipmentFilter = equipment;
          _favoritesOnly = favorites;
          _applyFilters();
        },
      ),
    );
  }
}

// Modal Filtres (EF-ENT-PROG-7)
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
          const Text('Filtres', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          DropdownButtonFormField<String>(
            value: _muscle.isEmpty ? null : _muscle,
            hint: const Text('Groupe musculaire'),
            items: ['Jambes', 'Dos', 'Pecs'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _muscle = v ?? ''),
          ),
          DropdownButtonFormField<String>(
            value: _equipment.isEmpty ? null : _equipment,
            hint: const Text('Équipement'),
            items: ['Barre', 'Machine', 'Libre'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
