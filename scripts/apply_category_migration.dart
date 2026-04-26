import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Script to apply category Modified Hybrid Sync migration to Supabase
///
/// Usage:
///   SUPABASE_URL=... SUPABASE_PUBLISHABLE_KEY=... dart scripts/apply_category_migration.dart
///
/// Or source .env first: `set -a && . ./.env && set +a`
///
/// Prerequisites:
///   - SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY in environment
///   - User must be authenticated as admin with database write access

Future<void> main() async {
  print('🚀 Category Modified Hybrid Sync Migration');
  print('═' * 60);

  final supabaseUrl = Platform.environment['SUPABASE_URL'];
  final supabaseKey = Platform.environment['SUPABASE_PUBLISHABLE_KEY'];

  if (supabaseUrl == null || supabaseKey == null) {
    print('❌ Missing Supabase credentials in .env');
    print('   Required: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY');
    exit(1);
  }

  // Initialize Supabase
  print('🔌 Connecting to Supabase...');
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );
  final supabase = Supabase.instance.client;

  // Read migration SQL
  print('📄 Reading migration file...');
  final migrationFile = File('supabase/migrations/20260115_add_category_hybrid_sync_columns.sql');

  if (!migrationFile.existsSync()) {
    print('❌ Migration file not found: ${migrationFile.path}');
    exit(1);
  }

  final migrationSql = migrationFile.readAsStringSync();
  print('✅ Migration loaded (${migrationSql.length} characters)');

  // Confirm with user
  print('');
  print('⚠️  This will apply the following changes to bexly.categories:');
  print('   • Add columns: source, built_in_id, has_been_modified, is_deleted');
  print('   • Create indexes for sync queries');
  print('   • Update RLS policies');
  print('   • Migrate existing data (mark all as built-in with modified flag)');
  print('');
  stdout.write('Do you want to proceed? (yes/no): ');
  final confirmation = stdin.readLineSync();

  if (confirmation?.toLowerCase() != 'yes') {
    print('❌ Migration cancelled by user');
    exit(0);
  }

  // Apply migration using RPC (requires a migration function on Supabase)
  print('');
  print('🔄 Applying migration...');
  print('');

  try {
    // Split SQL into individual statements
    final statements = migrationSql
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !s.startsWith('--'))
        .toList();

    print('Found ${statements.length} SQL statements');

    // Execute each statement
    int successCount = 0;
    for (var i = 0; i < statements.length; i++) {
      final statement = statements[i];

      // Skip comments
      if (statement.startsWith('--') || statement.startsWith('/*')) {
        continue;
      }

      try {
        print('${i + 1}/${statements.length}: Executing...');

        // Use RPC to execute raw SQL (requires a custom RPC function)
        await supabase.rpc('exec_sql', params: {'sql': statement});

        successCount++;
        print('   ✅ Success');
      } catch (e) {
        // Some statements might fail if already applied (e.g., ADD COLUMN IF NOT EXISTS)
        if (e.toString().contains('already exists') ||
            e.toString().contains('IF NOT EXISTS')) {
          print('   ⚠️  Already exists (skipped)');
          successCount++;
        } else {
          print('   ❌ Error: $e');
          // Continue with next statement
        }
      }
    }

    print('');
    print('═' * 60);
    print('✅ Migration completed!');
    print('   • $successCount statements executed successfully');
    print('');
    print('Next steps:');
    print('   1. Verify schema changes in Supabase Dashboard');
    print('   2. Run data conversion script to migrate local categories');
    print('   3. Test sync flow');

  } catch (e) {
    print('❌ Migration failed: $e');
    exit(1);
  }
}
