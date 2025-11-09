// lib/features/pets/domain/models/pet_model.dart

class PetOwner {
  final String id;
  final String name;
  final String? avatarUrl;

  PetOwner({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  factory PetOwner.fromJson(Map<String, dynamic> json) {
    return PetOwner(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Bilinmeyen Kullanıcı',
      avatarUrl: json['avatarUrl'] ?? '',
    );
  }
}

class Pet {
  final String id;
  final PetOwner? owner;
  final String name;
  final String species;
  final String breed;
  final String gender;
  final int ageMonths;
  final String? bio;
  final List<String> photos;
  final bool vaccinated;
  final Map<String, dynamic> location;
  final double? latitude;
  final double? longitude;
  final bool isActive;

  const Pet({
    required this.id,
    this.owner,
    required this.name,
    required this.species,
    required this.breed,
    required this.gender,
    required this.ageMonths,
    this.bio,
    required this.photos,
    required this.vaccinated,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.isActive,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> defaultLocation = {
      'type': 'Point',
      'coordinates': [0.0, 0.0],
    };

    final locationData = json['location'];
    Map<String, dynamic> locationMap = defaultLocation;
    double? latitude;
    double? longitude;

    if (locationData is Map<String, dynamic>) {
      locationMap = Map<String, dynamic>.from(locationData);
      final coords = locationData['coordinates'];
      if (coords is List && coords.length >= 2) {
        longitude = _parseDouble(coords[0]);
        latitude = _parseDouble(coords[1]);
      }
    }

    final ageValue = json['ageMonths'];
    final int parsedAge = ageValue is int
        ? ageValue
        : ageValue is String
            ? int.tryParse(ageValue) ?? 0
            : 0;

    final photosList = (json['photos'] as List?)
            ?.whereType<String>()
            .toList(growable: false) ??
        const <String>[];

    return Pet(
      id: json['_id'] ?? '',
      owner: json['ownerId'] != null
          ? PetOwner.fromJson(json['ownerId'])
          : null,
      name: json['name']?.toString() ?? 'Bilinmeyen Evcil',
      species: json['species']?.toString() ?? 'Bilinmiyor',
      breed: json['breed']?.toString() ?? 'Bilinmiyor',
      gender: json['gender']?.toString() ?? 'Bilinmiyor',
      photos: photosList,
      ageMonths: parsedAge,
      bio: json['bio']?.toString(),
      vaccinated: json['vaccinated'] == true,
      location: locationMap,
      latitude: latitude,
      longitude: longitude,
      isActive: json['isActive'] != false,
    );
  }
}

double? _parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
