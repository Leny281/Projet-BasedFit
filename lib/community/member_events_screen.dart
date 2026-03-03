import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class MemberEventsScreen extends StatefulWidget {
  final int userId;

  const MemberEventsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<MemberEventsScreen> createState() => _MemberEventsScreenState();
}

class _MemberEventsScreenState extends State<MemberEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _availableEvents = [];
  List<Event> _myEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      final available = await EventService.getEventsForUser(widget.userId);
      final myEvents = await EventService.getUserEvents(widget.userId);

      setState(() {
        _availableEvents = available;
        _myEvents = myEvents;
      });
    } catch (e) {
      print('Erreur lors du chargement des événements: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinEvent(Map<String, dynamic> eventData) async {
    final eventId = eventData['id'] as int;
    final maxParticipants = eventData['max_participants'] as int;
    final currentCount = eventData['participant_count'] as int;

    if (currentCount >= maxParticipants) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cet événement est complet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await EventService.joinEvent(eventId, widget.userId);

    if (success) {
      await _loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription réussie ! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de s\'inscrire à cet événement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _leaveEvent(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se désinscrire ?'),
        content: Text(
          'Voulez-vous vous désinscrire de l\'événement "${event.name}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            child: const Text('Se désinscrire'),
          ),
        ],
      ),
    );

    if (confirmed == true && event.id != null) {
      final success = await EventService.leaveEvent(event.id!, widget.userId);

      if (success) {
        await _loadEvents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous êtes désinscrit de cet événement'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Événements'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Disponibles', icon: Icon(Icons.event_available)),
            Tab(text: 'Mes événements', icon: Icon(Icons.event_note)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableEventsTab(),
                _buildMyEventsTab(),
              ],
            ),
    );
  }

  Widget _buildAvailableEventsTab() {
    if (_availableEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucun événement disponible',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Les événements de vos salles favorites\napparaîtront ici',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableEvents.length,
        itemBuilder: (context, index) {
          final eventData = _availableEvents[index];
          final event = Event.fromMap(eventData);
          final gymName = eventData['gym_name'] as String;
          final participantCount = eventData['participant_count'] as int;
          final isJoined = (eventData['is_joined'] as int) > 0;
          final isFull = participantCount >= event.maxParticipants;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.teal[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.event,
                          color: Colors.teal[700],
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    gymName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isJoined)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  size: 16, color: Colors.green[700]),
                              const SizedBox(width: 4),
                              Text(
                                'Inscrit',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.timer,
                        label: '${event.duration} min',
                        color: Colors.blue,
                      ),
                      _InfoChip(
                        icon: Icons.people,
                        label: '$participantCount/${event.maxParticipants}',
                        color: isFull ? Colors.red : Colors.green,
                      ),
                      _InfoChip(
                        icon: Icons.emoji_events,
                        label: event.reward,
                        color: Colors.amber,
                      ),
                    ],
                  ),
                  if (event.eventDate != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            '${event.eventDate!.day}/${event.eventDate!.month}/${event.eventDate!.year} '
                            'à ${event.eventDate!.hour.toString().padLeft(2, '0')}:${event.eventDate!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isJoined
                          ? null
                          : (isFull ? null : () => _joinEvent(eventData)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isJoined
                            ? Colors.grey[400]
                            : (isFull ? Colors.grey[400] : Colors.teal[700]),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isJoined
                            ? 'Déjà inscrit'
                            : (isFull ? 'Complet' : 'Participer'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyEventsTab() {
    if (_myEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_note, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucune inscription',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inscrivez-vous aux événements\ndans l\'onglet "Disponibles"',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myEvents.length,
        itemBuilder: (context, index) {
          final event = _myEvents[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green[700],
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.timer,
                        label: '${event.duration} min',
                        color: Colors.blue,
                      ),
                      _InfoChip(
                        icon: Icons.emoji_events,
                        label: event.reward,
                        color: Colors.amber,
                      ),
                    ],
                  ),
                  if (event.eventDate != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            '${event.eventDate!.day}/${event.eventDate!.month}/${event.eventDate!.year} '
                            'à ${event.eventDate!.hour.toString().padLeft(2, '0')}:${event.eventDate!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _leaveEvent(event),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        side: BorderSide(color: Colors.red[700]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Se désinscrire',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final MaterialColor color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
