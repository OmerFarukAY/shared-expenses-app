import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:denk/core/errors/app_exception.dart';
import 'package:denk/features/auth/domain/user_profile.dart';
import 'package:denk/features/groups/data/group_repository.dart';
import 'package:denk/features/groups/domain/group_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreGroupRepository repository;

  final creator = UserProfile(
    uid: 'user_omer',
    displayName: 'Ömer',
    preferredCurrency: 'TRY',
    languageCode: 'tr',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final friend = UserProfile(
    uid: 'user_ahmet',
    displayName: 'Ahmet',
    preferredCurrency: 'TRY',
    languageCode: 'tr',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = FirestoreGroupRepository(firestore: fakeFirestore);
  });

  group('FirestoreGroupRepository (Realtime & Invariants)', () {
    test(
      'createGroup creates group, owner member, user_group link, and invite doc',
      () async {
        final group = await repository.createGroup(
          name: 'Ankara Flat',
          description: 'Roommate shared expenses',
          defaultCurrency: 'TRY',
          creator: creator,
        );

        expect(group.name, 'Ankara Flat');
        expect(group.createdBy, 'user_omer');
        expect(group.memberCount, 1);
        expect(group.inviteCode.startsWith('DNK-'), isTrue);

        // Check group doc in Firestore
        final groupDoc = await fakeFirestore
            .collection('groups')
            .doc(group.id)
            .get();
        expect(groupDoc.exists, isTrue);
        expect(groupDoc.data()!['name'], 'Ankara Flat');

        // Check creator member record
        final memberDoc = await fakeFirestore
            .collection('groups')
            .doc(group.id)
            .collection('members')
            .doc(creator.uid)
            .get();
        expect(memberDoc.exists, isTrue);
        expect(memberDoc.data()!['role'], 'owner');
        expect(memberDoc.data()!['displayName'], 'Ömer');

        // Check user_group link
        final userGroupDoc = await fakeFirestore
            .collection('users')
            .doc(creator.uid)
            .collection('user_groups')
            .doc(group.id)
            .get();
        expect(userGroupDoc.exists, isTrue);

        // Check invite doc
        final inviteDoc = await fakeFirestore
            .collection('invites')
            .doc(group.inviteCode)
            .get();
        expect(inviteDoc.exists, isTrue);
        expect(inviteDoc.data()!['groupId'], group.id);
      },
    );

    test(
      'resolveInviteCode finds group by code and rejects invalid code',
      () async {
        final group = await repository.createGroup(
          name: 'Berlin Trip',
          defaultCurrency: 'EUR',
          creator: creator,
        );

        // Resolve with valid code
        final resolved = await repository.resolveInviteCode(group.inviteCode);
        expect(resolved.id, group.id);
        expect(resolved.name, 'Berlin Trip');

        // Resolve with lowercase or spaced input
        final lowerCode = group.inviteCode.toLowerCase().replaceAll('-', ' ');
        final resolvedLoose = await repository.resolveInviteCode(lowerCode);
        expect(resolvedLoose.id, group.id);

        // Non-existent code throws AppException
        expect(
          () => repository.resolveInviteCode('DNK-9999'),
          throwsA(isA<AppException>()),
        );
      },
    );

    test(
      'joinGroupWithInvite adds member and increments member count',
      () async {
        final group = await repository.createGroup(
          name: 'Family Home',
          defaultCurrency: 'TRY',
          creator: creator,
        );

        await repository.joinGroupWithInvite(
          inviteCode: group.inviteCode,
          user: friend,
        );

        final members = await repository.watchGroupMembers(group.id).first;
        expect(members.length, 2);
        expect(
          members.any((m) => m.uid == friend.uid && m.displayName == 'Ahmet'),
          isTrue,
        );

        final updatedGroup = await repository.getGroup(group.id);
        expect(updatedGroup!.memberCount, 2);
      },
    );

    test('leaveGroup removes member and decrements member count', () async {
      final group = await repository.createGroup(
        name: 'Study Group',
        defaultCurrency: 'USD',
        creator: creator,
      );

      await repository.joinGroupWithInvite(
        inviteCode: group.inviteCode,
        user: friend,
      );

      // Leave
      await repository.leaveGroup(groupId: group.id, uid: friend.uid);

      final members = await repository.watchGroupMembers(group.id).first;
      expect(members.length, 1);
      expect(members.any((m) => m.uid == friend.uid), isFalse);

      final updatedGroup = await repository.getGroup(group.id);
      expect(updatedGroup!.memberCount, 1);
    });

    test(
      'watchGroupMembers emits realtime updates when members join',
      () async {
        final group = await repository.createGroup(
          name: 'Realtime Group',
          defaultCurrency: 'TRY',
          creator: creator,
        );

        final stream = repository.watchGroupMembers(group.id);
        expect(
          stream,
          emitsInOrder([
            predicate<List<GroupMember>>((list) => list.length == 1),
            predicate<List<GroupMember>>((list) => list.length == 2),
          ]),
        );

        // Trigger realtime member addition
        await repository.joinGroupWithInvite(
          inviteCode: group.inviteCode,
          user: friend,
        );
      },
    );
  });
}
