import 'package:flutter/material.dart';
import 'HomeScreen.dart';
import 'Bookings.dart';
import 'Profile.dart';
import 'ExplorePage.dart';

class ExploreScreen extends StatefulWidget {
  final Function(int)? onTabTapped;

  const ExploreScreen({Key? key, this.onTabTapped}) : super(key: key);

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  int _selectedIndex = 1;
  late PageController _pageController;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
    _pages = [
      HomeScreen(),
      ExplorePage(),
      Bookings(),
      ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });

    widget.onTabTapped?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _getTitle(_selectedIndex),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.yellow[600],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Explore"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Bookings"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return "Home";
      case 1:
        return "Explore";
      case 2:
        return "Bookings";
      case 3:
        return "Profile";
      default:
        return "Explore";
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}