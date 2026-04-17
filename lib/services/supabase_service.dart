import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/prediction_model.dart';
import '../models/schedule_model.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String surname,
    required String dob,
    required String gender,
    required String profession,
    required String region,
    required String phone,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
        'surname': surname,
      },
    );

    if (response.user != null) {
      await _client.from('profiles').insert({
        'id': response.user!.id,
        'first_name': firstName,
        'surname': surname,
        'dob': dob,
        'gender': gender,
        'profession': profession,
        'region': region,
        'phone_number': phone,
      });
    }
    return response;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> saveScan(Prediction scan, File imageFile) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$userId/$fileName';

    try {
      await _client.storage.from('leaf_scans').upload(path, imageFile);
      final imageUrl = _client.storage.from('leaf_scans').getPublicUrl(path);

      await _client.from('scan_history').insert({
        'user_id': userId,
        'disease_name': scan.diseaseName,
        'confidence': scan.confidence,
        'description': scan.description,
        'treatment': scan.treatment,
        'image_url': imageUrl,
        'is_leaf': scan.isLeaf,
      });
    } catch (e) {
      print('Supabase Save Scan Error: $e');
    }
  }

  Future<List<Prediction>> fetchScans() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('scan_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((e) {
        return Prediction(
          diseaseName: e['disease_name'],
          confidence: (e['confidence'] as num).toDouble(),
          description: e['description'],
          treatment: e['treatment'],
          imagePath: e['image_url'], 
          dateTime: DateTime.parse(e['created_at']),
          isAsset: false,
          isLeaf: e['is_leaf'] ?? true,
          isNetwork: true,
        );
      }).toList();
    } catch (e) {
      print('Fetch scans error: $e');
      return [];
    }
  }

  Future<void> deleteScan(String imageUrl) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    try {
      await _client.from('scan_history').delete().eq('image_url', imageUrl);
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;
      final path = '$userId/$fileName';
      await _client.storage.from('leaf_scans').remove([path]);
    } catch (e) {
      print('Supabase Delete Scan Error: $e');
    }
  }

  Future<String?> addSchedule(Schedule schedule) async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client.from('schedules').insert({
        'user_id': userId,
        'activity': schedule.activity,
        'date_time': schedule.dateTime.toIso8601String(),
        'is_completed': schedule.isCompleted,
      }).select('id').single();
      
      return response['id'].toString();
    } catch (e) {
      print('Supabase Add Schedule Error: $e');
      return null;
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    try {
      dynamic idToMatch = int.tryParse(scheduleId) ?? scheduleId;
      await _client.from('schedules').delete().eq('id', idToMatch).eq('user_id', userId);
    } catch (e) {
      print('Supabase Delete Schedule Error: $e');
    }
  }

  Future<List<Schedule>> fetchSchedules() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('schedules')
          .select()
          .eq('user_id', userId)
          .order('date_time', ascending: true);

      return (response as List).map((e) => Schedule.fromMap({
        'id': e['id'].toString(),
        'activity': e['activity'],
        'dateTime': e['date_time'],
        'isCompleted': e['is_completed'],
      })).toList();
    } catch (e) {
      print('Supabase Fetch Schedules Error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final response = await _client.from('profiles').select().eq('id', userId).single();
    return response as Map<String, dynamic>;
  }

  Future<void> updateUserProfile({
    required String firstName,
    required String surname,
    required String profession,
    required String region,
    required String phone,
    String? dob,
    String? gender,
    String? avatarUrl,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client.from('profiles').update({
      'first_name': firstName,
      'surname': surname,
      'profession': profession,
      'region': region,
      'phone_number': phone,
      if (dob != null) 'dob': dob,
      if (gender != null) 'gender': gender,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    }).eq('id', userId);
  }

  Future<String?> uploadAvatar(File imageFile) async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$userId/$fileName';

    try {
      await _client.storage.from('avatars').upload(path, imageFile);
      return _client.storage.from('avatars').getPublicUrl(path);
    } catch (e) {
      print('Supabase Avatar Upload Error: $e');
      return null;
    }
  }

  Future<String> askGemini(String prompt) async {
    try {
      final response = await _client.functions.invoke(
        'cabbage-doctor',
        body: {
          'prompt': prompt,
          'content': prompt,
          'message': prompt,
        },
      );
      
      if (response.status == 200) {
        if (response.data is Map) {
          final data = response.data as Map;
          return data['reply']?.toString() ?? 
                 data['message']?.toString() ?? 
                 data['text']?.toString() ?? 
                 data['content']?.toString() ??
                 data.toString();
        }
        return response.data.toString();
      } else {
        if (response.data is Map && response.data['error'] != null) {
          return 'AI Error: ${response.data['error']}';
        }
        return 'Error ${response.status}: ${response.data}';
      }
    } on FunctionException catch (e) {
      return 'Function Error: ${e.status} - ${e.details}';
    } catch (e) {
      return 'AI unreachable: $e';
    }
  }
}
