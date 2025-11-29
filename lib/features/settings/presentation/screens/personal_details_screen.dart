import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
import 'package:bexly/core/riverpod/auth_providers.dart' as firebase_auth;
import 'package:bexly/core/utils/logger.dart';
import 'package:toastification/toastification.dart';

class PersonalDetailsScreen extends HookConsumerWidget {
  const PersonalDetailsScreen({super.key});

  /// Upload profile picture to Firebase Storage and return download URL
  Future<(String?, String?)> _uploadProfilePicture(File imageFile, String userId) async {
    try {
      Log.i('Uploading profile picture for user: $userId', label: 'ProfileUpload');

      // Use Bexly Firebase Storage (same project as Authentication)
      // FirebaseStorage.instance uses DEFAULT app which is Bexly
      final storage = FirebaseStorage.instance;

      // Create unique file path: avatars/{userId}/profile.jpg
      final storageRef = storage.ref().child('avatars/$userId/profile.jpg');

      Log.i('Storage path: avatars/$userId/profile.jpg', label: 'ProfileUpload');
      Log.i('Using default Firebase Storage (bexly-app)', label: 'ProfileUpload');

      // Upload file
      final uploadTask = storageRef.putFile(imageFile);

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

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
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final nameField = useTextEditingController();
    final emailField = useTextEditingController();
    final profilePicture = useState<File?>(null);

    useEffect(() {
      // Read directly from Firebase Auth (source of truth)
      nameField.text = firebaseUser?.displayName ?? '';
      emailField.text = firebaseUser?.email ?? '';
      if (firebaseUser?.photoURL != null) {
        // photoURL is typically a network URL, not local file
        // You may need to download and cache it if needed
      }

      return null;
    }, [firebaseUser]);

    return CustomScaffold(
      context: context,
      title: 'Personal Details',
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
                          title: 'Choose Photo',
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
                                  label: 'Camera',
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
                                  label: 'Gallery',
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
                            backgroundColor: (profilePicture.value == null && firebaseUser?.photoURL == null)
                                ? Theme.of(context).colorScheme.surface
                                : Colors.transparent,
                            backgroundImage: profilePicture.value != null
                                ? FileImage(profilePicture.value!)
                                : (firebaseUser?.photoURL != null
                                    ? NetworkImage(firebaseUser!.photoURL!)
                                    : null),
                            radius: 69,
                            child: profilePicture.value == null && firebaseUser?.photoURL == null
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
                            child: Icon(
                              HugeIcons.strokeRoundedCamera02,
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
                    label: 'Name',
                    hint: 'John Doe',
                    maxLength: 100,
                    customCounterText: '',
                  ),
                  CustomTextField(
                    controller: emailField,
                    label: 'Email',
                    hint: 'john@example.com',
                    enabled: false,
                    customCounterText: '',
                  ),
                ],
              ),
            ),
          ),
          PrimaryButton(
            label: 'Save',
            onPressed: () async {
              final newName = nameField.text.trim();
              if (newName.isEmpty) {
                Toast.show(
                  'Name cannot be empty.',
                  type: ToastificationType.warning,
                );
                return;
              }

              try {
                // Update Firebase Auth profile directly (source of truth)
                await firebaseUser?.updateDisplayName(newName);

                // Upload profile picture to Firebase Storage if changed
                if (profilePicture.value != null && firebaseUser != null) {
                  Log.i('Uploading new profile picture...', label: 'PersonalDetails');
                  final (photoURL, errorMessage) = await _uploadProfilePicture(
                    profilePicture.value!,
                    firebaseUser.uid,
                  );

                  if (photoURL != null) {
                    await firebaseUser.updatePhotoURL(photoURL);
                    Log.i('Profile photo URL updated: $photoURL', label: 'PersonalDetails');
                  } else {
                    Log.w('Failed to upload profile picture: $errorMessage', label: 'PersonalDetails');
                    Toast.show(
                      'Failed to upload avatar',
                      type: ToastificationType.error,
                    );
                    return; // Don't continue if upload failed
                  }
                }

                // Reload user to get updated profile
                await firebaseUser?.reload();

                // Invalidate auth provider to force refresh UI
                ref.invalidate(firebase_auth.authStateProvider);

                Toast.show(
                  'Personal details updated!',
                  type: ToastificationType.success,
                );

                if (context.mounted) context.pop();
              } catch (e) {
                Toast.show(
                  'Failed to update profile: ${e.toString()}',
                  type: ToastificationType.error,
                );
              }
            },
          ).floatingBottomContained,
        ],
      ),
    );
  }
}
