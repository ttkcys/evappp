import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:evapp/constants/app_color_constants.dart';

class PassEventPage extends StatefulWidget {
  const PassEventPage({super.key});

  @override
  State<PassEventPage> createState() => _PassEventPageState();
}

class _PassEventPageState extends State<PassEventPage> {
  List<Map<String, dynamic>> joinedEvents = [];
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchJoinedEvents();
  }

  Future<void> _fetchJoinedEvents() async {
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
      final List<String> eventIds = List<String>.from(userDoc.data()?['joinedEvents'] ?? []);

      if (eventIds.isNotEmpty) {
        final eventsCollection = FirebaseFirestore.instance.collection('events');
        final querySnapshot = await eventsCollection.where(FieldPath.documentId, whereIn: eventIds).get();
        setState(() {
          joinedEvents = querySnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['location'] = '${data['city']}, ${data['district']}, ${data['neighborhood']}'; // Concatenate location fields
            return data;
          }).toList();
        });
      } else {
        setState(() {
          joinedEvents = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorConstants.white,
      appBar: AppBar(
        backgroundColor: AppColorConstants.white,
        title: const Text(
          'Katıldığım Etkinlikler',
          style: TextStyle(
            color: AppColorConstants.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: false,
      ),
      body: joinedEvents.isEmpty
          ? const Center(
              child: Text(
                'Henüz bir etkinliğe katılmadınız',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: joinedEvents.length,
              itemBuilder: (context, index) {
                final event = joinedEvents[index];
                final location = event['location']; // Use the concatenated location

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
                                event['profilePhoto'] ?? 'https://via.placeholder.com/150',
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
                              event['date'] ?? '',
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(event['eventName'] ?? ''),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tarih: ${event['date']}'),
                              Text('Yer: $location'), 
                              Text('Açıklama: ${event['explain']}'),
                            ],
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
