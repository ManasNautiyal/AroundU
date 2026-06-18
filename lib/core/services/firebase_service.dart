import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class FirebaseService {
  /// Initializes Firebase services.
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
  }
}
