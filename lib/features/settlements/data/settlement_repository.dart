import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:denk/core/errors/app_exception.dart';
import 'package:denk/features/settlements/domain/settlement_model.dart';

abstract class SettlementRepository {
  Stream<List<SettlementRecord>> watchGroupSettlements(String groupId);
  Future<void> recordSettlement(SettlementRecord settlement);
  Future<void> deleteSettlement({
    required String groupId,
    required String settlementId,
  });
}

class FirestoreSettlementRepository implements SettlementRepository {
  final FirebaseFirestore _firestore;

  FirestoreSettlementRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _settlementsCol(String groupId) =>
      _firestore.collection('groups').doc(groupId).collection('settlements');

  @override
  Stream<List<SettlementRecord>> watchGroupSettlements(String groupId) {
    return _settlementsCol(
      groupId,
    ).orderBy('settledAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return SettlementRecord.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  @override
  Future<void> recordSettlement(SettlementRecord settlement) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _settlementsCol(settlement.groupId).doc(settlement.id);
        final docSnap = await transaction.get(docRef);

        if (docSnap.exists) {
          // Idempotent guard: A settlement with this deterministic ID has already
          // been recorded (e.g. from a concurrent tap or another member's device).
          // Safely no-op without writing a duplicate document or reversing balances.
          return;
        }

        transaction.set(docRef, settlement.toMap());
      });
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        message: 'Failed to record settlement: $e',
        code: 'settlement-record-failed',
      );
    }
  }

  @override
  Future<void> deleteSettlement({
    required String groupId,
    required String settlementId,
  }) async {
    try {
      await _settlementsCol(groupId).doc(settlementId).delete();
    } catch (e) {
      throw AppException(
        message: 'Failed to delete settlement: $e',
        code: 'settlement-delete-failed',
      );
    }
  }
}
