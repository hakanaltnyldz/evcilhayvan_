// lib/features/pets/presentation/widgets/pet_card.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:evcilhayvanmobil/core/http.dart';
import 'package:evcilhayvanmobil/core/theme/app_palette.dart';
import 'package:evcilhayvanmobil/features/pets/domain/models/pet_model.dart';

class PetCard extends StatefulWidget {
  final Pet pet;
  final VoidCallback onTap;

  const PetCard({
    super.key,
    required this.pet,
    required this.onTap,
  });

  @override
  State<PetCard> createState() => _PetCardState();
}

class _PetCardState extends State<PetCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final String ownerName = pet.owner?.name ?? '';
    final String avatarLetter = ownerName.isNotEmpty
        ? ownerName.substring(0, 1).toUpperCase()
        : '?';
    final heroTag = 'pet-image-${pet.id}';

    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      scale: _isPressed ? 0.97 : 1,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
        elevation: 10,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (value) {
            setState(() => _isPressed = value);
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PetImage(heroTag: heroTag, pet: pet),
              _PetInfoSection(
                pet: pet,
                ownerName: ownerName,
                avatarLetter: avatarLetter,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetImage extends StatelessWidget {
  final String heroTag;
  final Pet pet;

  const _PetImage({required this.heroTag, required this.pet});

  @override
  Widget build(BuildContext context) {
    final borderRadius = const BorderRadius.vertical(top: Radius.circular(20));

    return Stack(
      children: [
        Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: borderRadius,
              child: SizedBox(
                height: 210,
                width: double.infinity,
                child: pet.photos.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: '${apiBaseUrl}${pet.photos[0]}',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFE5E3FF),
                              Color(0xFFFDE4DF),
                            ],
                          ),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFE5E3FF),
                              Color(0xFFFDE4DF),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.pets,
                          size: 76,
                          color: AppPalette.primary.withOpacity(0.5),
                        ),
                      ),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFE5E3FF),
                            Color(0xFFFDE4DF),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.pets,
                        size: 76,
                        color: AppPalette.primary.withOpacity(0.5),
                      ),
                    ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.05),
                  Colors.black.withOpacity(0.45),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: _Badge(
            icon: Icons.category,
            label: pet.species,
          ),
        ),
        if (pet.vaccinated)
          Positioned(
            top: 16,
            right: 16,
            child: _Badge(
              icon: Icons.verified,
              label: 'Aşılı',
              backgroundColor: Colors.greenAccent.shade200,
              foregroundColor: Colors.green.shade900,
            ),
          ),
        Positioned(
          bottom: 18,
          left: 20,
          right: 20,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Text(
              pet.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    shadows: const [
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 6,
                        color: Colors.black38,
                      ),
                    ],
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PetInfoSection extends StatelessWidget {
  final Pet pet;
  final String ownerName;
  final String avatarLetter;

  const _PetInfoSection({
    required this.pet,
    required this.ownerName,
    required this.avatarLetter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.pets,
                label:
                    pet.breed.isNotEmpty ? pet.breed : 'Cins Bilinmiyor',
              ),
              _InfoChip(
                icon: Icons.cake_outlined,
                label: '${pet.ageMonths} ay',
              ),
              _InfoChip(
                icon: pet.gender.toLowerCase() == 'female'
                    ? Icons.female
                    : Icons.male,
                label: pet.gender,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.12),
                child: Text(
                  avatarLetter,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ownerName.isNotEmpty
                          ? 'İlan sahibi: $ownerName'
                          : 'Sahip bilgisi yok',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (pet.latitude != null && pet.longitude != null)
                      Text(
                        'Konum: ${pet.latitude!.toStringAsFixed(4)}, ${pet.longitude!.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppPalette.onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const _Badge({
    required this.icon,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = foregroundColor ??
        (backgroundColor == null ? Colors.white : Colors.black87);

    final decoration = BoxDecoration(
      gradient: backgroundColor == null
          ? LinearGradient(
              colors: [
                AppPalette.primary.withOpacity(0.92),
                AppPalette.secondary.withOpacity(0.88),
              ],
            )
          : null,
      color: backgroundColor?.withOpacity(0.9),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppPalette.primary.withOpacity(0.18),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: decoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fgColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.16),
              Theme.of(context).colorScheme.primary.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}