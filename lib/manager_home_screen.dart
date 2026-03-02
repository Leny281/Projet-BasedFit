import 'package:flutter/material.dart';
import 'data/app_database.dart';

class ManagerHomeScreen extends StatefulWidget {
  final int managerId;
  const ManagerHomeScreen({super.key, required this.managerId});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  int _currentIndex = 0;
  String _gymName = '';

  @override
  void initState() {
    super.initState();
    _loadGymName();
  }

  Future<void> _loadGymName() async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      'gyms',
      columns: ['name'],
      where: 'manager_user_id = ?',
      whereArgs: [widget.managerId],
      limit: 1,
    );
    if (result.isNotEmpty && mounted) {
      setState(() => _gymName = result.first['name'] as String);
    }
  }

  List<Widget> get _pages => [
    _DashboardPage(managerId: widget.managerId, gymName: _gymName),
    _UsersPage(managerId: widget.managerId, gymName: _gymName),
    const _MusicPage(),
    const _EventsPage(),
  ];

  final List<String> _titles = const [
    'Tableau de bord',
    'Utilisateurs',
    'Musiques & Playlists',
    'Événements',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => Navigator.of(context).pushReplacementNamed('/auth'),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey[500],
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        backgroundColor: Colors.white,
        elevation: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Utilisateurs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note_outlined),
            activeIcon: Icon(Icons.music_note),
            label: 'Musiques',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_outlined),
            activeIcon: Icon(Icons.event),
            label: 'Événements',
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  PAGE 1 — TABLEAU DE BORD
// ════════════════════════════════════════════════════════════════════

class _DashboardPage extends StatefulWidget {
  final int managerId;
  final String gymName;
  const _DashboardPage({required this.managerId, required this.gymName});

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  int _currentlyInGym = 0;
  int _totalToday = 0;
  double _averageNow = 0.0;

  String get _currentTimeLabel {
    final now = DateTime.now();
    final days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final day = days[now.weekday - 1];
    final hour = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    return '$day $hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.gymName.isNotEmpty ? widget.gymName : 'Ma salle',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text(_currentTimeLabel,
                        style: TextStyle(fontSize: 13, color: Colors.blue[700])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[900]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bar_chart, color: Colors.white70, size: 18),
                    SizedBox(width: 8),
                    Text('Fréquentation de la salle',
                        style: TextStyle(color: Colors.white70, fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$_currentlyInGym',
                        style: const TextStyle(color: Colors.white, fontSize: 64,
                            fontWeight: FontWeight.bold, height: 1)),
                    const SizedBox(width: 12),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('personnes\nen ce moment',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(width: 8, height: 8,
                        decoration: const BoxDecoration(
                            color: Color(0xFF4ADE80), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text('En direct',
                        style: TextStyle(color: Color(0xFF4ADE80), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.white24),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatMini(icon: Icons.today, label: "Aujourd'hui",
                          value: '$_totalToday', unit: 'passages au total'),
                    ),
                    Container(width: 1, height: 50, color: Colors.white24),
                    Expanded(
                      child: _StatMini(icon: Icons.show_chart, label: 'Moyenne habituelle',
                          value: _averageNow.toStringAsFixed(0), unit: 'à cette heure ce jour'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('À venir...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[400])),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  PAGE 2 — UTILISATEURS DE LA SALLE
// ════════════════════════════════════════════════════════════════════

class _UsersPage extends StatefulWidget {
  final int managerId;
  final String gymName;
  const _UsersPage({required this.managerId, required this.gymName});

  @override
  State<_UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<_UsersPage> {
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  int? _gymId;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final db = await AppDatabase.instance.database;

    // Récupérer l'id de la salle du gérant
    final gymResult = await db.query(
      'gyms',
      columns: ['id'],
      where: 'manager_user_id = ?',
      whereArgs: [widget.managerId],
      limit: 1,
    );

    if (gymResult.isEmpty) {
      setState(() { _loading = false; });
      return;
    }

    final gymId = gymResult.first['id'] as int;
    setState(() => _gymId = gymId);

    // Récupérer les utilisateurs ayant cette salle en favori
    final members = await db.rawQuery('''
      SELECT u.id, u.first_name, u.last_name, u.email, u.goal, u.created_at
      FROM users u
      INNER JOIN user_gym_favorites f ON f.user_id = u.id
      WHERE f.gym_id = ? AND u.is_admin = 0
      ORDER BY u.first_name ASC
    ''', [gymId]);

    setState(() {
      _members = members;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_gymId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Aucune salle associée à ce compte.',
                style: TextStyle(color: Colors.grey[500], fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: _members.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(32),
              children: [
                const SizedBox(height: 60),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun membre n\'a encore\nchoisi votre salle en favori.',
                        style: TextStyle(color: Colors.grey[500], fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _members.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${_members.length} membre${_members.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        if (widget.gymName.isNotEmpty) ...[
                          Text(' — ${widget.gymName}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        ],
                      ],
                    ),
                  );
                }
                final member = _members[index - 1];
                final initials =
                    '${(member['first_name'] as String).substring(0, 1)}'
                    '${(member['last_name'] as String).substring(0, 1)}'.toUpperCase();
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Text(initials,
                          style: TextStyle(color: Colors.blue[700],
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text(
                      '${member['first_name']} ${member['last_name']}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(member['email'] as String),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        member['goal'] as String? ?? '',
                        style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  PAGES PLACEHOLDER
// ════════════════════════════════════════════════════════════════════

class _MusicPage extends StatelessWidget {
  const _MusicPage();
  @override
  Widget build(BuildContext context) => _PlaceholderPage(
        icon: Icons.library_music, title: 'Musiques & Playlists',
        description: 'Gérez la musique diffusée\ndans votre salle.',
        color: Colors.purple);
}

class _EventsPage extends StatelessWidget {
  const _EventsPage();
  @override
  Widget build(BuildContext context) => _PlaceholderPage(
        icon: Icons.event, title: 'Événements de la salle',
        description: 'Créez et gérez les événements\net animations de votre salle.',
        color: Colors.teal);
}

class _PlaceholderPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final MaterialColor color;
  const _PlaceholderPage({required this.icon, required this.title,
      required this.description, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: color[50], shape: BoxShape.circle),
            child: Icon(icon, size: 56, color: color[700]),
          ),
          const SizedBox(height: 24),
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color[800])),
          const SizedBox(height: 12),
          Text(description, style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: color[50], borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color[200]!),
            ),
            child: Text('Contenu à venir',
                style: TextStyle(fontSize: 13, color: color[600], fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  const _StatMini({required this.icon, required this.label,
      required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: Colors.white54, size: 14),
            const SizedBox(width: 4),
            Flexible(child: Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 12))),
          ]),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 28,
              fontWeight: FontWeight.bold, height: 1)),
          Text(unit, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }
}