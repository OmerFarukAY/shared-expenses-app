// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Denk';

  @override
  String get appTagline => 'Dépenses partagées, comptes sereins';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonEdit => 'Modifier';

  @override
  String get commonDone => 'Terminé';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonNext => 'Suivant';

  @override
  String get commonConfirm => 'Confirmer';

  @override
  String get commonError => 'Une erreur est survenue';

  @override
  String get commonLoading => 'Chargement...';

  @override
  String get navGroups => 'Groupes';

  @override
  String get navActivity => 'Activité';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get welcomeTitle => 'Bienvenue sur Denk';

  @override
  String get welcomeSubtitle =>
      'Gérez vos dépenses partagées entre colocataires, amis ou famille sans mot de passe ni données superflues.';

  @override
  String get chooseDisplayName => 'Choisissez votre nom affiché';

  @override
  String get youLabel => 'Vous';

  @override
  String get displayNameHint => 'Ex. Thomas, Camille, Julien';

  @override
  String get displayNameValidation =>
      'Veuillez saisir un nom entre 2 et 50 caractères';

  @override
  String get getStarted => 'Commencer';

  @override
  String get createGroup => 'Créer un groupe';

  @override
  String get joinGroup => 'Rejoindre un groupe';

  @override
  String get groupNameLabel => 'Nom du groupe';

  @override
  String get groupNameHint => 'Ex. Coloc Paris, Voyage à Rome, Dîner';

  @override
  String get groupCurrencyLabel => 'Devise';

  @override
  String get inviteCodeLabel => 'Code d\'invitation';

  @override
  String get inviteCodeHint => 'Ex. DNK-7X2K';

  @override
  String get joinButton => 'Rejoindre';

  @override
  String get copyInviteCode => 'Copier le code';

  @override
  String get inviteCodeCopied => 'Code copié dans le presse-papiers';

  @override
  String get noGroupsTitle => 'Aucun groupe pour l\'instant';

  @override
  String get noGroupsSubtitle =>
      'Créez un groupe ou rejoignez-en un via un code pour commencer.';

  @override
  String get expensesTab => 'Dépenses';

  @override
  String get balancesTab => 'Soldes';

  @override
  String get settleTab => 'Équilibrer';

  @override
  String get addExpense => 'Ajouter une dépense';

  @override
  String get expenseAmount => 'Montant';

  @override
  String get expenseTitle => 'De quoi s\'agissait-il ?';

  @override
  String get expenseTitleHint => 'Ex. Courses, Dîner, Électricité';

  @override
  String get expenseCategory => 'Catégorie';

  @override
  String get expenseDate => 'Date';

  @override
  String get expensePaidBy => 'Qui a payé ?';

  @override
  String get expenseSplitWith => 'Qui a participé ?';

  @override
  String get expenseSplitMethod => 'Mode de répartition';

  @override
  String get splitEqual => 'À parts égales';

  @override
  String get splitCustom => 'Montants exacts';

  @override
  String get splitPercentage => 'Par pourcentage';

  @override
  String get categoryFood => 'Restaurants & Sorties';

  @override
  String get categoryGroceries => 'Courses';

  @override
  String get categoryTransport => 'Transports';

  @override
  String get categoryHome => 'Logement & Loyer';

  @override
  String get categoryEntertainment => 'Loisirs';

  @override
  String get categoryTravel => 'Voyages';

  @override
  String get categoryBills => 'Factures';

  @override
  String get categoryShopping => 'Achats';

  @override
  String get categoryOther => 'Autre';

  @override
  String get totalSpending => 'Dépenses totales';

  @override
  String get yourBalance => 'Votre solde';

  @override
  String get youAreOwed => 'On vous doit';

  @override
  String get youOwe => 'Vous devez';

  @override
  String get youPaid => 'Vous avez payé';

  @override
  String get allSettled => 'Tout est équilibré';

  @override
  String get noExpensesTitle => 'Aucune dépense pour l\'instant';

  @override
  String get noExpensesSubtitle =>
      'Appuyez sur le bouton ci-dessous pour ajouter votre première dépense.';

  @override
  String get settlementTitle => 'Plan de remboursement';

  @override
  String get markAsSettled => 'Marquer comme remboursé';

  @override
  String get settlementCompleted => 'Remboursement enregistré';

  @override
  String get settlementHistory => 'Historique des remboursements';

  @override
  String get noSettlementsNeeded =>
      'Les comptes sont parfaitement équilibrés !';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsProfile => 'Profil';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsCurrency => 'Devise préférée';

  @override
  String get settingsPrivacy => 'Confidentialité et données';

  @override
  String get settingsPrivacyInfo => 'Informations de confidentialité';

  @override
  String get settingsDeleteAccount => 'Supprimer le compte local';

  @override
  String get settingsDeleteWarning =>
      'Cette action supprime votre identité locale sur cet appareil. Vous perdrez l\'accès à vos groupes sauf nouvelle invitation.';

  @override
  String get settingsAbout => 'À propos de Denk';

  @override
  String get settingsVersion => 'Version';

  @override
  String get expenseDetailTitle => 'Détails de la dépense';

  @override
  String get deleteExpenseConfirmTitle => 'Supprimer la dépense';

  @override
  String get deleteExpenseConfirmMessage =>
      'Êtes-vous sûr de vouloir supprimer cette dépense ? Tous les soldes seront recalculés.';

  @override
  String get paidBy => 'Payé par';

  @override
  String get splitBetween => 'Partagé entre';

  @override
  String get expenseNotes => 'Remarques';

  @override
  String get searchHint => 'Rechercher des dépenses...';

  @override
  String get filterAll => 'Tous';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get noMatchingExpenses => 'Aucune dépense correspondante';

  @override
  String get tryClearingSearchFilter =>
      'Essayez d\'effacer vos options de recherche ou de filtre.';

  @override
  String get spendingInsights => 'Aperçu des dépenses';

  @override
  String get spendingByCategory => 'Dépenses par catégorie';

  @override
  String get memberContributions => 'Contributions des membres';

  @override
  String get settingsPreferences => 'Préférences';

  @override
  String get themeTitle => 'Thème';

  @override
  String get themeSystem => 'Système par défaut';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get anonymousAccount => 'Compte anonyme Firebase';

  @override
  String get copyId => 'Copier l\'identifiant';

  @override
  String get membersLabel => 'membres';

  @override
  String get requestToJoinButton => 'Demander à rejoindre';

  @override
  String get joinRequestSentTitle => 'Demande envoyée';

  @override
  String joinRequestSentSubtitle(String groupName) {
    return 'Votre demande pour rejoindre $groupName a été envoyée. Vous pourrez accéder au groupe dès que le propriétaire l\'aura approuvée.';
  }

  @override
  String get joinRequestPending => 'En attente d\'approbation';

  @override
  String get joinRequestApproved => 'Approuvée';

  @override
  String get joinRequestRejected => 'Rejetée';

  @override
  String get joinRequestsTitle => 'Demandes d\'adhésion';

  @override
  String get approveButton => 'Approuver';

  @override
  String get rejectButton => 'Rejeter';

  @override
  String get noPendingRequests => 'Aucune demande en attente';

  @override
  String get cancelRequestButton => 'Annuler la demande';

  @override
  String get joinRequestCancelled => 'Demande d\'adhésion annulée';

  @override
  String get pendingApprovalCardTitle => 'En attente d\'approbation';

  @override
  String get pendingApprovalCardSubtitle =>
      'En attente de l\'approbation du propriétaire du groupe.';

  @override
  String get invalidOrInactiveInvite =>
      'Code d\'invitation introuvable ou inactif';

  @override
  String get alreadyMemberError => 'Vous êtes déjà membre de ce groupe.';

  @override
  String get requestAlreadyPendingError =>
      'Vous avez déjà une demande en attente pour ce groupe.';

  @override
  String get manageJoinRequestsTooltip => 'Gérer les demandes d\'adhésion';

  @override
  String pendingRequestsBadge(int count) {
    return '$count en attente';
  }

  @override
  String get settledBadge => 'Réglé';

  @override
  String get noCategoryData =>
      'Aucune donnée de catégorie disponible pour le moment.';

  @override
  String get copyAction => 'Copier';

  @override
  String get uidCopiedSnackbar => 'UID copié dans le presse-papiers';

  @override
  String get privacyCalloutTitle =>
      'Architecture axée sur la confidentialité et la minimisation des données';

  @override
  String get privacyCalloutBody =>
      'Aucun e-mail, téléphone ou mot de passe collecté. Seuls les membres du groupe peuvent consulter les soldes.';

  @override
  String get readAction => 'Lire';

  @override
  String get expensePaidByMultiple => 'Multiple people paid';

  @override
  String get expensePaidByMultipleAdvanced => 'Multiple people paid...';

  @override
  String get expenseSwitchToMultiplePayers => 'Switch to Multiple Payers';

  @override
  String get expenseSwitchToSinglePayer => 'Switch to Single Payer';

  @override
  String get expenseSplit => 'Split';

  @override
  String get expenseSplitCustomize => 'Customize';

  @override
  String expenseSplitSummaryEqually(int count) {
    return 'Equally · $count people ›';
  }

  @override
  String expenseSplitSummaryCustom(int count) {
    return 'Custom · $count people ›';
  }

  @override
  String expenseSplitSummaryPercentage(int count) {
    return 'Percentage · $count people ›';
  }

  @override
  String expenseLiveSummary(String payer, String amount, int count) {
    return '$payer paid $amount · Split among $count people';
  }

  @override
  String expenseLiveSummaryMultiple(String amount, int count) {
    return 'Multiple paid $amount · Split among $count people';
  }

  @override
  String expenseLiveSummaryRemaining(String amount) {
    return '$amount remaining';
  }

  @override
  String expenseLiveSummaryOver(String amount) {
    return '$amount over';
  }

  @override
  String get errorTooManyPayers => 'Too many payers (max 5)';

  @override
  String get errorTooManyParticipants => 'Too many participants (max 20)';

  @override
  String get errorNegativeAmount => 'Amounts must be greater than zero';

  @override
  String expenseZeroShareRemoved(int count) {
    return '$count participant(s) with 0 share removed.';
  }

  @override
  String get languageSystem => 'Langue du système';

  @override
  String get currency => 'Devise';
}
