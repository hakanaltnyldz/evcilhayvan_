// lib/features/messages/domain/models/conversation_model.dart

import '../../../auth/domain/user_model.dart';
import '../../../pets/domain/models/pet_model.dart';

class Conversation {
  final String id;
  final User otherParticipant;
  final Pet? relatedPet;
  final String? relatedPetId;
  final String lastMessage;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.otherParticipant,
    this.relatedPet,
    this.relatedPetId,
    required this.lastMessage,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json, String currentUserId) {
    final participants = (json['participants'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const <Map<String, dynamic>>[];

    final otherParticipantJson = participants.firstWhere(
      (p) => (p['_id'] ?? p['id']) != currentUserId,
      orElse: () => participants.isNotEmpty ? participants.first : <String, dynamic>{},
    );

    final relatedPetData = json['relatedPet'];
    Pet? relatedPet;
    String? relatedPetId;

    if (relatedPetData is Map<String, dynamic>) {
      relatedPet = Pet.fromJson(relatedPetData);
      relatedPetId = relatedPetData['_id']?.toString();
    } else if (relatedPetData is String) {
      relatedPetId = relatedPetData;
    }

    final dynamic lastMessageData = json['lastMessage'];
    String lastMessageText = '';
    if (lastMessageData is Map<String, dynamic>) {
      lastMessageText = lastMessageData['text']?.toString() ?? '';
    } else if (lastMessageData is String) {
      lastMessageText = lastMessageData;
    }

    final updatedAt = _parseDateTime(
      json['updatedAt'] ??
          (lastMessageData is Map<String, dynamic>
              ? lastMessageData['createdAt'] ?? lastMessageData['updatedAt']
              : null),
    );

    return Conversation(
      id: json['_id']?.toString() ?? '',
      otherParticipant: User.fromJson(otherParticipantJson),
      relatedPet: relatedPet,
      relatedPetId: relatedPetId,
      lastMessage: lastMessageText,
      updatedAt: updatedAt,
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
