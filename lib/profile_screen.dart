import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'models/user_model.dart';
import 'data/app_database.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  User? _user;

  // Statistiques
  int _workoutsCompleted = 0;
  int _totalDays = 0;
  int _currentStreak = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _user = _authService.currentUser;
    if (_user != null) {
      final stats = await _authService.getUserStats();
      setState(() {
        _workoutsCompleted = stats['workouts_completed'] ?? 0;
        _totalDays = stats['total_days'] ?? 0;
        _currentStreak = stats['current_streak'] ?? 0;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_user == null) {
      return const Center(
        child: Text('Erreur: Utilisateur non connecté'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du profil
          _buildProfileHeader(),
          const SizedBox(height: 24),

          // Statistiques rapides
          _buildStatsCards(),
          const SizedBox(height: 24),

          // Informations personnelles
          _buildPersonalInfo(),
          const SizedBox(height: 24),

          // Salles de sport favorites
          _GymFavoritesSection(userId: _user!.id),
          const SizedBox(height: 24),

          // Badges et réalisations
          _buildBadgesSection(),
          const SizedBox(height: 24),

          // Paramètres
          _buildSettingsSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Photo de profil
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    _user!.firstName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            // Informations de base
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _user!.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_user!.age} ans • ${_user!.goal}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _editProfile,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modifier'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.fitness_center,
            label: 'Entraînements',
            value: '$_workoutsCompleted',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_today,
            label: 'Jours actifs',
            value: '$_totalDays',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department,
            label: 'Streak',
            value: '$_currentStreak j',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo() {
    final bmi = _user!.weight / ((_user!.height / 100) * (_user!.height / 100));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Infos personnelles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editPersonalInfo,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.scale, 'Poids', '${_user!.weight.toStringAsFixed(1)} kg'),
            _buildInfoRow(Icons.height, 'Taille', '${_user!.height.toStringAsFixed(0)} cm'),
            _buildInfoRow(
              Icons.analytics,
              'IMC',
              '${bmi.toStringAsFixed(1)}',
              subtitle: _getBMICategory(bmi),
            ),
            _buildInfoRow(Icons.flag, 'Objectif', _user!.goal),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Badges & Réalisations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildBadge(
                  icon: Icons.emoji_events,
                  label: 'Débutant',
                  color: Colors.brown,
                  unlocked: true,
                ),
                _buildBadge(
                  icon: Icons.local_fire_department,
                  label: 'Série de 7',
                  color: Colors.orange,
                  unlocked: false,
                ),
                _buildBadge(
                  icon: Icons.star,
                  label: '50 Workouts',
                  color: Colors.amber,
                  unlocked: false,
                ),
                _buildBadge(
                  icon: Icons.military_tech,
                  label: 'Warrior',
                  color: Colors.purple,
                  unlocked: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
    required bool unlocked,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: unlocked ? color : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: unlocked ? Colors.black : Colors.grey[500],
            fontWeight: unlocked ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Gérer les notifications',
            onTap: () {
              // TODO: Ouvrir paramètres notifications
            },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.lock,
            title: 'Confidentialité',
            subtitle: 'Paramètres de confidentialité',
            onTap: () {
              // TODO: Ouvrir paramètres confidentialité
            },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.help,
            title: 'Aide & Support',
            subtitle: 'FAQ et assistance',
            onTap: () {
              // TODO: Ouvrir aide
            },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.info,
            title: 'À propos',
            subtitle: 'Version 1.0.0',
            onTap: () {
              _showAboutDialog();
            },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.logout,
            title: 'Déconnexion',
            subtitle: 'Se déconnecter de l\'application',
            titleColor: Colors.red,
            onTap: _logout,
          ),
          const Divider(height: 1),
          // ── Suppression de compte ─────────────────────────────────
          _buildSettingTile(
            icon: Icons.delete_forever,
            title: 'Supprimer mon compte',
            subtitle: 'Cette action est irréversible',
            titleColor: Colors.red[800],
            onTap: _deleteAccount,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? Colors.blue),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: titleColor,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Insuffisance pondérale';
    if (bmi < 25) return 'Poids normal';
    if (bmi < 30) return 'Surpoids';
    return 'Obésité';
  }

  void _editProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations du profil'),
        content: const Text(
          'Le nom, prénom et l\'âge ne peuvent pas être modifiés.\n\n'
          'Pour modifier la taille, le poids et l\'objectif, utilisez '
          'la section "Informations personnelles".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _editPersonalInfo() async {
    final weightController = TextEditingController(text: _user!.weight.toString());
    final heightController = TextEditingController(text: _user!.height.toString());
    String selectedGoal = _user!.goal;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations personnelles'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(
                    labelText: 'Poids (kg)',
                    suffixText: 'kg',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: heightController,
                  decoration: const InputDecoration(
                    labelText: 'Taille (cm)',
                    suffixText: 'cm',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Objectif'),
                  value: selectedGoal,
                  items: const [
                    DropdownMenuItem(
                      value: 'Prise de masse',
                      child: Text('Prise de masse'),
                    ),
                    DropdownMenuItem(
                      value: 'Perte de poids',
                      child: Text('Perte de poids'),
                    ),
                    DropdownMenuItem(
                      value: 'Maintien',
                      child: Text('Maintien'),
                    ),
                    DropdownMenuItem(
                      value: 'Remise en forme',
                      child: Text('Remise en forme'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedGoal = value ?? selectedGoal;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result == true) {
      final newWeight = double.tryParse(weightController.text);
      final newHeight = double.tryParse(heightController.text);

      if (newWeight != null && newHeight != null) {
        final updatedUser = _user!.copyWith(
          weight: newWeight,
          height: newHeight,
          goal: selectedGoal,
        );

        await _authService.updateUser(updatedUser);
        setState(() {
          _user = updatedUser;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Informations mises à jour'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('À propos de BasedFit'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BasedFit - Application de fitness'),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 16),
            Text(
              'Une application complète pour suivre vos entraînements, votre nutrition et votre progression.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _authService.logout();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/auth',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  // ── Suppression de compte ────────────────────────────────────────────────

  void _deleteAccount() {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
            const SizedBox(width: 8),
            const Text('Supprimer mon compte'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cette action est définitive et irréversible.\n\n'
              'Toutes vos données (programmes, stats, favoris) seront supprimées.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmez votre mot de passe',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text.trim();
              if (password.isEmpty) return;

              // Vérifier le mot de passe
              final db = await AppDatabase.instance.database;
              final hashed = AppDatabase.hashPassword(password);
              final result = await db.query(
                'users',
                where: 'id = ? AND password = ?',
                whereArgs: [_user!.id, hashed],
                limit: 1,
              );

              if (result.isEmpty) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mot de passe incorrect.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              // Supprimer l'utilisateur (CASCADE supprime ses favoris, stats, etc.)
              await db.delete('users', where: 'id = ?', whereArgs: [_user!.id]);
              await _authService.logout();

              if (mounted) {
                Navigator.pop(context);
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/auth',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  SECTION SALLES FAVORITES (max 3)
// ════════════════════════════════════════════════════════════════════

class _GymFavoritesSection extends StatefulWidget {
  final int userId;
  const _GymFavoritesSection({required this.userId});

  @override
  State<_GymFavoritesSection> createState() => _GymFavoritesSectionState();
}

class _GymFavoritesSectionState extends State<_GymFavoritesSection> {
  List<Map<String, dynamic>> _favorites = [];
  List<Map<String, dynamic>> _allGyms = [];
  bool _loading = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = await AppDatabase.instance.database;

    final favs = await db.rawQuery('''
      SELECT g.id, g.name
      FROM gyms g
      INNER JOIN user_gym_favorites f ON f.gym_id = g.id
      WHERE f.user_id = ?
      ORDER BY f.created_at ASC
    ''', [widget.userId]);

    final all = await db.query('gyms', columns: ['id', 'name'], orderBy: 'name ASC');

    setState(() {
      _favorites = favs;
      _allGyms = all;
      _loading = false;
    });
  }

  Future<void> _addFavorite(int gymId) async {
    if (_favorites.length >= 3) return;
    final db = await AppDatabase.instance.database;
    await db.insert('user_gym_favorites', {
      'user_id': widget.userId,
      'gym_id': gymId,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _load();
  }

  Future<void> _removeFavorite(int gymId) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'user_gym_favorites',
      where: 'user_id = ? AND gym_id = ?',
      whereArgs: [widget.userId, gymId],
    );
    await _load();
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final favoriteIds = _favorites.map((f) => f['id'] as int).toSet();
          final filtered = _allGyms
              .where((g) =>
                  !favoriteIds.contains(g['id'] as int) &&
                  (g['name'] as String)
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()))
              .toList();

          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Choisir une salle',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Rechercher une salle...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setModalState(() => _searchQuery = '');
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onChanged: (v) {
                    setModalState(() => _searchQuery = v);
                    setState(() => _searchQuery = v);
                  },
                ),
                const SizedBox(height: 8),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'Il n\'existe aucune salle pour l\'instant.'
                            : 'Aucune salle trouvée pour "$_searchQuery".',
                        style: TextStyle(color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final gym = filtered[i];
                        return ListTile(
                          leading: Icon(Icons.fitness_center,
                              color: Colors.blue[700]),
                          title: Text(gym['name'] as String),
                          trailing: const Icon(Icons.add_circle_outline,
                              color: Colors.blue),
                          onTap: () {
                            Navigator.pop(context);
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _addFavorite(gym['id'] as int);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mes salles favorites',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${_favorites.length}/3',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Text("Ajoutez jusqu'à 3 salles de sport",
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 16),

            if (_favorites.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text("Aucune salle ajoutée pour l'instant.",
                    style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              )
            else
              ..._favorites.map((gym) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.fitness_center,
                            color: Colors.blue[700], size: 20),
                        title: Text(gym['name'] as String,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: IconButton(
                          icon: Icon(Icons.remove_circle_outline,
                              color: Colors.red[400]),
                          onPressed: () => _removeFavorite(gym['id'] as int),
                          tooltip: 'Retirer',
                        ),
                      ),
                    ),
                  )),

            if (_favorites.length < 3) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.search),
                  label: const Text('Rechercher une salle'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}