import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String location;

  UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? location,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'email': email, 'phone': phone, 'location': location};
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(json.decode(source));
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier()
    : super(UserProfile(name: 'Farmer', email: '', phone: '', location: '')) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Check if we have cached data and if it's fresh (< 24 hours old)
        final lastFetch = prefs.getInt('user_data_last_fetch') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        final cacheAge = now - lastFetch;
        final cacheValid = cacheAge < 86400000; // 24 hours in milliseconds

        // If cache is valid, use cached data
        if (cacheValid && prefs.containsKey('user_name')) {
          state = UserProfile(
            name: prefs.getString('user_name') ?? 'Farmer',
            email: prefs.getString('user_email') ?? '',
            phone: prefs.getString('user_phone') ?? '',
            location: prefs.getString('user_location') ?? '',
          );
          print(
            'Using cached user data (age: ${(cacheAge / 3600000).toStringAsFixed(1)} hours)',
          );
          return;
        }

        // Cache is stale or doesn't exist, fetch from Firestore
        try {
          print('Fetching user data from Firestore (cache expired or missing)');
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (doc.exists) {
            final data = doc.data()!;
            state = UserProfile(
              name: data['name'] ?? 'Farmer',
              email: data['email'] ?? '',
              phone: data['phone'] ?? '',
              location: data['location'] ?? '',
            );

            // Update cache with fresh data
            await prefs.setString('user_name', state.name);
            await prefs.setString('user_email', state.email);
            await prefs.setString('user_phone', state.phone);
            await prefs.setString('user_location', state.location);
            await prefs.setInt('user_data_last_fetch', now);
            print('User data cached successfully');
            return;
          }
        } catch (e) {
          print('Error fetching from Firestore: $e');
          // Fall through to use cached data if available
        }
      }

      // Fallback to SharedPreferences (if Firestore fetch failed)
      state = UserProfile(
        name: prefs.getString('user_name') ?? 'Farmer',
        email: prefs.getString('user_email') ?? '',
        phone: prefs.getString('user_phone') ?? '',
        location: prefs.getString('user_location') ?? '',
      );
    } catch (e) {
      print('Error loading profile: $e');
      // Fallback to default profile
      state = UserProfile(name: 'Farmer', email: '', phone: '', location: '');
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    try {
      // Update local state
      state = profile;

      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', profile.name);
      await prefs.setString('user_email', profile.email);
      await prefs.setString('user_phone', profile.phone);
      await prefs.setString('user_location', profile.location);

      // Update Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Updating Firestore for user: ${user.uid}');
        print('Profile data: ${profile.toMap()}');
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(profile.toMap(), SetOptions(merge: true));
          print('Firestore update successful');
        } catch (firestoreError) {
          print('FIRESTORE UPDATE ERROR: $firestoreError');
          print('Error type: ${firestoreError.runtimeType}');
          rethrow; // Re-throw to be caught by outer try-catch
        }
      } else {
        print('No current user - cannot update Firestore');
      }
    } catch (e) {
      print('Error in updateProfile: $e');
      // State is already updated, so UI will reflect changes even if sync fails
    }
  }

  Future<void> resetProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_phone');
    await prefs.remove('user_location');
    state = UserProfile(name: 'Farmer', email: '', phone: '', location: '');
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
      return UserProfileNotifier();
    });
