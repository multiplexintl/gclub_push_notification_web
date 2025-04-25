import 'package:flutter/material.dart';

import 'segment.dart';

@immutable
class Audience {
  final int? totalCount;
  final int? offset;
  final int? limit;
  final List<Segment>? segments;

  const Audience({this.totalCount, this.offset, this.limit, this.segments});

  @override
  String toString() {
    return 'Audience(totalCount: $totalCount, offset: $offset, limit: $limit, segments: $segments)';
  }

  factory Audience.fromJson(Map<String, dynamic> json) => Audience(
        totalCount: json['total_count'] as int?,
        offset: json['offset'] as int?,
        limit: json['limit'] as int?,
        segments: (json['segments'] as List<dynamic>?)
            ?.map((e) => Segment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'total_count': totalCount,
        'offset': offset,
        'limit': limit,
        'segments': segments?.map((e) => e.toJson()).toList(),
      };
}
