import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:evapp/constants/app_color_constants.dart';

class SettingsPage extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;
  final Function(String eventId, String userId) onRemoveParticipant;

  const SettingsPage(
      {super.key,
      required this.eventId,
      required this.eventData,
      required this.onRemoveParticipant});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _dateController = TextEditingController();
  final _explainController = TextEditingController();
  Map<String, String> participants = {};
  int _participantLimit = 0;

  @override
  void initState() {
    super.initState();
    _initializeEventData();
    _fetchParticipants();
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _neighborhoodController.dispose();
    _dateController.dispose();
    _explainController.dispose();
    super.dispose();
  }

  void _initializeEventData() {
    _eventNameController.text = widget.eventData['eventName'];
    _cityController.text = widget.eventData['city'] ?? '';
    _districtController.text = widget.eventData['district'] ?? '';
    _neighborhoodController.text = widget.eventData['neighborhood'] ?? '';
    _dateController.text = widget.eventData['date'];
    _explainController.text = widget.eventData['explain'];
    _participantLimit = widget.eventData['participantLimit'] ?? 0;
  }

  Future<void> _fetchParticipants() async {
    final eventDoc =
        FirebaseFirestore.instance.collection('events').doc(widget.eventId);
    final docSnapshot = await eventDoc.get();
    if (docSnapshot.exists) {
      final participantIds =
          List<String>.from(docSnapshot.data()?['participants'] ?? []);
      for (var participantId in participantIds) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(participantId)
            .get();
        if (userDoc.exists) {
          setState(() {
            participants[participantId] = userDoc.data()?['name'] ?? 'Unknown';
          });
        }
      }
    }
  }

  Future<void> _updateEvent() async {
    if (_formKey.currentState!.validate()) {
      final eventName = _eventNameController.text.trim();
      final city = _cityController.text.trim();
      final district = _districtController.text.trim();
      final neighborhood = _neighborhoodController.text.trim();
      final date = _dateController.text.trim();
      final explain = _explainController.text.trim();

      final eventDoc =
          FirebaseFirestore.instance.collection('events').doc(widget.eventId);
      await eventDoc.update({
        'eventName': eventName,
        'city': city,
        'district': district,
        'neighborhood': neighborhood,
        'date': date,
        'explain': explain,
        'participantLimit': _participantLimit,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event updated successfully!')),
      );
    }
  }

  Future<void> _deleteEvent() async {
    final eventDoc =
        FirebaseFirestore.instance.collection('events').doc(widget.eventId);
    await eventDoc.delete();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Başarılı!'),
          content: const Text('Etkinlik başarıyla silindi.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Pop the SettingsPage
              },
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeParticipant(String participantId) async {
    final eventDoc =
        FirebaseFirestore.instance.collection('events').doc(widget.eventId);
    await eventDoc.update({
      'participants': FieldValue.arrayRemove([participantId]),
    });

    setState(() {
      participants.remove(participantId);
    });

    widget.onRemoveParticipant(widget.eventId, participantId);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Başarılı!'),
          content: const Text('Katılımcı başarıyla kaldırıldı.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorConstants.white,
      appBar: AppBar(
        backgroundColor: AppColorConstants.white,
        title: const Text(
          'Ayarlar',
          style: TextStyle(
            color: AppColorConstants.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: AppColorConstants.red),
            onPressed: _deleteEvent,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _eventNameController,
                decoration: const InputDecoration(
                  labelText: 'Etkinlik Adı',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the event name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'İl',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the city';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _districtController,
                decoration: const InputDecoration(
                  labelText: 'İlçe',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the district';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _neighborhoodController,
                decoration: const InputDecoration(
                  labelText: 'Mahalle',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the neighborhood';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Tarih',
                  hintText: 'dd/mm/yyyy',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _explainController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Enter an explanation',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: _participantLimit,
                decoration: const InputDecoration(
                  labelText: 'Katılımcı Sayısı',
                ),
                items: List.generate(50, (index) => index + 1).map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _participantLimit = newValue!;
                  });
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _updateEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorConstants.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Güncelle',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Katılımcılar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final participantId = participants.keys.elementAt(index);
                  final participantName =
                      participants[participantId] ?? 'Unknown';
                  return ListTile(
                    title: Text(participantName),
                    trailing: IconButton(
                      icon:
                          const Icon(Icons.close, color: AppColorConstants.red),
                      onPressed: () {
                        _removeParticipant(participantId);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
