import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evapp/features/main/settings/settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:evapp/constants/app_color_constants.dart';
import 'package:flutter/services.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> filteredEvents = [];
  List<String> joinedEvents = [];
  final TextEditingController _searchController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _fetchJoinedEvents();
    _searchController.addListener(_filterEvents);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterEvents);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchEvents() async {
  final eventsCollection = FirebaseFirestore.instance.collection('events');
  final querySnapshot = await eventsCollection.get();
  if (mounted) {
    setState(() {
      events = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; 
        return data;
      }).toList();
      filteredEvents = events;
    });
  }
}

Future<void> _fetchJoinedEvents() async {
  if (currentUser != null) {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    if (mounted) {
      setState(() {
        joinedEvents = List<String>.from(userDoc.data()?['joinedEvents'] ?? []);
      });
    }
  }
}


  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredEvents = events.where((event) {
        final eventName = event['eventName']?.toLowerCase() ?? '';
        final userName = event['userName']?.toLowerCase() ?? '';
        final location = event['location']?.toLowerCase() ?? '';
        return eventName.contains(query) ||
            userName.contains(query) ||
            location.contains(query);
      }).toList();
    });
  }

void _joinEvent(String eventId) async {
  final eventDoc = await FirebaseFirestore.instance.collection('events').doc(eventId).get();
  final event = eventDoc.data();
  final participants = List<String>.from(event?['participants'] ?? []);
  final participantLimit = event?['participantLimit'] ?? 0;

  if (participants.length < participantLimit) {
    if (currentUser != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
      await userDoc.update({
        'joinedEvents': FieldValue.arrayUnion([eventId]),
      });
      await eventDoc.reference.update({
        'participants': FieldValue.arrayUnion([currentUser!.uid]),
      });

    

      if (mounted) {
        setState(() {
          joinedEvents.add(eventId);
        });
      }
    }
  } else {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Katılımcı Sınırına Ulaşıldı'),
            content: const Text('Bu etkinliğe katılımcı sınırına ulaşıldı.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Tamam'),
              ),
            ],
          );
        },
      );
    }
  }
}

 void _leaveEvent(String eventId) async {
  if (currentUser != null) {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
    await userDoc.update({
      'joinedEvents': FieldValue.arrayRemove([eventId]),
    });
    await FirebaseFirestore.instance.collection('events').doc(eventId).update({
      'participants': FieldValue.arrayRemove([currentUser!.uid]),
    });
    if (mounted) {
      setState(() {
        joinedEvents.remove(eventId);
      });
    }
  }
}

  void _copyLocation(String location) {
    Clipboard.setData(ClipboardData(text: location));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorConstants.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextFormField(
              controller: _searchController,
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                hintText: 'Etkinlik ara',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                final event = filteredEvents[index];
                final isJoined = joinedEvents.contains(event['id']);
                final isOwner = event['userId'] == currentUser?.uid;
                final creationDate =
                    (event['creationDate'] as Timestamp).toDate();

                final location = '${event['city']}, ${event['district']}, ${event['neighborhood']}';

                return Card(
                  margin: const EdgeInsets.all(10.0),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(
                                event['profilePhoto'] ??
                                    'https://via.placeholder.com/150',
                              ),
                              radius: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                event['userName'] ?? 'Etkinlik açan kişi',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${creationDate.day}/${creationDate.month}/${creationDate.year}', 
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(event['eventName'] ?? ''),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Tarih: ${event['date']}'),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text('Yer: $location'),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy),
                                          onPressed: () {
                                            _copyLocation(location);
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Açıklama: ${event['explain']}'),
                                  ],
                                ),
                              ),
                            ),
                            isOwner
                                ? TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SettingsPage(
                                            eventId: event['id'],
                                            eventData: event,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('Ayarlar'),
                                  )
                                : TextButton(
                                    onPressed: () {
                                      if (isJoined) {
                                        _leaveEvent(event['id']);
                                      } else {
                                        _joinEvent(event['id']);
                                      }
                                    },
                                    child:
                                        Text(isJoined ? 'Katıldın' : 'Katıl'),
                                  ),
                          ],
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
    );
  }
}
