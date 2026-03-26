import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Cache médias (images/vidéos/audio) pour le chat.
///
/// Objectif: après le 1er téléchargement, les ouvertures suivantes doivent être
/// quasi instantanées (fichier local).
final oklChatMediaCache = CacheManager(
  Config(
    'okliforChatMediaCache',
    stalePeriod: const Duration(days: 14),
    maxNrOfCacheObjects: 800,
  ),
);

