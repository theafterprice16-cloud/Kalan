import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Status values as written in assets/roadmap.json.
enum RoadmapStatus {
  planned('planned'),
  inProgress('in_progress'),
  shipped('shipped');

  const RoadmapStatus(this.json);
  final String json;
}

/// One roadmap entry. See docs/ROADMAP_CONTENT.md for the file format.
class RoadmapItem {
  const RoadmapItem({
    required this.id,
    required this.titleTr,
    required this.titleEn,
    required this.summaryTr,
    required this.summaryEn,
    required this.status,
    this.targetVersion,
  });

  /// Strict: any missing or malformed field throws [FormatException].
  factory RoadmapItem.fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('Roadmap item must be an object');
    }
    String text(Object? value, String field) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
      throw FormatException('Roadmap item field "$field" must be text');
    }

    Map<String, Object?> pair(String field) {
      final value = json[field];
      if (value is Map<String, Object?>) return value;
      throw FormatException('Roadmap item field "$field" needs tr and en');
    }

    final id = text(json['id'], 'id');
    final title = pair('title');
    final summary = pair('summary');
    final statusText = text(json['status'], 'status');
    final status = RoadmapStatus.values
        .where((s) => s.json == statusText)
        .firstOrNull;
    if (status == null) {
      throw FormatException('Unknown roadmap status "$statusText" for $id');
    }
    final target = json['targetVersion'];
    if (target != null && (target is! String || target.trim().isEmpty)) {
      throw FormatException('targetVersion of $id must be text');
    }
    return RoadmapItem(
      id: id,
      titleTr: text(title['tr'], 'title.tr'),
      titleEn: text(title['en'], 'title.en'),
      summaryTr: text(summary['tr'], 'summary.tr'),
      summaryEn: text(summary['en'], 'summary.en'),
      status: status,
      targetVersion: (target as String?)?.trim(),
    );
  }

  final String id;
  final String titleTr;
  final String titleEn;
  final String summaryTr;
  final String summaryEn;
  final RoadmapStatus status;
  final String? targetVersion;

  String title(String localeName) =>
      localeName.startsWith('tr') ? titleTr : titleEn;

  String summary(String localeName) =>
      localeName.startsWith('tr') ? summaryTr : summaryEn;
}

/// Parses the whole file: a JSON list of items with unique ids.
List<RoadmapItem> parseRoadmap(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! List<Object?>) {
    throw const FormatException('Roadmap file must be a JSON list');
  }
  final items = decoded.map(RoadmapItem.fromJson).toList();
  final ids = <String>{};
  for (final item in items) {
    if (!ids.add(item.id)) {
      throw FormatException('Duplicate roadmap id "${item.id}"');
    }
  }
  return items;
}

const roadmapAsset = 'assets/roadmap.json';

/// Raw file contents; overridden in tests.
final roadmapSourceProvider = FutureProvider<String>(
  (ref) => rootBundle.loadString(roadmapAsset),
);

final roadmapProvider = FutureProvider<List<RoadmapItem>>(
  (ref) async => parseRoadmap(await ref.watch(roadmapSourceProvider.future)),
);
