import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evapp/features/main/route/route_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:evapp/constants/app_color_constants.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ShareEventPage extends StatefulWidget {
  const ShareEventPage({super.key});

  @override
  State<ShareEventPage> createState() => _ShareEventPageState();
}

class _ShareEventPageState extends State<ShareEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _dateController = TextEditingController();
  final _explainController = TextEditingController();
  int _participantLimit = 1;

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

  Future<void> _shareEvent() async {
    if (_formKey.currentState!.validate()) {
      final eventName = _eventNameController.text.trim();
      final city = _cityController.text.trim();
      final district = _districtController.text.trim();
      final neighborhood = _neighborhoodController.text.trim();
      final date = _dateController.text.trim();
      final explain = _explainController.text.trim();
      final creationDate = DateTime.now();

      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final userName = userDoc['name'];
        final userEmail = userDoc['email'];
        final profilePhoto = userDoc['profilePhoto'];

        final eventsCollection =
            FirebaseFirestore.instance.collection('events');
        final eventDoc = eventsCollection.doc();

        await eventDoc.set({
          'id': eventDoc.id,
          'eventName': eventName,
          'city': city,
          'district': district,
          'neighborhood': neighborhood,
          'date': date,
          'explain': explain,
          'userName': userName,
          'userEmail': userEmail,
          'profilePhoto': profilePhoto,
          'userId': user.uid,
          'participants': [],
          'participantLimit': _participantLimit,
          'creationDate': creationDate,
        });

        _showSuccessDialog();
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Başarılı!'),
          content: const Text('Etkinlik başarıyla paylaşıldı.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const RoutePage(initialIndex: 0)),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('OK'),
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
          'Etkinlik Paylaş',
          style: TextStyle(
              color: AppColorConstants.orange, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _eventNameController,
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    labelText: 'Etkinlik Adı',
                    border: OutlineInputBorder(),
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
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    labelText: 'İl',
                    border: OutlineInputBorder(),
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
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    labelText: 'İlçe',
                    border: OutlineInputBorder(),
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
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    labelText: 'Mahalle',
                    border: OutlineInputBorder(),
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
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    labelText: 'Tarih',
                    hintText: 'dd/mm/yyyy',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the date';
                    }
                    return null;
                  },
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    await _selectDate(context);
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  maxLines: 5,
                  controller: _explainController,
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    labelText: 'Açıklama',
                    hintText: 'Açıklama giriniz',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: _participantLimit,
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    labelText: 'Katılımcı Sayısı',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      List.generate(50, (index) => index + 1).map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _participantLimit = newValue ?? 1;
                    });
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _shareEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Etkinliği Paylaş',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
