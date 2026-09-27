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
}
