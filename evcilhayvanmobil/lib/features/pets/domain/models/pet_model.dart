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
  final bool isActive;

  Pet({
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
    required this.isActive,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> defaultLocation = {
      'type': 'Point',
      'coordinates': [0.0, 0.0],
    };

    return Pet(
      id: json['_id'] ?? '',
      owner: json['ownerId'] != null
          ? PetOwner.fromJson(json['ownerId'])
          : null,
      name: json['name'] ?? 'Bilinmeyen Evcil',
      species: json['species'] ?? 'Bilinmiyor',
      breed: json['breed'] ?? 'Bilinmiyor',
      gender: json['gender'] ?? 'Bilinmiyor',
      photos: List<String>.from(json['photos'] ?? []),
      ageMonths: (json['ageMonths'] ?? 0) is int
          ? json['ageMonths']
          : int.tryParse(json['ageMonths'].toString()) ?? 0,
      bio: json['bio'],
      vaccinated: json['vaccinated'] ?? false,
      location: json['location'] ?? defaultLocation,
      isActive: json['isActive'] ?? true,
    );
  }
}
