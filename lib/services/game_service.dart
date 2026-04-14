import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GameService {
  static final _fn = FirebaseFunctions.instance;
  static final _fs = FirebaseFirestore.instance;

  static Future<String> createRoom(Map<String, dynamic> settings) async {
    final r = await _fn.httpsCallable('createRoom').call({'settings': settings});
    return r.data['code'] as String;
  }

  static Future<void> joinRoom(String code) =>
      _fn.httpsCallable('joinRoom').call({'code': code.toUpperCase()});

  static Future<void> startGame(String code) =>
      _fn.httpsCallable('startGame').call({'code': code});

  static Future<void> submitDrawing(String code, String dataURL) =>
      _fn.httpsCallable('submitDrawing').call({'code': code, 'dataURL': dataURL});

  static Future<void> submitVotes(String code, Map<String, int> ratings) =>
      _fn.httpsCallable('submitVotes').call({'code': code, 'ratings': ratings});

  static Future<void> updateSettings(String code, Map<String, dynamic> settings) =>
      _fs.doc('rooms/$code').update({'settings': settings});

  static Stream<DocumentSnapshot<Map<String, dynamic>>> roomStream(String code) =>
      _fs.doc('rooms/$code').snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> playersStream(String code) =>
      _fs.collection('rooms/$code/players').snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> drawingsStream(String code) =>
      _fs.collection('rooms/$code/drawings').snapshots();
}
