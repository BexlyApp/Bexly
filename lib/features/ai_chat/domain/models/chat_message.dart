import 'dart:typed_data';

/// Action button for confirm dialogs in chat
class ChatActionButton {
  final String label;
  final String actionType; // 'confirm' or 'cancel'
  final Map<String, dynamic>? actionData; // Data to pass when confirmed

  const ChatActionButton({
    required this.label,
    required this.actionType,
    this.actionData,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'actionType': actionType,
    if (actionData != null) 'actionData': actionData,
  };

  factory ChatActionButton.fromJson(Map<String, dynamic> json) {
    return ChatActionButton(
      label: json['label'] as String,
      actionType: json['actionType'] as String,
      actionData: json['actionData'] as Map<String, dynamic>?,
    );
  }
}

/// Pending action that requires user confirmation
class PendingAction {
  final String actionType; // e.g., 'delete_budget', 'update_budget'
  final Map<String, dynamic> actionData;
  final List<ChatActionButton> buttons;

  const PendingAction({
    required this.actionType,
    required this.actionData,
    required this.buttons,
  });

  Map<String, dynamic> toJson() => {
    'actionType': actionType,
    'actionData': actionData,
    'buttons': buttons.map((b) => b.toJson()).toList(),
  };

  factory PendingAction.fromJson(Map<String, dynamic> json) {
    return PendingAction(
      actionType: json['actionType'] as String,
      actionData: json['actionData'] as Map<String, dynamic>,
      buttons: (json['buttons'] as List)
          .map((b) => ChatActionButton.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ChatMessage {
  final String id;
  final String content;
  final bool isFromUser;
  final DateTime timestamp;
  final bool isTyping;
  final String? error;
  final Uint8List? imageBytes;
  final PendingAction? pendingAction; // Action awaiting confirmation
  final bool isActionHandled; // Whether pending action has been handled
  final String? modelName; // AI model name (e.g., "gemini-2.5-flash", "gpt-4o-mini")

  ChatMessage({
    required this.id,
    required this.content,
    required this.isFromUser,
    required this.timestamp,
    this.isTyping = false,
    this.error,
    this.imageBytes,
    this.pendingAction,
    this.isActionHandled = false,
    this.modelName,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isFromUser,
    DateTime? timestamp,
    bool? isTyping,
    String? error,
    Uint8List? imageBytes,
    PendingAction? pendingAction,
    bool? isActionHandled,
    String? modelName,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isFromUser: isFromUser ?? this.isFromUser,
      timestamp: timestamp ?? this.timestamp,
      isTyping: isTyping ?? this.isTyping,
      error: error ?? this.error,
      imageBytes: imageBytes ?? this.imageBytes,
      pendingAction: pendingAction ?? this.pendingAction,
      isActionHandled: isActionHandled ?? this.isActionHandled,
      modelName: modelName ?? this.modelName,
    );
  }

  /// Check if this message has unhandled pending action
  bool get hasPendingAction => pendingAction != null && !isActionHandled;
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isTyping;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isTyping = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isTyping,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isTyping: isTyping ?? this.isTyping,
      error: error ?? this.error,
    );
  }
}
