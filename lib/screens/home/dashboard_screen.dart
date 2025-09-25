import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../layouts/landlord_layout.dart';
import '../layouts/tenant_layout.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;

    if (user == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Redirect landlords directly to the property management layout
    if (user.role == UserRole.landlord) {
      return LandlordLayout();
    }

    // Redirect tenants to the tenant layout with sidebar
    return TenantLayout();
  }
}
