import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class CreateEventScreen extends StatefulWidget {
  final int gymId;
  final Event? existingEvent; // Pour éditer un événement existant

  const CreateEventScreen({
    super.key,
    required this.gymId,
    this.existingEvent,
  });

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _rewardController = TextEditingController();
  bool _isLoading = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.existingEvent != null) {
      _nameController.text = widget.existingEvent!.name;
      _descriptionController.text = widget.existingEvent!.description;
      _durationController.text = widget.existingEvent!.duration.toString();
      _maxParticipantsController.text = widget.existingEvent!.maxParticipants.toString();
      _rewardController.text = widget.existingEvent!.reward;
      _selectedDate = widget.existingEvent!.eventDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _maxParticipantsController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final event = Event(
        id: widget.existingEvent?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        duration: int.parse(_durationController.text),
        maxParticipants: int.parse(_maxParticipantsController.text),
        reward: _rewardController.text.trim(),
        gymId: widget.gymId,
        createdAt: widget.existingEvent?.createdAt ?? DateTime.now(),
        eventDate: _selectedDate,
      );

      if (widget.existingEvent != null) {
        await EventService.updateEvent(event);
      } else {
        await EventService.createEvent(event);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingEvent != null
                ? 'Événement modifié avec succès !'
                : 'Événement créé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Retourner true pour indiquer le succès
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.existingEvent != null
            ? 'Modifier l\'événement'
            : 'Créer un événement'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
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
                        Icon(Icons.event, color: Colors.teal[700], size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Informations de l\'événement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom de l\'événement',
                        hintText: 'Ex: Challenge 30 jours',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer un nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'En quoi consiste cet événement ?',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer une description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            decoration: InputDecoration(
                              labelText: 'Durée (minutes)',
                              hintText: '60',
                              prefixIcon: const Icon(Icons.timer),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Durée requise';
                              }
                              final duration = int.tryParse(value);
                              if (duration == null || duration <= 0) {
                                return 'Durée invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _maxParticipantsController,
                            decoration: InputDecoration(
                              labelText: 'Max participants',
                              hintText: '20',
                              prefixIcon: const Icon(Icons.people),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nombre requis';
                              }
                              final max = int.tryParse(value);
                              if (max == null || max <= 0) {
                                return 'Nombre invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _rewardController,
                      decoration: InputDecoration(
                        labelText: 'Récompense',
                        hintText: 'Ex: Badge exclusif, Accès VIP...',
                        prefixIcon: const Icon(Icons.emoji_events),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer une récompense';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date de l\'événement (optionnel)',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} '
                                  'à ${_selectedDate!.hour.toString().padLeft(2, '0')}:${_selectedDate!.minute.toString().padLeft(2, '0')}'
                              : 'Aucune date sélectionnée',
                          style: TextStyle(
                            color: _selectedDate != null
                                ? Colors.black87
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.existingEvent != null
                          ? 'Modifier l\'événement'
                          : 'Créer l\'événement',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
