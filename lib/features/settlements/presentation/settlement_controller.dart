import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:denk/features/settlements/data/settlement_repository.dart';
import 'package:denk/features/settlements/domain/settlement_model.dart';

final settlementRepositoryProvider = Provider<SettlementRepository>((ref) {
  return FirestoreSettlementRepository();
});

final groupSettlementsStreamProvider =
    StreamProvider.family<List<SettlementRecord>, String>((ref, groupId) {
      final repo = ref.watch(settlementRepositoryProvider);
      return repo.watchGroupSettlements(groupId);
    });

class SettlementController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> recordSettlement(SettlementRecord settlement) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(settlementRepositoryProvider);
      await repo.recordSettlement(settlement);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteSettlement({
    required String groupId,
    required String settlementId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(settlementRepositoryProvider);
      await repo.deleteSettlement(groupId: groupId, settlementId: settlementId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final settlementControllerProvider =
    AsyncNotifierProvider<SettlementController, void>(SettlementController.new);
