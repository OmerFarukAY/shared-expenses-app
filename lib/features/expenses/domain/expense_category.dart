import 'package:flutter/material.dart';
import 'package:denk/core/theme/app_colors.dart';
import 'package:denk/l10n/l10n.dart';

/// Sensible expense categories with visual differentiation.
enum ExpenseCategory {
  food,
  groceries,
  transport,
  home,
  entertainment,
  travel,
  bills,
  shopping,
  other;

  String get id => name;

  String localizedName(AppLocalizations? l10n) {
    switch (this) {
      case ExpenseCategory.food:
        return l10n?.categoryFood ?? 'Food & Dining';
      case ExpenseCategory.groceries:
        return l10n?.categoryGroceries ?? 'Groceries';
      case ExpenseCategory.transport:
        return l10n?.categoryTransport ?? 'Transport';
      case ExpenseCategory.home:
        return l10n?.categoryHome ?? 'Home & Rent';
      case ExpenseCategory.entertainment:
        return l10n?.categoryEntertainment ?? 'Entertainment';
      case ExpenseCategory.travel:
        return l10n?.categoryTravel ?? 'Travel';
      case ExpenseCategory.bills:
        return l10n?.categoryBills ?? 'Bills & Utilities';
      case ExpenseCategory.shopping:
        return l10n?.categoryShopping ?? 'Shopping';
      case ExpenseCategory.other:
        return l10n?.categoryOther ?? 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.groceries:
        return Icons.local_grocery_store_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_subway_rounded;
      case ExpenseCategory.home:
        return Icons.home_rounded;
      case ExpenseCategory.entertainment:
        return Icons.confirmation_number_rounded;
      case ExpenseCategory.travel:
        return Icons.flight_takeoff_rounded;
      case ExpenseCategory.bills:
        return Icons.receipt_long_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.other:
        return Icons.category_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return AppColors.categoryFood;
      case ExpenseCategory.groceries:
        return AppColors.categoryGroceries;
      case ExpenseCategory.transport:
        return AppColors.categoryTransport;
      case ExpenseCategory.home:
        return AppColors.categoryHome;
      case ExpenseCategory.entertainment:
        return AppColors.categoryEntertainment;
      case ExpenseCategory.travel:
        return AppColors.categoryTravel;
      case ExpenseCategory.bills:
        return AppColors.categoryBills;
      case ExpenseCategory.shopping:
        return AppColors.categoryShopping;
      case ExpenseCategory.other:
        return AppColors.categoryOther;
    }
  }

  static ExpenseCategory fromString(String? key) {
    if (key == null) return ExpenseCategory.other;
    return ExpenseCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == key.toLowerCase(),
      orElse: () => ExpenseCategory.other,
    );
  }
}
