// lib/features/messages/domain/models/message_model.dart

import '../../../auth/domain/user_model.dart';

class Message {
  final String id;
  final String conversationId;
  final User sender;
  final String text;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.text,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final senderData = json['sender'];

    return Message(
      id: json['_id'] ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      sender: senderData is Map<String, dynamic>
          ? User.fromJson(senderData)
          : senderData is String
              ? User.fromJson({'_id': senderData})
              : User.fromJson({}),
      text: json['text'] ?? '',
      createdAt: _parseDateTime(json['createdAt']),
    );
  }
}

DateTime _parseDateTime(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is double) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  return DateTime.now();
}
