import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/groups/domain/invite_code_generator.dart';

void main() {
  group('GroupModel & GroupMember Domain Models', () {
    final now = DateTime(2026, 9, 27, 12, 0, 0);

    test('GroupMember toMap and fromMap conversion', () {
      final member = GroupMember(
        uid: 'user_1',
        displayName: 'Ömer',
        role: MemberRole.owner,
        joinedAt: now,
      );

      final map = member.toMap();
      expect(map['uid'], 'user_1');
      expect(map['displayName'], 'Ömer');
      expect(map['role'], 'owner');
      expect(map['joinedAt'], isA<Timestamp>());

      final restored = GroupMember.fromMap(map, 'user_1');
      expect(restored.uid, 'user_1');
      expect(restored.displayName, 'Ömer');
      expect(restored.role, MemberRole.owner);
      expect(restored.isOwner, isTrue);
    });

    test('GroupModel toMap and fromMap conversion', () {
      final group = GroupModel(
        id: 'group_abc',
        name: 'Ankara Flat',
        description: 'Monthly flat expenses',
        defaultCurrency: 'TRY',
        inviteCode: 'DNK-7X2K',
        createdBy: 'user_1',
        createdAt: now,
        updatedAt: now,
        memberCount: 3,
        active: true,
      );

      final map = group.toMap();
      expect(map['id'], 'group_abc');
      expect(map['name'], 'Ankara Flat');
      expect(map['defaultCurrency'], 'TRY');
      expect(map['inviteCode'], 'DNK-7X2K');
      expect(map['memberCount'], 3);

      final restored = GroupModel.fromMap(map, 'group_abc');
      expect(restored.id, 'group_abc');
      expect(restored.name, 'Ankara Flat');
      expect(restored.description, 'Monthly flat expenses');
      expect(restored.defaultCurrency, 'TRY');
      expect(restored.inviteCode, 'DNK-7X2K');
      expect(restored.memberCount, 3);
    });
  });

  group('InviteCodeGenerator', () {
    test(
      'generates valid unambiguous format with 6 characters (length 10)',
      () {
        for (int i = 0; i < 20; i++) {
          final code = InviteCodeGenerator.generate();
          expect(code.startsWith('DNK-'), isTrue);
          expect(code.length, 10);
          expect(InviteCodeGenerator.isValidFormat(code), isTrue);
          // Ensure no ambiguous characters
          expect(code.contains('0'), isFalse);
          expect(code.contains('O'), isFalse);
          expect(code.contains('1'), isFalse);
          expect(code.contains('I'), isFalse);
          expect(code.contains('L'), isFalse);
        }
      },
    );

    test('sanitizes user input correctly', () {
      expect(InviteCodeGenerator.sanitize('dnk-7x2k9p'), 'DNK-7X2K9P');
      expect(InviteCodeGenerator.sanitize('7x2k9p'), 'DNK-7X2K9P');
      expect(InviteCodeGenerator.sanitize('DNK 7X2K9P'), 'DNK-7X2K9P');
      expect(InviteCodeGenerator.sanitize('  7x2k9p  '), 'DNK-7X2K9P');
      // Legacy format sanitization
      expect(InviteCodeGenerator.sanitize('7x2k'), 'DNK-7X2K');
    });

    test(
      'validates format strictly (6-char high entropy and legacy 4-char)',
      () {
        // High-entropy 6-character codes
        expect(InviteCodeGenerator.isValidFormat('DNK-7X2K9P'), isTrue);
        expect(
          InviteCodeGenerator.isValidFormat('7X2K9P'),
          isTrue,
        ); // Auto-sanitizes

        // Legacy 4-character backward compatibility
        expect(InviteCodeGenerator.isValidFormat('DNK-7X2K'), isTrue);
        expect(
          InviteCodeGenerator.isValidFormat('7X2K'),
          isTrue,
        ); // Auto-sanitizes

        // Rejections
        expect(
          InviteCodeGenerator.isValidFormat('DNK-702K9P'),
          isFalse,
        ); // '0' is invalid
        expect(
          InviteCodeGenerator.isValidFormat('DNK-7I2K9P'),
          isFalse,
        ); // 'I' is invalid
        expect(
          InviteCodeGenerator.isValidFormat('DNK-7L2K9P'),
          isFalse,
        ); // 'L' is invalid
        expect(
          InviteCodeGenerator.isValidFormat('DNK-7O2K9P'),
          isFalse,
        ); // 'O' is invalid
        expect(
          InviteCodeGenerator.isValidFormat('INVALID_TOO_LONG_12345'),
          isFalse,
        );
        expect(
          InviteCodeGenerator.isValidFormat('DNK-2'),
          isFalse,
        ); // Too short
      },
    );
  });
}
