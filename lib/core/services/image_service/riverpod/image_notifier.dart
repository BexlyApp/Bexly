import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bexly/core/services/image_service/domain/image_state.dart';
import 'package:bexly/core/services/image_service/image_service.dart';
import 'package:bexly/core/services/image_service/riverpod/image_service_provider.dart';

class ImageNotifier extends Notifier<ImageState> {
  late final ImageService _imageService;

  @override
  ImageState build() {
    _imageService = ref.watch(imageServiceProvider);
    return ImageState();
  }

  Future<String?> pickImage() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final image = await _imageService.pickImageFromGallery();
      state = state.copyWith(imageFile: image, isLoading: false);
      return state.savedPath;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to pick image: $e',
        isLoading: false,
      );
    }

    return '';
  }

  Future<String?> takePhoto() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final image = await _imageService.takePhoto();
      state = state.copyWith(imageFile: image, isLoading: false);
      return state.savedPath;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to take photo: $e',
        isLoading: false,
      );
    }
    return '';
  }

  Future<String?> saveImage() async {
    if (state.imageFile == null) return null;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final savedPath = await _imageService.saveImage(state.imageFile!);
      state = state.copyWith(savedPath: savedPath, isLoading: false);
      return savedPath;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to save image: $e',
        isLoading: false,
      );

      return null;
    }
  }

  Future<bool> deleteImage() async {
    if (state.savedPath == null) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _imageService.deleteImage(state.savedPath!);

      if (!success) {
        state.clear();
      } else {
        state = state.copyWith(isLoading: false);
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete image: $e',
        isLoading: false,
      );

      return false;
    }
  }

  /// Loads an image from a given file path and updates the state.
  /// This is useful for displaying an existing image.
  void loadImagePath(String path) {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final imageFile = File(path);
      // We assume the path provided is already a saved/persistent path.
      state = state.copyWith(
        imageFile: imageFile,
        savedPath: path,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load image from path: $e',
        isLoading: false,
      );
    }
  }

  /// Sets an image from bytes (e.g., from receipt scanner)
  /// Creates a temporary file and saves the bytes to it
  Future<void> setImageFromBytes(Uint8List imageBytes, {String fileName = 'receipt.jpg'}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');

      // Write bytes to file
      await tempFile.writeAsBytes(imageBytes);

      // Update state with the file
      state = state.copyWith(
        imageFile: tempFile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load image from bytes: $e',
        isLoading: false,
      );
    }
  }

  void clearImage() {
    state = state.clear();
  }
}

final imageProvider = NotifierProvider<ImageNotifier, ImageState>(
  ImageNotifier.new,
);
