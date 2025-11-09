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
    final participants = json['participants'] as List? ?? [];
    final otherParticipantJson = participants.firstWhere(
      (p) => p['_id'] != currentUserId,
      orElse: () => participants.isNotEmpty ? participants.first : {},
    );

    final relatedPetData = json['relatedPet'];
    Pet? relatedPet;
    String? relatedPetId;

    if (relatedPetData is Map<String, dynamic>) {
      relatedPet = Pet.fromJson(relatedPetData);
      relatedPetId = relatedPetData['_id'];
    } else if (relatedPetData is String) {
      relatedPetId = relatedPetData;
    }

    return Conversation(
      id: json['_id'] ?? '',
      otherParticipant: User.fromJson(otherParticipantJson),
      relatedPet: relatedPet,
      relatedPetId: relatedPetId,
      lastMessage: json['lastMessage'] ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
