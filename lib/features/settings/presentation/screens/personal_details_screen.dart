import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bexly/core/services/supabase_init_service.dart';
import 'package:gap/gap.dart';
import 'package:bexly/core/components/bottom_sheets/custom_bottom_sheet.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/components/buttons/secondary_button.dart';
import 'package:bexly/core/components/dialogs/toast.dart';
import 'package:bexly/core/extensions/popup_extension.dart';
import 'package:bexly/core/components/form_fields/custom_text_field.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/services/image_service/image_service.dart';
import 'package:bexly/core/services/auth/supabase_auth_service.dart';
import 'package:bexly/features/authentication/presentation/riverpod/auth_provider.dart';
import 'package:bexly/core/extensions/localization_extension.dart';
import 'package:bexly/core/utils/logger.dart';
import 'package:toastification/toastification.dart';

class PersonalDetailsScreen extends HookConsumerWidget {
  const PersonalDetailsScreen({super.key});

  /// Upload profile picture to Supabase Storage and return download URL
  Future<(String?, String?)> _uploadProfilePicture(File imageFile, String userId) async {
    try {
      Log.i('Uploading profile picture for user: $userId', label: 'ProfileUpload');

      // Use Supabase Storage with 'Assets' bucket
      // Structure: Assets/Avatars/{userId}/avatar.jpg (shared across all products)
      if (!SupabaseInitService.isInitialized) {
        return (null, 'Supabase not initialized');
      }
      final supabase = SupabaseInitService.client;

      // Create file path: Avatars/{userId}/avatar.jpg
      final filePath = 'Avatars/$userId/avatar.jpg';

      Log.i('Storage path: Assets/$filePath', label: 'ProfileUpload');
      Log.i('Using Supabase Storage (Assets bucket)', label: 'ProfileUpload');

      // Upload file to Supabase Storage
      await supabase.storage.from('Assets').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              upsert: true, // Overwrite if exists
              contentType: 'image/jpeg',
            ),
          );

      // Get public download URL
      final downloadUrl = supabase.storage.from('Assets').getPublicUrl(filePath);

      Log.i('Profile picture uploaded successfully: $downloadUrl', label: 'ProfileUpload');
      return (downloadUrl, null);
    } catch (e, stack) {
      Log.e('Failed to upload profile picture: $e', label: 'ProfileUpload');
      Log.e('Stack: $stack', label: 'ProfileUpload');
      return (null, e.toString());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get user data from Supabase auth + local auth state
    final supabaseAuth = ref.watch(supabaseAuthServiceProvider);
    final localAuth = ref.watch(authStateProvider);

    final nameField = useTextEditingController();
    final emailField = useTextEditingController();
    final profilePicture = useState<File?>(null);

    useEffect(() {
      // Use local auth state (with offline support)
      nameField.text = localAuth.name;
      emailField.text = localAuth.email;

      return null;
    }, [localAuth]);

    return CustomScaffold(
      context: context,
      title: context.l10n.personalDetails,
      showBalance: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Form(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.spacing20,
                AppSpacing.spacing16,
                AppSpacing.spacing20,
                100,
              ),
              child: Column(
                spacing: AppSpacing.spacing16,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final imageService = ImageService();

                      // Show bottom sheet with Camera + Gallery options
                      await context.openBottomSheet<void>(
                        child: CustomBottomSheet(
                          title: context.l10n.choosePhoto,
                          child: Row(
                            children: [
                              Expanded(
                                child: SecondaryButton(
                                  context: context,
                                  onPressed: () async {
                                    Navigator.pop(context); // Close bottom sheet first
                                    final file = await imageService.takePhoto();
                                    if (file != null) {
                                      profilePicture.value = file;
                                      Log.d('Profile picture taken: ${file.path}', label: 'PersonalDetails');
                                    }
                                  },
                                  label: context.l10n.camera,
                                  icon: HugeIcons.strokeRoundedCamera01,
                                ),
                              ),
                              const Gap(AppSpacing.spacing8),
                              Expanded(
                                child: SecondaryButton(
                                  context: context,
                                  onPressed: () async {
                                    Navigator.pop(context); // Close bottom sheet first
                                    final file = await imageService.pickImageFromGallery();
                                    if (file != null) {
                                      profilePicture.value = file;
                                      Log.d('Profile picture selected: ${file.path}', label: 'PersonalDetails');
                                    }
                                  },
                                  label: context.l10n.gallery,
                                  icon: HugeIcons.strokeRoundedImage01,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.darkAlpha30,
                          // Use colorScheme.surfaceVariant for a subtle background
                          radius: 70,
                          child: CircleAvatar(
                            // Only show background when no image (to support transparent PNGs)
                            backgroundColor: (profilePicture.value == null && localAuth.profilePicture == null)
                                ? Theme.of(context).colorScheme.surface
                                : Colors.transparent,
                            backgroundImage: profilePicture.value != null
                                ? FileImage(profilePicture.value!)
                                : (localAuth.profilePicture != null
                                    ? (localAuth.profilePicture!.startsWith('http')
                                        ? NetworkImage(localAuth.profilePicture!)
                                        : FileImage(File(localAuth.profilePicture!)))
                                    : null),
                            radius: 69,
                            child: profilePicture.value == null && localAuth.profilePicture == null
                                ? Icon(
                                    Icons.camera_alt,
                                    color: AppColors.darkAlpha30,
                                    size: 40,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(AppSpacing.spacing8),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              shape: BoxShape.circle,
                            ),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedCamera02,
                              size: 20,
                              color: AppColors.neutral200,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomTextField(
                    controller: nameField,
                    label: context.l10n.name,
                    hint: 'John Doe',
                    maxLength: 100,
                    customCounterText: '',
                  ),
                  CustomTextField(
                    controller: emailField,
                    label: context.l10n.email,
                    hint: 'john@example.com',
                    enabled: false,
                    customCounterText: '',
                  ),
                ],
              ),
            ),
          ),
          PrimaryButton(
            label: context.l10n.save,
            onPressed: () async {
              final newName = nameField.text.trim();
              if (newName.isEmpty) {
                Toast.show(
                  context.l10n.nameCannotBeEmpty,
                  type: ToastificationType.warning,
                );
                return;
              }

              try {
                String? photoURL = localAuth.profilePicture;

                // Upload profile picture to Supabase Storage if changed
                if (profilePicture.value != null) {
                  final userId = supabaseAuth.userId ?? localAuth.id.toString();
                  Log.i('Uploading new profile picture...', label: 'PersonalDetails');
                  final (uploadedPhotoURL, errorMessage) = await _uploadProfilePicture(
                    profilePicture.value!,
                    userId,
                  );

                  if (uploadedPhotoURL != null) {
                    photoURL = uploadedPhotoURL;
                    Log.i('Profile photo URL updated: $photoURL', label: 'PersonalDetails');
                  } else {
                    Log.w('Failed to upload profile picture: $errorMessage', label: 'PersonalDetails');
                    if (context.mounted) {
                      Toast.show(
                        context.l10n.failedToUploadAvatar,
                        type: ToastificationType.error,
                      );
                    }
                    return; // Don't continue if upload failed
                  }
                }

                // 1. Save local FIRST (instant feedback, works offline)
                final updatedUser = ref.read(authStateProvider).copyWith(
                  name: newName,
                  profilePicture: photoURL,
                );
                ref.read(authStateProvider.notifier).setUser(updatedUser);
                Log.i('✅ Updated local auth state', label: 'PersonalDetails');

                // 2. Sync to Supabase in background (fire and forget)
                if (supabaseAuth.isAuthenticated) {
                  try {
                    await ref.read(supabaseAuthServiceProvider.notifier).updateProfile(
                      fullName: newName,
                      avatarUrl: photoURL,
                    );
                    Log.i('✅ Synced to Supabase user metadata', label: 'PersonalDetails');
                  } catch (e) {
                    Log.w('Failed to sync to Supabase: $e', label: 'PersonalDetails');
                    // Don't show error - local update succeeded, sync can retry later
                  }
                }

                if (context.mounted) {
                  Toast.show(
                    context.l10n.personalDetailsUpdated,
                    type: ToastificationType.success,
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  Toast.show(
                    '${context.l10n.failedToUpdateProfile}: ${e.toString()}',
                    type: ToastificationType.error,
                  );
                }
              }
            },
          ).floatingBottomContained,
        ],
      ),
    );
  }
}
