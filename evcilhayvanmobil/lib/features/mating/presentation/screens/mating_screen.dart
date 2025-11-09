// lib/features/mating/presentation/screens/mating_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvanmobil/core/theme/app_palette.dart';
import 'package:evcilhayvanmobil/core/widgets/modern_background.dart';
import 'package:evcilhayvanmobil/features/mating/data/repositories/mating_repository.dart';
import 'package:evcilhayvanmobil/features/mating/domain/models/mating_profile.dart';

class MatingScreen extends ConsumerStatefulWidget {
  const MatingScreen({super.key});

  @override
  ConsumerState<MatingScreen> createState() => _MatingScreenState();
}

class _MatingScreenState extends ConsumerState<MatingScreen> {
  final List<String> _species = const ['Tümü', 'Köpek', 'Kedi', 'Kuş'];
  String _selectedSpecies = 'Tümü';
  String _selectedGender = 'Tümü';
  double _maxDistance = 20;
  final Set<String> _requestingProfiles = <String>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = MatingQuery(
      species: _selectedSpecies == 'Tümü' ? null : _selectedSpecies,
      gender: _selectedGender == 'Tümü' ? null : _selectedGender,
      maxDistanceKm: _maxDistance,
    );

    final profilesAsync = ref.watch(matingProfilesProvider(filters));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Eşleşme Bul'),
      ),
      body: ModernBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evcil dostların için uygun eşleşmeleri keşfet.',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _FilterChips(
                  label: 'Tür',
                  values: _species,
                  selectedValue: _selectedSpecies,
                  onSelected: (value) => setState(() => _selectedSpecies = value),
                ),
                const SizedBox(height: 12),
                _FilterChips(
                  label: 'Cinsiyet',
                  values: const ['Tümü', 'Erkek', 'Dişi'],
                  selectedValue: _selectedGender,
                  onSelected: (value) => setState(() => _selectedGender = value),
                ),
                const SizedBox(height: 12),
                Text(
                  'Maksimum mesafe: ${_maxDistance.round()} km',
                  style: theme.textTheme.bodyMedium,
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: theme.colorScheme.primary,
                    inactiveTrackColor:
                        theme.colorScheme.primary.withOpacity(0.15),
                    thumbColor: theme.colorScheme.secondary,
                    overlayColor: theme.colorScheme.secondary.withOpacity(0.12),
                  ),
                  child: Slider(
                    value: _maxDistance,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: '${_maxDistance.round()} km',
                    onChanged: (value) => setState(() => _maxDistance = value),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: profilesAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stackTrace) => _ErrorState(
                      message: error.toString(),
                      onRetry: () => ref.invalidate(matingProfilesProvider(filters)),
                    ),
                    data: (profiles) {
                      final filtered = profiles.where((profile) {
                        final matchesSpecies = _selectedSpecies == 'Tümü' ||
                            profile.species == _selectedSpecies;
                        final matchesGender = _selectedGender == 'Tümü' ||
                            profile.gender == _selectedGender;
                        final matchesDistance =
                            profile.distanceKm <= _maxDistance;
                        return matchesSpecies &&
                            matchesGender &&
                            matchesDistance;
                      }).toList();

                      if (filtered.isEmpty) {
                        return const _EmptyState();
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(matingProfilesProvider(filters));
                          try {
                            await ref.read(
                              matingProfilesProvider(filters).future,
                            );
                          } catch (_) {}
                        },
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final profile = filtered[index];
                            final isRequesting =
                                _requestingProfiles.contains(profile.id);
                            return _ProfileCard(
                              profile: profile,
                              isRequesting: isRequesting,
                              onDetails: () => _openDetails(profile),
                              onRequestMatch: () =>
                                  _requestMatch(profile, filters: filters),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDetails(MatingProfile profile) async {
    if (!mounted) return;
    if (profile.petId.isEmpty) {
      _showSnackBar('İlan detayı açılamadı.', isError: true);
      return;
    }
    context.pushNamed(
      'pet-detail',
      pathParameters: {'id': profile.petId},
    );
  }

  Future<void> _requestMatch(
    MatingProfile profile, {
    required MatingQuery filters,
  }) async {
    if (_requestingProfiles.contains(profile.id)) {
      return;
    }
    setState(() {
      _requestingProfiles.add(profile.id);
    });

    final repository = ref.read(matingRepositoryProvider);
    try {
      final targetId = profile.id.isNotEmpty ? profile.id : profile.petId;
      final result = await repository.sendMatchRequest(targetId);
      if (!mounted) return;
      _showSnackBar(result.message, isError: !result.success);
      if (result.success || result.didMatch) {
        ref.invalidate(matingProfilesProvider(filters));
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _requestingProfiles.remove(profile.id);
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String label;
  final List<String> values;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const _FilterChips({
    required this.label,
    required this.values,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: values.map((value) {
            final isSelected = value == selectedValue;
            return FilterChip(
              label: Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onSelected(value),
              showCheckmark: false,
              backgroundColor: theme.colorScheme.surface,
              selectedColor: theme.colorScheme.primary,
              side: BorderSide(
                color: isSelected
                    ? Colors.transparent
                    : theme.colorScheme.primary.withOpacity(0.12),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final MatingProfile profile;
  final bool isRequesting;
  final VoidCallback onDetails;
  final VoidCallback onRequestMatch;

  const _ProfileCard({
    required this.profile,
    required this.isRequesting,
    required this.onDetails,
    required this.onRequestMatch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.12),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(
          color: AppPalette.primary.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: _ProfileImage(imageUrl: profile.primaryImageUrl),
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        profile.gender,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${profile.breed} · ${profile.formattedAge}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.map_outlined,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${profile.distanceKmRounded} km yakınında',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDetails,
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Detaylar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isRequesting || profile.hasPendingRequest
                            ? null
                            : onRequestMatch,
                        icon: isRequesting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.favorite_outline),
                        label: Text(
                          profile.hasPendingRequest
                              ? 'İstek gönderildi'
                              : profile.isMatched
                                  ? 'Eşleşti'
                                  : 'Eşleşme iste',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 60, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Filtreleri gevşetmeyi deneyin',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Yakınında henüz uygun eşleşme bulunamadı.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 60, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Bir sorun oluştu',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  final String imageUrl;

  const _ProfileImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (imageUrl.isEmpty) {
      return _placeholder(theme);
    }

    return Image.network(
      imageUrl,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _placeholder(theme),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: 180,
          width: double.infinity,
          color: theme.colorScheme.surfaceVariant,
          alignment: Alignment.center,
          child: CircularProgressIndicator(
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded /
                    progress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      height: 180,
      width: double.infinity,
      color: theme.colorScheme.surfaceVariant,
      alignment: Alignment.center,
      child: Icon(
        Icons.pets,
        size: 48,
        color: theme.colorScheme.onSurface.withOpacity(0.5),
      ),
    );
  }
}