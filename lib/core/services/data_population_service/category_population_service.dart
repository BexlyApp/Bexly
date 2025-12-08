import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:bexly/core/database/app_database.dart';
import 'package:bexly/core/localization/app_localizations.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:bexly/features/category/data/repositories/category_repo.dart';

class CategoryPopulationService {
  /// Supported languages in the app
  static const List<String> supportedLanguages = ['en', 'vi', 'zh', 'fr', 'th', 'id', 'es', 'pt', 'ja', 'ko', 'de', 'hi', 'ru', 'ar'];

  /// Generate localized titles JSON for a category
  /// Returns JSON string like: {"en": "Food & Drinks", "vi": "Ăn uống", ...}
  static String? _generateLocalizedTitles(int? categoryId) {
    if (categoryId == null) return null;

    final localizedTitles = <String, String>{};

    for (final langCode in supportedLanguages) {
      final locale = Locale(langCode);
      final l10n = AppLocalizations(locale);
      final localizedName = l10n.getCategoryName(categoryId);

      // Only include if we have a valid translation (not "Unknown Category")
      if (localizedName != 'Unknown Category') {
        localizedTitles[langCode] = localizedName;
      }
    }

    // Return null if no translations found
    if (localizedTitles.isEmpty) return null;

    return jsonEncode(localizedTitles);
  }

  static Future<void> populate(AppDatabase db) async {
    Log.i('Initializing default categories...', label: 'category');
    final allDefaultCategories = categories.getAllCategories();
    final categoryDao = db.categoryDao;

    for (final categoryModel in allDefaultCategories) {
      // Generate localized titles for this category
      final localizedTitlesJson = _generateLocalizedTitles(categoryModel.id);

      final companion = CategoriesCompanion(
        id: Value(
          categoryModel.id!,
        ), // Assuming IDs are always present in defaults
        title: Value(categoryModel.title),
        icon: Value(categoryModel.icon),
        iconBackground: Value(categoryModel.iconBackground),
        iconType: Value(categoryModel.iconTypeValue),
        parentId: categoryModel.parentId == null
            ? const Value.absent()
            : Value(categoryModel.parentId),
        description:
            categoryModel.description == null ||
                categoryModel.description!.isEmpty
            ? const Value.absent()
            : Value(categoryModel.description!),
        localizedTitles: localizedTitlesJson == null
            ? const Value.absent()
            : Value(localizedTitlesJson),
        isSystemDefault: const Value(true), // Mark as system default
        transactionType: Value(categoryModel.transactionType),
      );
      try {
        await categoryDao.addCategory(companion);
      } catch (e) {
        Log.e(
          'Failed to add category ${categoryModel.title}: $e',
          label: 'category',
        );
        // Decide if you want to stop initialization or continue
      }
    }

    Log.i(
      'Default categories initialization complete: (${allDefaultCategories.length}',
      label: 'category',
    );
  }

  /// Re-populates default categories by removing all and re-inserting
  /// This fixes corrupted categories while preserving transactions
  static Future<void> repopulate(AppDatabase db) async {
    Log.i('Re-populating default categories...', label: 'category');
    final allDefaultCategories = categories.getAllCategories();
    final categoryDao = db.categoryDao;

    // STEP 1: Disable foreign key constraints temporarily
    Log.i('Disabling foreign key constraints...', label: 'category');
    await db.customStatement('PRAGMA foreign_keys = OFF;');

    try {
      // STEP 2: Delete ALL categories
      Log.i('Deleting all existing categories...', label: 'category');
      await db.customStatement('DELETE FROM categories;');

      // STEP 3: Insert default categories with correct IDs
      Log.i('Inserting ${allDefaultCategories.length} default categories...', label: 'category');
      for (final categoryModel in allDefaultCategories) {
        // Generate localized titles for this category
        final localizedTitlesJson = _generateLocalizedTitles(categoryModel.id);

        final companion = CategoriesCompanion(
          id: Value(categoryModel.id!),
          title: Value(categoryModel.title),
          icon: Value(categoryModel.icon),
          iconBackground: Value(categoryModel.iconBackground),
          iconType: Value(categoryModel.iconTypeValue),
          parentId: categoryModel.parentId == null
              ? const Value.absent()
              : Value(categoryModel.parentId),
          description:
              categoryModel.description == null ||
                  categoryModel.description!.isEmpty
              ? const Value.absent()
              : Value(categoryModel.description!),
          localizedTitles: localizedTitlesJson == null
              ? const Value.absent()
              : Value(localizedTitlesJson),
          isSystemDefault: const Value(true),
          transactionType: Value(categoryModel.transactionType),
        );

        try {
          await categoryDao.upsertCategory(companion);
        } catch (e) {
          Log.e(
            'Failed to insert category ${categoryModel.title}: $e',
            label: 'category',
          );
        }
      }

      Log.i(
        'Successfully re-populated ${allDefaultCategories.length} categories',
        label: 'category',
      );
    } finally {
      // STEP 4: Re-enable foreign key constraints
      Log.i('Re-enabling foreign key constraints...', label: 'category');
      await db.customStatement('PRAGMA foreign_keys = ON;');
    }
  }
}
