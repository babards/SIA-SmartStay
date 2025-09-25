import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  // Initialize notifications
  Future<void> initialize() async {
    try {
      // Firebase Messaging is not supported on Windows/Linux desktop
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
        return;
      }
      await _messaging.requestPermission();
      String? token = await _messaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Notification init skipped: ${e.toString()}');
      }
    }
  }

  // Send weather alert notification
  Future<void> sendWeatherAlert(
      String userId, String message, Map<String, dynamic> weatherData) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'weather_alert',
        'title': 'Weather Alert',
        'message': message,
        'data': weatherData,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('Error sending weather alert: ${e.toString()}');
    }
  }

  // Get user notifications
  Future<void> getUserNotifications(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _notifications = snapshot.docs
          .map((doc) => NotificationModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      notifyListeners();
    } catch (e) {
      print('Error fetching notifications: ${e.toString()}');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: ${e.toString()}');
    }
  }
}
