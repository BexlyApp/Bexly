import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/utils/logger.dart';

/// Provider to hold the selected avatar path (local file path or URL)
final avatarPathProvider = StateProvider.autoDispose<String?>((ref) => null);

class AvatarPicker extends HookConsumerWidget {
  final String? initialImageUrl; // Firebase photoURL or other URL

  const AvatarPicker({
    super.key,
    this.initialImageUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarPath = ref.watch(avatarPathProvider);

    // Initialize with Firebase photo URL on first load
    useEffect(() {
      if (initialImageUrl != null && avatarPath == null) {
        Future.microtask(() {
          ref.read(avatarPathProvider.notifier).state = initialImageUrl;
        });
      }
      return null;
    }, [initialImageUrl]);

    Future<void> pickImage() async {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 85,
        );

        if (image != null) {
          ref.read(avatarPathProvider.notifier).state = image.path;
          Log.i('Avatar selected: ${image.path}', label: 'onboarding');
        }
      } catch (e) {
        Log.e('Error picking image: $e', label: 'onboarding');
      }
    }

    // Check if avatarPath is a URL or local file path
    final bool isUrl = avatarPath != null &&
        (avatarPath.startsWith('http://') || avatarPath.startsWith('https://'));
    final bool isLocalFile = avatarPath != null && !isUrl;

    return GestureDetector(
      onTap: pickImage,
      child: Stack(
        children: [
          // Avatar circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neutral100,
              border: Border.all(
                color: AppColors.primary,
                width: 3,
              ),
              image: isLocalFile
                  ? DecorationImage(
                      image: FileImage(File(avatarPath!)),
                      fit: BoxFit.cover,
                    )
                  : isUrl
                      ? DecorationImage(
                          image: NetworkImage(avatarPath!),
                          fit: BoxFit.cover,
                        )
                      : null,
            ),
            child: avatarPath == null
                ? HugeIcon(
                    icon: HugeIcons.strokeRoundedUser as dynamic,
                    size: 48,
                    color: AppColors.neutral50,
                  )
                : null,
          ),

          // Edit button
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedCamera01 as dynamic,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
