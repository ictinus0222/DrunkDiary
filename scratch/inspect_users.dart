import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  final snapshot = await FirebaseFirestore.instance.collection('users').get();
  print('Total Users: ${snapshot.docs.length}');
  for (var doc in snapshot.docs) {
    print('User: ${doc.id}');
    print('Data: ${doc.data()}');
  }
}
