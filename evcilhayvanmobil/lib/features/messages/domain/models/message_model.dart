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
    return Message(
      id: json['_id'] ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      sender: json['sender'] != null
          ? User.fromJson(json['sender'])
          : User(id: '', name: 'Bilinmeyen', email: '', role: ''),
      text: json['text'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
