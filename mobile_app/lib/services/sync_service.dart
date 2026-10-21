import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/screening.dart';
import 'auth_service.dart';
import 'database_service.dart';

class SyncResult {
  final int syncedCount;
  final int failedCount;
  final String? errorMessage;

  SyncResult(
      {required this.syncedCount,
      required this.failedCount,
      this.errorMessage});
}

class SyncService {
  final FirebaseFirestore _firestore;
  final DatabaseService _dbService;

  SyncService({FirebaseFirestore? firestore, DatabaseService? dbService})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _dbService = dbService ?? DatabaseService.instance;

  /// Executes opportunistic background synchronization of unsynced local records to Cloud Firestore.
  Future<SyncResult> syncPendingRecords() async {
    List<Screening> pendingScreenings = [];
    try {
      pendingScreenings = await _dbService.getUnsyncedScreenings();
      if (pendingScreenings.isEmpty) {
        return SyncResult(syncedCount: 0, failedCount: 0);
      }

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        return SyncResult(
          syncedCount: 0,
          failedCount: pendingScreenings.length,
          errorMessage:
              'Sign in with a Firebase account to sync. Records remain saved on this device.',
        );
      }

      int syncedCount = 0;
      int failedCount = 0;
      String? firstError;
      final List<String> successfullySyncedIds = [];

      for (final screening in pendingScreenings) {
        try {
          final docMap = screening.toMap();
          docMap['uploaded_by'] = firebaseUser.uid;
          final worker = AuthService.instance.currentUser;
          if (worker != null && worker.id == firebaseUser.uid) {
            docMap['recorded_by_name'] = worker.name;
          }
          docMap['synced_at'] = FieldValue.serverTimestamp();

          await _firestore
              .collection('screenings')
              .doc(screening.screeningId)
              .set(docMap, SetOptions(merge: true));

          successfullySyncedIds.add(screening.screeningId);
          syncedCount++;
        } catch (error) {
          failedCount++;
          firstError ??= error.toString();
        }
      }

      if (successfullySyncedIds.isNotEmpty) {
        await _dbService.markAsSynced(successfullySyncedIds);
      }

      return SyncResult(
        syncedCount: syncedCount,
        failedCount: failedCount,
        errorMessage: firstError,
      );
    } catch (error) {
      return SyncResult(
        syncedCount: 0,
        failedCount: pendingScreenings.length,
        errorMessage: error.toString(),
      );
    }
  }
}
