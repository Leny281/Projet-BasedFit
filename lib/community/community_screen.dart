import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/forum_model.dart';
import '../services/forum_service.dart';
import 'create_forum_screen.dart';
import 'forum_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final ForumService _forumService = ForumService();
  List<Forum> _forums = [];
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadForums();
    _checkAdminStatus();
  }

  Future<void> _loadForums() async {
    setState(() => _isLoading = true);
    
    try {
      final forums = await _forumService.getAllForums();
      setState(() {
        _forums = forums;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _forumService.isCurrentUserAdmin();
    setState(() => _isAdmin = isAdmin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _forums.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadForums,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _forums.length,
                    itemBuilder: (context, index) {
                      return _buildForumCard(_forums[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createForum,
        icon: const Icon(Icons.add),
        label: const Text('Créer un forum'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun forum pour le moment',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Soyez le premier à créer un forum !',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForumCard(Forum forum) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openForum(forum),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      forum.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_isAdmin)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteForum(forum),
                      tooltip: 'Supprimer (Admin)',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                forum.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    forum.createdByUserName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.message,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${forum.messageCount} messages',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(forum.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return 'Il y a ${diff.inMinutes} min';
      }
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays}j';
    } else {
      return DateFormat('dd/MM/yy').format(date);
    }
  }

  Future<void> _createForum() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateForumScreen(),
      ),
    );

    if (result == true) {
      _loadForums();
    }
  }

  Future<void> _openForum(Forum forum) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForumDetailScreen(forum: forum),
      ),
    );
    
    // Recharger pour mettre à jour le nombre de messages
    _loadForums();
  }

  Future<void> _deleteForum(Forum forum) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le forum'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le forum "${forum.title}" ?\n\n'
          'Tous les messages seront également supprimés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _forumService.deleteForum(forum.id!);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Forum supprimé'),
              backgroundColor: Colors.green,
            ),
          );
          _loadForums();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur: Permission refusée'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
