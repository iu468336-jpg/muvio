import 'package:muvio/data/models/addon_models.dart';
import 'package:muvio/data/models/media_models.dart';

part 'seed_addons.dart';
part 'seed_movies.dart';

/// Rich cinematic catalog seed ensuring crisp artwork, zero broken links,
/// and instant first-boot experience matching the 7 UI mockups.
class SeedCatalogData {
  const SeedCatalogData._();

  static const String sampleVideoHls =
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4';

  static const String sampleVideoBackup =
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4';

  static const String sampleVideoSciFi =
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';

  static const List<MediaItem> heroItems = [
    MediaItem(
      id: 'tt_eclipse_muvio',
      type: 'movie',
      title: 'ÉCLIPSE',
      poster:
          'https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=900&q=80',
      backdrop:
          'https://images.unsplash.com/photo-1462331940025-496dfbfc7564?auto=format&fit=crop&w=1400&q=85',
      synopsis:
          'Dans un futur où la lumière s’est éteinte, une découverte pourrait tout changer.',
      year: 2026,
      rating: 8.9,
      genres: ['Sci-Fi', 'Drame', 'Action'],
      cast: [
        'Louis Garrel',
        'Sofia Boutella',
        'Cillian Murphy',
        'Adèle Exarchopoulos'
      ],
      runtime: '2h 28m',
      isOriginal: true,
      isNewRelease: true,
    ),
    MediaItem(
      id: 'tt15239678',
      type: 'movie',
      title: 'Dune: Part Two',
      poster: 'https://image.tmdb.org/t/p/w780/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
      backdrop:
          'https://image.tmdb.org/t/p/w1280/xOMo8BRK7PfcJv9JCnx7s5hj0PX.jpg',
      synopsis:
          'Paul Atréides s’unit à Chani et aux Fremen tout en préparant sa revanche contre les conspirateurs qui ont détruit sa famille.',
      year: 2024,
      rating: 8.6,
      genres: ['Sci-Fi', 'Action', 'Drame'],
      cast: [
        'Timothée Chalamet',
        'Zendaya',
        'Rebecca Ferguson',
        'Javier Bardem'
      ],
      runtime: '2h 46m',
    ),
    MediaItem(
      id: 'tt0816692',
      type: 'movie',
      title: 'Interstellar',
      poster: 'https://image.tmdb.org/t/p/w780/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
      backdrop:
          'https://image.tmdb.org/t/p/w1280/xJHokMbljvjADYdit5fK5VQsXEG.jpg',
      synopsis:
          'Une équipe d’explorateurs franchit un trou de ver dans l’espace pour assurer la survie de l’humanité.',
      year: 2014,
      rating: 8.7,
      genres: ['Sci-Fi', 'Drame'],
      cast: [
        'Matthew McConaughey',
        'Anne Hathaway',
        'Jessica Chastain',
        'Michael Caine'
      ],
      runtime: '2h 49m',
    ),
    MediaItem(
      id: 'tt2788316',
      type: 'series',
      title: 'Shōgun',
      poster: 'https://image.tmdb.org/t/p/w780/7O4iVfOMQmdCSxhOg1WnzG1AgYT.jpg',
      backdrop:
          'https://image.tmdb.org/t/p/w1280/5zmiBoMzeeVdQ62no55JOJMY498.jpg',
      synopsis:
          'En l’an 1600 au Japon, le seigneur Yoshii Toranaga lutte pour sa survie alors que ses ennemis du Conseil des Régents s’unissent contre lui.',
      year: 2024,
      rating: 8.8,
      genres: ['Drame', 'Action'],
      cast: ['Hiroyuki Sanada', 'Cosmo Jarvis', 'Anna Sawai'],
      runtime: '10 épisodes',
      episodes: [
        EpisodeVideo(
          id: 'tt2788316:1:1',
          title: 'Anjin',
          season: 1,
          episode: 1,
          overview: 'Un navire européen échoue sur les côtes du Japon féodal.',
        ),
        EpisodeVideo(
          id: 'tt2788316:1:7',
          title: 'Un bâton d’encens',
          season: 1,
          episode: 7,
          overview: 'Toranaga est acculé par de nouvelles alliances.',
        ),
      ],
    ),
  ];

  static const List<MediaItem> catalogItems = _seedCatalogItems;

  static List<InstalledAddon> defaultProposedAddons() =>
      _defaultProposedAddons();

  static List<StreamSource> fallbackStreamsFor(MediaItem item) =>
      _fallbackStreamsFor(item);
}
