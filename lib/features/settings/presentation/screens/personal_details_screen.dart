import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bexly/core/components/buttons/primary_button.dart';
import 'package:bexly/core/components/dialogs/toast.dart';
import 'package:bexly/core/components/form_fields/custom_text_field.dart';
import 'package:bexly/core/components/scaffolds/custom_scaffold.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/services/image_service/image_service.dart';
import 'package:bexly/core/riverpod/auth_providers.dart' as firebase_auth;
import 'package:toastification/toastification.dart';

class PersonalDetailsScreen extends HookConsumerWidget {
  const PersonalDetailsScreen({super.key});
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
                      final pickedImage = await imageService.pickImage(context);
                      if (pickedImage != null) {
                        profilePicture.value = File(pickedImage.path);
                      }
                    },
                    child: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.darkAlpha30,
                          // Use colorScheme.surfaceVariant for a subtle background
                          radius: 70,
                          child: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surface, // Use colorScheme.surface
                            backgroundImage: profilePicture.value != null
                                ? FileImage(profilePicture.value!)
                                : null,
                            radius: 69,
                            child: profilePicture.value == null
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

                // TODO: Upload profile picture to Firebase Storage if changed
                // if (profilePicture.value != null) {
                //   final photoURL = await uploadProfilePicture(profilePicture.value!);
                //   await firebaseUser?.updatePhotoURL(photoURL);
                // }

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
