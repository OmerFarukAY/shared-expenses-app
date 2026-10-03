import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/groups/data/group_repository.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/groups/domain/join_request_model.dart';
import 'package:denk/features/expenses/domain/expense_model.dart';
import 'package:denk/features/expenses/presentation/expense_controller.dart';
import 'package:denk/features/settlements/domain/settlement_model.dart';
import 'package:denk/features/settlements/presentation/settlement_controller.dart';

/// Provider for the singleton [GroupRepository].
final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return FirestoreGroupRepository();
});

/// Stream provider for all groups the current user is a member of.
final userGroupsStreamProvider = StreamProvider<List<GroupModel>>((ref) {
  final userProfile = ref.watch(userProfileControllerProvider).value;
  if (userProfile == null) return const Stream.empty();

  final repository = ref.watch(groupRepositoryProvider);
  return repository.watchUserGroups(userProfile.uid);
});

class SelectedGroupIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;

  @override
  set state(String? val) => super.state = val;
}

/// Currently selected group ID in the app.
final selectedGroupIdProvider =
    NotifierProvider<SelectedGroupIdNotifier, String?>(
      SelectedGroupIdNotifier.new,
    );

/// Provider watching the currently selected [GroupModel].
final currentGroupProvider = Provider<GroupModel?>((ref) {
  final selectedId = ref.watch(selectedGroupIdProvider);
  if (selectedId == null) return null;

  final groupsAsync = ref.watch(userGroupsStreamProvider);
  return groupsAsync.value?.firstWhere(
    (g) => g.id == selectedId,
    orElse: () => groupsAsync.value!.first,
  );
});

/// Stream provider for members of a specific group.
final groupMembersStreamProvider =
    StreamProvider.family<List<GroupMember>, String>((ref, groupId) {
      final repository = ref.watch(groupRepositoryProvider);
      return repository.watchGroupMembers(groupId);
    });

/// Stream provider for pending join requests of a specific group (owner/admin view).
final groupJoinRequestsStreamProvider =
    StreamProvider.family<List<JoinRequestModel>, String>((ref, groupId) {
      final repository = ref.watch(groupRepositoryProvider);
      return repository.watchGroupJoinRequests(groupId);
    });

/// Stream provider for join requests created by the current user.
final userJoinRequestsStreamProvider = StreamProvider<List<JoinRequestModel>>((
  ref,
) {
  final userProfile = ref.watch(userProfileControllerProvider).value;
  if (userProfile == null) return const Stream.empty();

  final repository = ref.watch(groupRepositoryProvider);
  return repository.watchUserJoinRequests(userProfile.uid);
});

/// Immutable data container holding synchronized state for a group's dashboard.
class GroupDashboardData {
  final List<GroupMember> members;
  final List<ExpenseModel> expenses;
  final List<SettlementRecord> settlements;

  const GroupDashboardData({
    required this.members,
    required this.expenses,
    required this.settlements,
  });
}

/// Unified provider combining members, expenses, and settlements into a single
/// coherent state. Eliminates staggered rendering flickers and stale state lag
/// during page transitions and background stream reloads.
final groupDashboardDataProvider =
    Provider.family<AsyncValue<GroupDashboardData>, String>((ref, groupId) {
  final membersAsync = ref.watch(groupMembersStreamProvider(groupId));
  final expensesAsync = ref.watch(groupExpensesStreamProvider(groupId));
  final settlementsAsync = ref.watch(groupSettlementsStreamProvider(groupId));

  if (membersAsync.hasError) {
    return AsyncValue.error(membersAsync.error!, membersAsync.stackTrace!);
  }
  if (expensesAsync.hasError) {
    return AsyncValue.error(expensesAsync.error!, expensesAsync.stackTrace!);
  }
  if (settlementsAsync.hasError) {
    return AsyncValue.error(settlementsAsync.error!, settlementsAsync.stackTrace!);
  }

  if (membersAsync.hasValue && expensesAsync.hasValue && settlementsAsync.hasValue) {
    return AsyncValue.data(
      GroupDashboardData(
        members: membersAsync.value!,
        expenses: expensesAsync.value!,
        settlements: settlementsAsync.value!,
      ),
    );
  }

  return const AsyncValue.loading();
});

