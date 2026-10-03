import 'package:flutter/widgets.dart';
import 'package:denk/core/errors/app_exception.dart';
import 'package:denk/l10n/l10n.dart';

/// Extension to resolve localized, user-friendly error messages from any error object.
extension LocalizedErrorX on BuildContext {
  String localizedErrorMessage(Object? error) {
    final l10n = AppLocalizations.of(this);
    if (l10n == null) return error?.toString() ?? 'Error';

    if (error == null) return l10n.commonError;

    if (error is AppException) {
      switch (error.code) {
        case 'permission-denied':
          return l10n.errorPermissionDenied;
        case 'network-unavailable':
          return l10n.errorNetworkUnavailable;
        case 'not-found':
          return l10n.errorNotFound;
        case 'invalid-name':
          if (error.message.toLowerCase().contains('group')) {
            return l10n.errorGroupNameLength;
          }
          return l10n.displayNameValidation;
        case 'invalid-code-format':
          return l10n.errorInvalidCodeFormat;
        case 'invite-not-found':
        case 'invite-inactive':
          return l10n.invalidOrInactiveInvite;
        case 'already-member':
          return l10n.alreadyMemberError;
        case 'request-already-pending':
        case 'pending-request-exists':
          return l10n.requestAlreadyPendingError;
        case 'rejection-limit-reached':
          return l10n.joinRequestLimitReached;
        case 'invalid-percentage-sum':
          return l10n.errorInvalidPercentageSum;
        case 'invalid-amount':
          return l10n.errorEnterValidAmount;
        case 'no-payers':
          return l10n.errorSelectPayer;
        case 'negative-payer-amount':
        case 'negative-split-amount':
          return l10n.errorNegativeAmount;
        case 'payer-sum-mismatch':
          return l10n.errorPayerMismatchGeneric;
        case 'no-participants':
          return l10n.errorSelectParticipant;
        case 'split-sum-mismatch':
          return l10n.errorSplitMismatchGeneric;
        case 'apple-account-required':
          return l10n.appleAccountRequired;
        case 'requires-recent-login':
          return l10n.deleteAccountReauthRequired;
        case 'ownership-transfer-required':
          return l10n.deleteAccountOwnershipRequired;
        case 'credential-already-in-use':
          return l10n.accountAlreadyInUseTitle;
        case 'provider-already-linked':
        case 'operation-not-allowed':
        case 'auth-failed':
        case 'sign-in-failed':
          return l10n.accountLinkErrorGeneric;
        case 'settlement-record-failed':
          return l10n.errorSettlementRecordFailed;
        case 'settlement-delete-failed':
          return l10n.errorSettlementDeleteFailed;
        case 'cannot-remove-balance':
          return l10n.cannotRemoveMemberBalance;
        case 'cannot-leave-balance':
          return l10n.cannotLeaveGroupBalance;
      }
    }

    final msg = error.toString().toLowerCase();
    if (msg.contains('permission-denied') || msg.contains('permission denied')) {
      return l10n.errorPermissionDenied;
    }
    if (msg.contains('network') ||
        msg.contains('unavailable') ||
        msg.contains('socketexception') ||
        msg.contains('connection failed')) {
      return l10n.errorNetworkUnavailable;
    }
    if (msg.contains('not found') || msg.contains('not-found')) {
      return l10n.errorNotFound;
    }
    if (msg.contains('valid amount')) {
      return l10n.errorEnterValidAmount;
    }
    if (msg.contains('what the expense was for') || msg.contains('expense title')) {
      return l10n.errorEnterExpenseTitle;
    }
    if (msg.contains('at least one participant must be selected')) {
      return l10n.errorSelectParticipant;
    }
    if (msg.contains('who paid')) {
      return l10n.errorSelectPayer;
    }
    if (msg.contains('positive') || msg.contains('greater than zero')) {
      return l10n.errorNegativeAmount;
    }
    if (msg.contains('too many payers')) {
      return l10n.errorTooManyPayers;
    }
    if (msg.contains('too many participants')) {
      return l10n.errorTooManyParticipants;
    }
    if (msg.contains('share > 0') || msg.contains('share > zero')) {
      return l10n.errorAtLeastOneParticipantShare;
    }
    if (msg.contains('equal 100%')) {
      return l10n.errorInvalidPercentageSum;
    }
    if (msg.contains('group name must be between') || msg.contains('1 and 60 characters')) {
      return l10n.errorGroupNameLength;
    }
    if (msg.contains('name between 2 and') || msg.contains('display name must be')) {
      return l10n.displayNameValidation;
    }
    if (msg.contains('already a member')) {
      return l10n.alreadyMemberError;
    }
    if (msg.contains('pending') && msg.contains('request')) {
      return l10n.requestAlreadyPendingError;
    }
    if (msg.contains('katılma sınır') || msg.contains('limit reached') || msg.contains('rejection-limit-reached')) {
      return l10n.joinRequestLimitReached;
    }
    if (msg.contains('invite code not found') || msg.contains('invalid or inactive invite')) {
      return l10n.invalidOrInactiveInvite;
    }
    if (msg.contains('payer contributions') || msg.contains('total paid does not match')) {
      return l10n.errorPayerMismatchGeneric;
    }
    if (msg.contains('allocated splits') || msg.contains('sum of splits does not match')) {
      return l10n.errorSplitMismatchGeneric;
    }
    if (msg.contains('apple account')) {
      return l10n.appleAccountRequired;
    }
    if (msg.contains('ownership transfer required')) {
      return l10n.deleteAccountOwnershipRequired;
    }
    if (msg.contains('cannot be removed before their balance')) {
      return l10n.cannotRemoveMemberBalance;
    }
    if (msg.contains('cannot leave the group before your balance')) {
      return l10n.cannotLeaveGroupBalance;
    }
    if (msg.contains('link account') || msg.contains('linking failed')) {
      return l10n.accountLinkErrorGeneric;
    }
    if (msg.contains('settlement') && msg.contains('record')) {
      return l10n.errorSettlementRecordFailed;
    }
    if (msg.contains('settlement') && msg.contains('delete')) {
      return l10n.errorSettlementDeleteFailed;
    }

    return l10n.commonError;
  }
}
