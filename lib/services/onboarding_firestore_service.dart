import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/onboarding_data.dart';

class OnboardingFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _onboardingCollection =>
      _firestore.collection('user_onboarding');

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Document reference for current user's onboarding data
  DocumentReference? get _userOnboardingDoc =>
      _userId != null ? _onboardingCollection.doc(_userId) : null;

  /// Upload onboarding data to Firestore
  Future<void> uploadOnboardingData(OnboardingData data) async {
    if (_userId == null) {
      throw Exception('User must be authenticated to upload onboarding data');
    }

    try {
      final docRef = _userOnboardingDoc!;
      final dataMap = data.toJson();

      // Add user ID and server timestamp
      dataMap['userId'] = _userId;
      dataMap['serverUpdatedAt'] = FieldValue.serverTimestamp();

      await docRef.set(dataMap, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to upload onboarding data: $e');
    }
  }

  /// Download onboarding data from Firestore
  Future<OnboardingData?> downloadOnboardingData() async {
    if (_userId == null) {
      throw Exception('User must be authenticated to download onboarding data');
    }

    try {
      final docRef = _userOnboardingDoc!;
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        return OnboardingData.fromJson(data);
      }

      return null; // No onboarding data found
    } catch (e) {
      throw Exception('Failed to download onboarding data: $e');
    }
  }

  /// Check if user has onboarding data in Firestore
  Future<bool> hasOnboardingData() async {
    if (_userId == null) return false;

    try {
      final docRef = _userOnboardingDoc!;
      final docSnapshot = await docRef.get();
      return docSnapshot.exists;
    } catch (e) {
      return false;
    }
  }

  /// Delete onboarding data from Firestore
  Future<void> deleteOnboardingData() async {
    if (_userId == null) {
      throw Exception('User must be authenticated to delete onboarding data');
    }

    try {
      final docRef = _userOnboardingDoc!;
      await docRef.delete();
    } catch (e) {
      throw Exception('Failed to delete onboarding data: $e');
    }
  }

  /// Update specific fields in onboarding data
  Future<void> updateOnboardingField(String field, dynamic value) async {
    if (_userId == null) {
      throw Exception('User must be authenticated to update onboarding data');
    }

    try {
      final docRef = _userOnboardingDoc!;
      final updateData = {
        field: value,
        'updatedAt': DateTime.now().toIso8601String(),
        'serverUpdatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.update(updateData);
    } catch (e) {
      throw Exception('Failed to update onboarding field: $e');
    }
  }

  /// Get onboarding data as a stream for real-time updates
  Stream<OnboardingData?> getOnboardingDataStream() {
    if (_userId == null) {
      return Stream.value(null);
    }

    return _userOnboardingDoc!.snapshots().map((docSnapshot) {
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        return OnboardingData.fromJson(data);
      }
      return null;
    });
  }

  /// Sync local onboarding data with cloud
  /// Returns true if cloud data was used, false if local data was uploaded
  Future<bool> syncOnboardingData(OnboardingData localData) async {
    if (_userId == null) return false;

    try {
      final cloudData = await downloadOnboardingData();

      if (cloudData != null) {
        // Cloud data exists, check which is more recent
        final cloudUpdated = cloudData.updatedAt;
        final localUpdated = localData.updatedAt;

        if (cloudUpdated.isAfter(localUpdated)) {
          // Cloud data is newer, return true to indicate cloud data should be used
          return true;
        } else {
          // Local data is newer or same, upload to cloud
          await uploadOnboardingData(localData);
          return false;
        }
      } else {
        // No cloud data, upload local data
        await uploadOnboardingData(localData);
        return false;
      }
    } catch (e) {
      // If sync fails, prefer local data
      return false;
    }
  }

  /// Mark onboarding as completed in Firestore
  Future<void> markOnboardingCompleted() async {
    await updateOnboardingField('isCompleted', true);
  }

  /// Get onboarding completion status
  Future<bool> isOnboardingCompleted() async {
    try {
      final data = await downloadOnboardingData();
      return data?.isCompleted ?? false;
    } catch (e) {
      return false;
    }
  }
}
