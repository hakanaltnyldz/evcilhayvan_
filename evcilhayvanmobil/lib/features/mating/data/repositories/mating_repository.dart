// lib/features/mating/data/repositories/mating_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/http.dart';
import '../../domain/models/mating_profile.dart';

/// Filters used when querying the matching backend.
@immutable
class MatingQuery {
  final String? species;
  final String? gender;
  final double? maxDistanceKm;

  const MatingQuery({
    this.species,
    this.gender,
    this.maxDistanceKm,
  });

  MatingQuery copyWith({
    String? species,
    String? gender,
    double? maxDistanceKm,
  }) {
    return MatingQuery(
      species: species ?? this.species,
      gender: gender ?? this.gender,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    if (species != null && species!.isNotEmpty) {
      params['species'] = species;
    }
    if (gender != null && gender!.isNotEmpty) {
      params['gender'] = gender;
    }
    if (maxDistanceKm != null && maxDistanceKm! > 0) {
      params['maxDistanceKm'] = maxDistanceKm;
    }
    return params;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatingQuery &&
        other.species == species &&
        other.gender == gender &&
        other.maxDistanceKm == maxDistanceKm;
  }

  @override
  int get hashCode => Object.hash(species, gender, maxDistanceKm);
}

class MatchRequestResult {
  final bool success;
  final bool didMatch;
  final String message;

  const MatchRequestResult({
    required this.success,
    required this.didMatch,
    required this.message,
  });

  factory MatchRequestResult.fromJson(Map<String, dynamic> json) {
    final successValue = json['success'];
    final didMatchValue =
        json['match'] ?? json['didMatch'] ?? json['isMatch'] ?? false;
    final messageValue = json['message'] ??
        (didMatchValue == true
            ? 'Tebrikler! Yeni bir eşleşme oluştu.'
            : 'Eşleşme isteği gönderildi.');

    return MatchRequestResult(
      success: successValue is bool ? successValue : true,
      didMatch: didMatchValue == true,
      message: messageValue.toString(),
    );
  }
}

final matingRepositoryProvider = Provider<MatingRepository>((ref) {
  final dio = HttpClient().dio;
  return MatingRepository(dio);
});

final matingProfilesProvider =
    FutureProvider.autoDispose.family<List<MatingProfile>, MatingQuery>(
  (ref, query) async {
    final repository = ref.watch(matingRepositoryProvider);
    return repository.fetchProfiles(query: query);
  },
);

class MatingRepository {
  final Dio _dio;

  MatingRepository(this._dio);

  Future<List<MatingProfile>> fetchProfiles({
    MatingQuery query = const MatingQuery(),
  }) async {
    try {
      final response = await _dio.get(
        '/api/matching/profiles',
        queryParameters: query.toQueryParameters(),
      );

      final data = response.data;
      final List<dynamic> rawList =
          (data['profiles'] as List?) ?? (data['items'] as List?) ??
              (data['data'] as List?) ?? const [];

      return rawList
          .whereType<Map<String, dynamic>>()
          .map(MatingProfile.fromJson)
          .toList();
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['message']?.toString() ?? 'Veri alınamadı.')
          : e.message ?? 'Veri alınamadı.';
      throw Exception('Eşleşme listesi alınamadı: $message');
    }
  }

  Future<MatchRequestResult> sendMatchRequest(String profileId) async {
    try {
      final response = await _dio.post('/api/matching/request/$profileId');
      final data = response.data as Map<String, dynamic>? ?? <String, dynamic>{};
      return MatchRequestResult.fromJson(data);
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['message']?.toString() ?? 'Eşleşme isteği başarısız')
          : e.message ?? 'Eşleşme isteği başarısız';
      throw Exception(message);
    }
  }
}