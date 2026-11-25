import 'package:flutter/foundation.dart';

/// Supported provider protocols in Muvio.
enum AddonKind { stremio, nuvio }

@immutable
class AddonCatalogDef {
  const AddonCatalogDef({
    required this.type,
    required this.id,
    required this.name,
    this.genres = const [],
    this.searchSupported = false,
  });

  factory AddonCatalogDef.fromJson(Map<String, dynamic> json) {
    final rawExtra = json['extra'];
    final genres = <String>[];
    var searchSupported = false;

    if (rawExtra is List) {
      for (final item in rawExtra) {
        if (item is Map<String, dynamic>) {
          final extraName = item['name']?.toString() ?? '';
          if (extraName == 'search') {
            searchSupported = true;
          }
          if (extraName == 'genre' && item['options'] is List) {
            for (final opt in item['options'] as List) {
              if (opt != null) genres.add(opt.toString());
            }
          }
        }
      }
    }

    if (json['extraSupported'] is List) {
      final supported =
          (json['extraSupported'] as List).map((e) => e.toString()).toList();
      if (supported.contains('search')) searchSupported = true;
    }

    return AddonCatalogDef(
      type: json['type']?.toString() ?? 'movie',
      id: json['id']?.toString() ?? 'top',
      name: json['name']?.toString() ?? json['id']?.toString() ?? 'Catalog',
      genres: genres,
      searchSupported: searchSupported,
    );
  }

  final String type;
  final String id;
  final String name;
  final List<String> genres;
  final bool searchSupported;

  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'name': name,
        'genres': genres,
        'searchSupported': searchSupported,
      };
}

@immutable
class AddonManifest {
  const AddonManifest({
    required this.id,
    required this.version,
    required this.name,
    required this.description,
    required this.resources,
    required this.types,
    required this.catalogs,
    this.idPrefixes = const [],
    this.logo,
    this.background,
    this.behaviorHints = const {},
    this.kind = AddonKind.stremio,
  });

  factory AddonManifest.fromJson(
    Map<String, dynamic> json, {
    AddonKind kind = AddonKind.stremio,
  }) {
    final id = json['id']?.toString().trim() ?? '';
    final name = json['name']?.toString().trim() ?? '';
    if (id.isEmpty || name.isEmpty) {
      throw const FormatException('Manifest invalide: id ou name manquant.');
    }

    final resources = <String>[];
    final rawResources = json['resources'] ?? json['capabilities'];
    if (rawResources is List) {
      for (final res in rawResources) {
        if (res is String) {
          resources.add(res);
        } else if (res is Map<String, dynamic> && res['name'] != null) {
          resources.add(res['name'].toString());
        }
      }
    }

    final types = <String>[];
    if (json['types'] is List) {
      for (final t in json['types'] as List) {
        if (t != null) types.add(t.toString());
      }
    }

    final catalogs = <AddonCatalogDef>[];
    if (json['catalogs'] is List) {
      for (final c in json['catalogs'] as List) {
        if (c is Map<String, dynamic>) {
          catalogs.add(AddonCatalogDef.fromJson(c));
        }
      }
    }

    final prefixes = <String>[];
    if (json['idPrefixes'] is List) {
      for (final p in json['idPrefixes'] as List) {
        if (p != null) prefixes.add(p.toString());
      }
    }

    final hints = json['behaviorHints'] is Map<String, dynamic>
        ? json['behaviorHints'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return AddonManifest(
      id: id,
      version: json['version']?.toString() ?? '1.0.0',
      name: name,
      description: json['description']?.toString() ?? '',
      resources: resources,
      types: types.isEmpty ? const ['movie', 'series'] : types,
      catalogs: catalogs,
      idPrefixes: prefixes,
      logo: json['logo']?.toString() ?? json['icon']?.toString(),
      background: json['background']?.toString(),
      behaviorHints: hints,
      kind: kind,
    );
  }

  final String id;
  final String version;
  final String name;
  final String description;
  final List<String> resources;
  final List<String> types;
  final List<AddonCatalogDef> catalogs;
  final List<String> idPrefixes;
  final String? logo;
  final String? background;
  final Map<String, dynamic> behaviorHints;
  final AddonKind kind;

  bool supportsResource(String resource) => resources.contains(resource);

  Map<String, dynamic> toJson() => {
        'id': id,
        'version': version,
        'name': name,
        'description': description,
        'resources': resources,
        'types': types,
        'catalogs': catalogs.map((c) => c.toJson()).toList(),
        'idPrefixes': idPrefixes,
        'logo': logo,
        'background': background,
        'behaviorHints': behaviorHints,
        'kind': kind.name,
      };
}

/// Installed or proposed addon state with circuit-breaker health tracking.
@immutable
class InstalledAddon {
  const InstalledAddon({
    required this.id,
    required this.manifestUrl,
    required this.manifest,
    required this.installed,
    required this.enabled,
    this.failureCount = 0,
    this.accentColorHex = 0xFFE50914,
    this.shortBadge = 'ADD',
    this.categoryLabel = 'Films & Séries',
  });

  final String id;
  final String manifestUrl;
  final AddonManifest manifest;
  final bool installed;
  final bool enabled;
  final int failureCount;
  final int accentColorHex;
  final String shortBadge;
  final String categoryLabel;

  /// Circuit breaker: addon marked offline after 3 consecutive failures.
  bool get isOffline => failureCount >= 3;

  String get baseUrl {
    if (manifestUrl.endsWith('/manifest.json')) {
      return manifestUrl.substring(
        0,
        manifestUrl.length - '/manifest.json'.length,
      );
    }
    return manifestUrl;
  }

  InstalledAddon copyWith({
    bool? installed,
    bool? enabled,
    int? failureCount,
    AddonManifest? manifest,
  }) {
    return InstalledAddon(
      id: id,
      manifestUrl: manifestUrl,
      manifest: manifest ?? this.manifest,
      installed: installed ?? this.installed,
      enabled: enabled ?? this.enabled,
      failureCount: failureCount ?? this.failureCount,
      accentColorHex: accentColorHex,
      shortBadge: shortBadge,
      categoryLabel: categoryLabel,
    );
  }
}
