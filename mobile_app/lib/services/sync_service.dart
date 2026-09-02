import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_service.dart';

class SyncResult {
  final int syncedCount;
  final int failedCount;
  final String? errorMessage;

  SyncResult({required this.syncedCount, required this.failedCount, this.errorMessage});
}

class SyncService {
  final FirebaseFirestore _firestore;
  final DatabaseService _dbService;

  SyncService({FirebaseFirestore? firestore, DatabaseService? dbService})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _dbService = dbService ?? DatabaseService.instance;

  /// Executes opportunistic background synchronization of unsynced local records to Cloud Firestore.
  Future<SyncResult> syncPendingRecords() async {
    try {
      final pendingScreenings = await _dbService.getUnsyncedScreenings();
      if (pendingScreenings.isEmpty) {
        return SyncResult(syncedCount: 0, failedCount: 0);
      }

      int syncedCount = 0;
      int failedCount = 0;
      final List<String> successfullySyncedIds = [];

      for (final screening in pendingScreenings) {
        try {
          final docMap = screening.toMap();
          docMap['synced_at'] = FieldValue.serverTimestamp();

          await _firestore
              .collection('screenings')
              .doc(screening.screeningId)
              .set(docMap, SetOptions(merge: true));

          successfullySyncedIds.add(screening.screeningId);
          syncedCount++;
        } catch (e) {
          failedCount++;
        }
      }

      if (successfullySyncedIds.isNotEmpty) {
        await _dbService.markAsSynced(successfullySyncedIds);
      }

      return SyncResult(
        syncedCount: syncedCount,
        failedCount: failedCount,
      );
    } catch (e) {
      return SyncResult(
        syncedCount: 0,
        failedCount: 0,
        errorMessage: e.toString(),
      );
    }
  }
}
