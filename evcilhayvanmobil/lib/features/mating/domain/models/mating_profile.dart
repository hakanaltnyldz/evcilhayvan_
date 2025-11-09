// lib/features/mating/domain/models/mating_profile.dart

import 'package:meta/meta.dart';

@immutable
class MatingProfile {
  final String id;
  final String petId;
  final String name;
  final String species;
  final String breed;
  final String gender;
  final double distanceKm;
  final int ageMonths;
  final String? bio;
  final List<String> imageUrls;
  final bool hasPendingRequest;
  final bool isMatched;

  const MatingProfile({
    required this.id,
    required this.petId,
    required this.name,
    required this.species,
    required this.breed,
    required this.gender,
    required this.distanceKm,
    required this.ageMonths,
    required this.imageUrls,
    this.bio,
    this.hasPendingRequest = false,
    this.isMatched = false,
  });

  factory MatingProfile.fromJson(Map<String, dynamic> json) {
    final petJson = (json['pet'] as Map<String, dynamic>?) ?? json;

    final id = (json['id'] ?? petJson['id'] ?? json['_id'] ?? petJson['_id'])
        ?.toString();
    final petId =
        (json['petId'] ?? petJson['id'] ?? petJson['_id'] ?? id)?.toString();

    final List<dynamic>? imagesJson =
        (petJson['images'] as List?) ?? (json['images'] as List?);

    String? extractImage(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is Map<String, dynamic>) {
        return value['url']?.toString() ?? value['secure_url']?.toString();
      }
      return value.toString();
    }

    final imageUrls = <String>[];
    for (final item in imagesJson ?? const []) {
      final url = extractImage(item);
      if (url != null && url.isNotEmpty) {
        imageUrls.add(url);
      }
    }

    final coverImage = extractImage(
      petJson['coverImage'] ?? json['coverImage'] ?? json['avatar'],
    );
    if (coverImage != null && coverImage.isNotEmpty) {
      imageUrls.insert(0, coverImage);
    }

    double parseDistance(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value.toString());
      return parsed ?? 0;
    }

    int parseAgeMonths(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.round();
      final parsed = int.tryParse(value.toString());
      return parsed ?? 0;
    }

    return MatingProfile(
      id: id ?? petId ?? '',
      petId: petId ?? id ?? '',
      name: (petJson['name'] ?? json['name'] ?? 'İlan').toString(),
      species: (petJson['species'] ?? json['species'] ?? 'Tümü').toString(),
      breed: (petJson['breed'] ?? json['breed'] ?? 'Bilinmiyor').toString(),
      gender: (petJson['gender'] ?? json['gender'] ?? 'Bilinmiyor').toString(),
      distanceKm: parseDistance(
        json['distanceKm'] ?? json['distance'] ?? json['distance_km'],
      ),
      ageMonths: parseAgeMonths(
        petJson['ageMonths'] ?? petJson['age'] ?? json['ageMonths'],
      ),
      bio: (petJson['bio'] ?? json['bio'])?.toString(),
      imageUrls: imageUrls,
      hasPendingRequest:
          (json['hasPendingRequest'] ?? json['requested'] ?? false) == true,
      isMatched: (json['match'] ?? json['isMatch'] ?? false) == true,
    );
  }

  String get primaryImageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  String get formattedAge {
    if (ageMonths <= 0) return 'Yaş bilgisi yok';
    if (ageMonths < 12) {
      return '${ageMonths} aylık';
    }
    final years = ageMonths ~/ 12;
    final remainingMonths = ageMonths % 12;
    if (remainingMonths == 0) {
      return '$years yaş';
    }
    return '$years yaş ${remainingMonths} aylık';
  }

  double get distanceKmRounded => double.parse(distanceKm.toStringAsFixed(1));
}