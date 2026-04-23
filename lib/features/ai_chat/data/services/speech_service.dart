import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:bexly/core/utils/logger.dart';

export 'package:speech_to_text/speech_to_text.dart' show LocaleName;

/// Provider for the speech service
final speechServiceProvider = Provider<SpeechService>((ref) {
  return SpeechService();
});

/// Provider for speech recognition state
final speechStateProvider = NotifierProvider<SpeechStateNotifier, SpeechState>(() {
  return SpeechStateNotifier();
});

/// Speech recognition state
class SpeechState {
  final bool isInitialized;
  final bool isListening;
  final String recognizedText;
  final String partialText;
  final double confidence;
  final String? error;
  final String currentLocale;

  const SpeechState({
    this.isInitialized = false,
    this.isListening = false,
    this.recognizedText = '',
    this.partialText = '',
    this.confidence = 0.0,
    this.error,
    this.currentLocale = 'vi_VN',
  });

  SpeechState copyWith({
    bool? isInitialized,
    bool? isListening,
    String? recognizedText,
    String? partialText,
    double? confidence,
    String? error,
    String? currentLocale,
  }) {
    return SpeechState(
      isInitialized: isInitialized ?? this.isInitialized,
      isListening: isListening ?? this.isListening,
      recognizedText: recognizedText ?? this.recognizedText,
      partialText: partialText ?? this.partialText,
      confidence: confidence ?? this.confidence,
      error: error,
      currentLocale: currentLocale ?? this.currentLocale,
    );
  }
}

/// State notifier for speech recognition
class SpeechStateNotifier extends Notifier<SpeechState> {
  late final SpeechService _service;

  @override
  SpeechState build() {
    _service = ref.watch(speechServiceProvider);
    return const SpeechState();
  }

  /// Initialize speech recognition
  Future<bool> initialize() async {
    if (state.isInitialized) return true;

    final success = await _service.initialize();
    if (success) {
      state = state.copyWith(isInitialized: true, error: null);
    } else {
      state = state.copyWith(
        isInitialized: false,
        error: 'Speech recognition not available on this device',
      );
    }
    return success;
  }

  /// Start listening for speech
  Future<void> startListening({String? localeId}) async {
    if (!state.isInitialized) {
      final success = await initialize();
      if (!success) return;
    }

    if (state.isListening) return;

    state = state.copyWith(
      isListening: true,
      recognizedText: '',
      partialText: '',
      error: null,
    );

    await _service.startListening(
      onResult: (result) {
        if (result.finalResult) {
          state = state.copyWith(
            recognizedText: result.recognizedWords,
            partialText: '',
            confidence: result.confidence,
            isListening: false,
          );
        } else {
          state = state.copyWith(
            partialText: result.recognizedWords,
          );
        }
      },
      localeId: localeId ?? state.currentLocale,
      onError: (error) {
        state = state.copyWith(
          isListening: false,
          error: error,
        );
      },
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!state.isListening) return;
    await _service.stopListening();
    state = state.copyWith(isListening: false);
  }

  /// Cancel listening (discard partial results)
  Future<void> cancelListening() async {
    if (!state.isListening) return;
    await _service.cancelListening();
    state = state.copyWith(
      isListening: false,
      partialText: '',
    );
  }

  /// Set locale for speech recognition
  void setLocale(String localeId) {
    state = state.copyWith(currentLocale: localeId);
  }

  /// Clear recognized text
  void clearText() {
    state = state.copyWith(
      recognizedText: '',
      partialText: '',
    );
  }
}

/// Service for speech-to-text functionality
class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  /// Initialize the speech recognition service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          Log.d('Speech status: $status', label: 'SpeechService');
        },
        onError: (error) {
          Log.e('Speech error: ${error.errorMsg}', label: 'SpeechService');
        },
        debugLogging: false,
      );

      if (_isInitialized) {
        final locales = await _speech.locales();
        Log.d('Available locales: ${locales.map((l) => l.localeId).join(", ")}', label: 'SpeechService');
      }

      return _isInitialized;
    } catch (e) {
      Log.e('Failed to initialize speech: $e', label: 'SpeechService');
      return false;
    }
  }

  /// Check if speech recognition is available
  bool get isAvailable => _isInitialized && _speech.isAvailable;

  /// Check if currently listening
  bool get isListening => _speech.isListening;

  /// Get available locales
  Future<List<LocaleName>> getLocales() async {
    if (!_isInitialized) return [];
    return await _speech.locales();
  }

  /// Start listening for speech input
  Future<void> startListening({
    required Function(SpeechRecognitionResult) onResult,
    String localeId = 'vi_VN',
    Function(String)? onError,
  }) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) {
        onError?.call('Speech recognition not available');
        return;
      }
    }

    try {
      await _speech.listen(
        onResult: onResult,
        localeId: localeId,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
        ),
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
      Log.d('Started listening with locale: $localeId', label: 'SpeechService');
    } catch (e) {
      Log.e('Failed to start listening: $e', label: 'SpeechService');
      onError?.call('Failed to start voice input');
    }
  }

  /// Stop listening and finalize result
  Future<void> stopListening() async {
    await _speech.stop();
    Log.d('Stopped listening', label: 'SpeechService');
  }

  /// Cancel listening and discard results
  Future<void> cancelListening() async {
    await _speech.cancel();
    Log.d('Cancelled listening', label: 'SpeechService');
  }
}
