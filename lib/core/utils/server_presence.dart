enum ServerPresenceStatus { online, offline, unknown }

ServerPresenceStatus getServerPresence(dynamic lastSeenAt) {
  if (lastSeenAt == null) {
    return ServerPresenceStatus.unknown;
  }

  DateTime? seenAt;

  if (lastSeenAt is String) {
    seenAt = DateTime.tryParse(lastSeenAt)?.toLocal();
  } else if (lastSeenAt is int) {
    seenAt = DateTime.fromMillisecondsSinceEpoch(lastSeenAt * 1000).toLocal();
  }

  if (seenAt == null) {
    return ServerPresenceStatus.unknown;
  }

  final diff = DateTime.now().difference(seenAt);

  if (diff.inSeconds <= 30) {
    return ServerPresenceStatus.online;
  }

  return ServerPresenceStatus.offline;
}

String serverPresenceLabel(dynamic lastSeenAt) {
  switch (getServerPresence(lastSeenAt)) {
    case ServerPresenceStatus.online:
      return 'online';
    case ServerPresenceStatus.offline:
      return 'offline';
    case ServerPresenceStatus.unknown:
      return 'unknown';
  }
}

String serverPresenceLabelRu(dynamic lastSeenAt) {
  switch (getServerPresence(lastSeenAt)) {
    case ServerPresenceStatus.online:
      return 'Онлайн';
    case ServerPresenceStatus.offline:
      return 'Офлайн';
    case ServerPresenceStatus.unknown:
      return 'Нет данных';
  }
}
