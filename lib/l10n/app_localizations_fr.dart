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

  @override
  String get memberLeftSuffix => ' (parti)';

  @override
  String get removeMember => 'Supprimer le membre';

  @override
  String get leaveGroup => 'Quitter le groupe';

  @override
  String get deleteGroup => 'Supprimer le groupe';

  @override
  String get cannotRemoveMemberBalance =>
      'Le membre ne peut pas être supprimé avant que son solde ne soit nul.';

  @override
  String get cannotLeaveGroupBalance =>
      'Vous ne pouvez pas quitter le groupe avant que votre solde ne soit nul.';

  @override
  String get privacyBullet1 =>
      'Aucun e-mail, numéro de téléphone ou mot de passe requis.';

  @override
  String get privacyBullet2 =>
      'Aucun identifiant publicitaire ou SDK de suivi.';

  @override
  String get privacyBullet3 =>
      'Aucune autorisation d\'accès aux contacts ou à la localisation GPS.';

  @override
  String get privacyBullet4 =>
      'L\'authentification utilise des identifiants Firebase anonymes.';

  @override
  String get privacyBullet5 =>
      'Seuls les membres du groupe avec lesquels vous partagez votre code d\'invitation peuvent voir les dépenses.';

  @override
  String get accountSecurityTitle => 'Sécurité et récupération du compte';

  @override
  String get accountSecuritySubtitle =>
      'Associez un compte pour récupérer vos groupes et soldes sur tous vos appareils.';

  @override
  String get accountSecuredSubtitle =>
      'Vos groupes et soldes sont sauvegardés et récupérables sur tous vos appareils.';

  @override
  String get accountStatusAnonymous => 'Compte invité (non sécurisé)';

  @override
  String get accountStatusSecured => 'Compte sécurisé';

  @override
  String get linkWithGoogle => 'Associer avec Google';

  @override
  String get linkWithApple => 'Continuer avec Apple';

  @override
  String get linkedWithGoogle => 'Associé avec Google';

  @override
  String get linkedWithApple => 'Associé avec Apple';

  @override
  String get accountLinkingSuccess => 'Compte associé avec succès !';

  @override
  String get accountAlreadyInUseTitle => 'Compte déjà existant';

  @override
  String get accountAlreadyInUseBody =>
      'Ce compte est déjà associé à un autre profil Denk. Souhaitez-vous passer à ce compte sur cet appareil ou continuer avec votre compte invité actuel ?';

  @override
  String get switchAccountButton => 'Passer au compte existant';

  @override
  String get keepCurrentAccountButton => 'Garder le compte invité';

  @override
  String get accountSwitchSuccess => 'Passage au compte existant effectué.';

  @override
  String get accountLinkErrorGeneric =>
      'Échec de l\'association du compte. Veuillez réessayer.';

  @override
  String get appleAccountRequired =>
      'Veuillez vous connecter avec un compte Apple dans les réglages de l\'appareil pour continuer.';

  @override
  String get deleteAccountTitle => 'Supprimer le Compte';

  @override
  String get deleteAccountSubtitle =>
      'Supprimez définitivement votre compte. Les groupes dont vous êtes propriétaire avec d\'autres membres nécessitent un transfert de propriété. Irréversible.';

  @override
  String get deleteAccountConfirmTitle =>
      'Supprimer définitivement le compte ?';

  @override
  String get deleteAccountConfirmBody =>
      'Cette action est irréversible. Votre historique de dépenses sera conservé, mais votre nom sera anonymisé. Les groupes où vous êtes le seul propriétaire seront supprimés.';

  @override
  String get deleteAccountSuccess => 'Votre compte a été supprimé.';

  @override
  String get deleteAccountOwnershipRequired => 'Transfert de Propriété Requis';

  @override
  String get deleteAccountOwnershipRequiredBody =>
      'Vous êtes propriétaire des groupes suivants avec d\'autres membres. Veuillez transférer la propriété avant de supprimer votre compte.';

  @override
  String get transferOwnershipButton => 'Transférer la Propriété';

  @override
  String get transferOwnershipTitle => 'Transférer la Propriété du Groupe';

  @override
  String get transferOwnershipBody =>
      'Sélectionnez un membre pour devenir le nouveau propriétaire. Vous resterez membre du groupe.';

  @override
  String get transferOwnershipSuccess => 'Propriété transférée avec succès.';

  @override
  String get deleteAccountReauthRequired =>
      'Veuillez vous reconnecter pour confirmer la suppression du compte.';

  @override
  String get deleteAccountProcessing => 'Suppression du compte...';

  @override
  String get privacyPolicyTitle => 'Politique de Confidentialité';

  @override
  String get termsOfServiceTitle => 'Conditions d\'Utilisation';

  @override
  String get webAccountDeletionTitle => 'Suppression de Compte Web';

  @override
  String get webAccountDeletionSubtitle =>
      'Demandez la suppression de votre compte et de vos données sur le web si vous n\'avez plus accès à l\'application.';

  @override
  String get errorOpeningUrl => 'Impossible d\'ouvrir le lien.';

  @override
  String get legalSectionTitle => 'Mentions Légales';

  @override
  String get openAction => 'Ouvrir';
}
