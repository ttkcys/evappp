import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:evapp/constants/app_color_constants.dart';
import 'package:evapp/features/main/drawer/event_page.dart';
import 'package:evapp/features/main/profile/profile_page.dart';
import 'package:evapp/features/auth/login_page.dart';
import 'package:evapp/features/main/drawer/pass_event_page.dart';

class RoutePage extends StatefulWidget {
  final int initialIndex;
  const RoutePage({super.key, this.initialIndex = 0});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  late PageController _pageController;
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _selectedIndex = widget.initialIndex;
    _fetchUserProfilePhoto();
  }

  void _fetchUserProfilePhoto() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        if (userDoc.exists && userDoc.data() != null) {
          var data = userDoc.data() as Map<String, dynamic>; 
          if (data.containsKey('profilePhoto')) {
            profilePhotoUrl = data['profilePhoto'];
          } else {
            profilePhotoUrl = null;
          }
        } else {
          profilePhotoUrl = null;
        }
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorConstants.white,
      appBar: AppBar(
        backgroundColor: AppColorConstants.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/logo/logo.png',
              width: 80,
            ),
            if (profilePhotoUrl != null)
              CircleAvatar(
                backgroundImage: NetworkImage(profilePhotoUrl!),
                radius: 20,
              ),
          ],
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: false,
      ),
      drawer: Drawer(
        backgroundColor: AppColorConstants.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: AppColorConstants.orange,
              ),
              child: Text(
                'EvApp',
                style: TextStyle(
                  color: AppColorConstants.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: AppColorConstants.orange),
              title: const Text('Profil'),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: AppColorConstants.orange),
              title: const Text('Katıldığım Etkinlikler'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PassEventPage()),
                );
              },
            ),
            ListTile(
              title: const Center(
                  child: Text(
                'Log Out',
                style: TextStyle(color: AppColorConstants.red),
              )),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: const [
          EventPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        elevation: 0,
        backgroundColor: AppColorConstants.white,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              color: _selectedIndex == 0 ? AppColorConstants.orange : AppColorConstants.grey,
            ),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              color: _selectedIndex == 1 ? AppColorConstants.orange : AppColorConstants.grey,
            ),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColorConstants.orange,
        unselectedItemColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }
}
