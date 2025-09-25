import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/property_model.dart';
import '../properties/manage_properties_screen.dart';
import '../properties/add_property_screen.dart';
import '../properties/edit_property_screen.dart';
import '../properties/property_detail_screen.dart';
import '../profile/profile_screen.dart';

class LandlordLayout extends StatefulWidget {
  @override
  _LandlordLayoutState createState() => _LandlordLayoutState();
}

class _LandlordLayoutState extends State<LandlordLayout> {
  int _selectedIndex = 0;
  late UserModel _user;
  PropertyModel? _editingProperty;
  PropertyModel? _viewingProperty;
  final GlobalKey _managePropertiesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _user = authService.currentUserModel!;
  }

  Future<void> _logout() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      await auth.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {}
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: Color(0xFFF8F9FA),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'SmartStay Bukidnon',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
                SizedBox(height: 20),
                // User Profile Section
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Color(0xFF2196F3),
                      child: Text(
                        _user.name.isNotEmpty
                            ? _user.name[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                          Text(
                            _user.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Role Badge
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Landlord',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2196F3),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _selectedIndex = 1); // Profile
                      },
                      icon:
                          Icon(Icons.edit, size: 16, color: Color(0xFF2196F3)),
                      label: Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1),
          // Navigation Menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  icon: Icons.home_work,
                  title: 'Manage Properties',
                  index: 0,
                  isSelected: _selectedIndex == 0,
                ),
                _buildNavItem(
                  icon: Icons.person,
                  title: 'Profile',
                  index: 1,
                  isSelected: _selectedIndex == 1,
                ),
              ],
            ),
          ),
          Divider(height: 1),
          // Logout
          Container(
            padding: EdgeInsets.all(16),
            child: InkWell(
              onTap: _logout,
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required int index,
    required bool isSelected,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF2196F3) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Color(0xFF666666),
                size: 20,
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Color(0xFF333333),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return ManagePropertiesScreen(
          key: _managePropertiesKey,
          onEditProperty: (property) {
            setState(() {
              _editingProperty = property;
              _selectedIndex = 2; // Navigate to add/edit property screen
            });
          },
          onViewProperty: (property) {
            setState(() {
              _viewingProperty = property;
              _selectedIndex = 3; // Navigate to property detail screen
            });
          },
        );
      case 1:
        return ProfileScreen();
      case 2:
        // Check if we're adding new or editing existing
        if (_editingProperty == null || _editingProperty!.id.isEmpty) {
          // Adding new property
          return AddPropertyScreen(
            showAppBar: false, // Don't show AppBar when used in layout
            onSave: () async {
              setState(() {
                _editingProperty = null;
                _selectedIndex = 0; // Return to manage properties
              });
              // Refresh the property list
              if (_managePropertiesKey.currentState != null) {
                await (_managePropertiesKey.currentState! as dynamic)
                    .refreshData();
              }
            },
            onCancel: () {
              setState(() {
                _editingProperty = null;
                _selectedIndex = 0; // Return to manage properties
              });
            },
          );
        } else {
          // Editing existing property
          return EditPropertyScreen(
            property: _editingProperty!,
            showAppBar: false, // Don't show AppBar when used in layout
            onSave: () async {
              setState(() {
                _editingProperty = null;
                _selectedIndex = 0; // Return to manage properties
              });
              // Refresh the property list
              if (_managePropertiesKey.currentState != null) {
                await (_managePropertiesKey.currentState! as dynamic)
                    .refreshData();
              }
            },
            onCancel: () {
              setState(() {
                _editingProperty = null;
                _selectedIndex = 0; // Return to manage properties
              });
            },
          );
        }
      case 3:
        return PropertyDetailScreen(
          property: _viewingProperty!,
          onBack: () {
            setState(() {
              _viewingProperty = null;
              _selectedIndex = 0; // Return to manage properties
            });
          },
        );
      default:
        return ManagePropertiesScreen(
          onEditProperty: (property) {
            setState(() {
              _editingProperty = property;
              _selectedIndex = 2; // Navigate to add/edit property screen
            });
          },
          onViewProperty: (property) {
            setState(() {
              _viewingProperty = property;
              _selectedIndex = 3; // Navigate to property detail screen
            });
          },
        );
    }
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Color(0xFF2196F3),
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      _user.name.isNotEmpty ? _user.name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: Color(0xFF2196F3),
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    _user.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _user.email,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Landlord',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Navigation Items
          ListTile(
            leading: Icon(Icons.home_work, color: Color(0xFF2196F3)),
            title: Text('Manage Properties'),
            selected: _selectedIndex == 0,
            onTap: () {
              setState(() => _selectedIndex = 0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.person, color: Color(0xFF2196F3)),
            title: Text('Profile'),
            selected: _selectedIndex == 1,
            onTap: () {
              setState(() => _selectedIndex = 1);
              Navigator.pop(context);
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Color(0xFF2196F3),
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_work),
          label: 'Properties',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text('SmartStay Bukidnon'),
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
        ),
        drawer: _buildMobileDrawer(),
        body: _buildContent(),
        bottomNavigationBar: _buildBottomNav(),
      );
    } else {
      return Scaffold(
        body: Row(
          children: [
            _buildSidebar(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      );
    }
  }
}
