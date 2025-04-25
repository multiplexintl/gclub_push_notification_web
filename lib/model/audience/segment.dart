import 'package:flutter/material.dart';

@immutable
class Segment {
  final String? id;
  final String? name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? appId;
  final bool? readOnly;
  final bool? isActive;
  final dynamic source;
  final dynamic segmentStatus;
  final dynamic loadingStartedAt;
  final dynamic loadingCompletedAt;

  const Segment({
    this.id,
    this.name,
    this.createdAt,
    this.updatedAt,
    this.appId,
    this.readOnly,
    this.isActive,
    this.source,
    this.segmentStatus,
    this.loadingStartedAt,
    this.loadingCompletedAt,
  });

  @override
  String toString() {
    return 'Segment(id: $id, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, appId: $appId, readOnly: $readOnly, isActive: $isActive, source: $source, segmentStatus: $segmentStatus, loadingStartedAt: $loadingStartedAt, loadingCompletedAt: $loadingCompletedAt)';
  }

  factory Segment.fromJson(Map<String, dynamic> json) => Segment(
        id: json['id'] as String?,
        name: json['name'] as String?,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] == null
            ? null
            : DateTime.parse(json['updated_at'] as String),
        appId: json['app_id'] as String?,
        readOnly: json['read_only'] as bool?,
        isActive: json['is_active'] as bool?,
        source: json['source'] as dynamic,
        segmentStatus: json['segment_status'] as dynamic,
        loadingStartedAt: json['loading_started_at'] as dynamic,
        loadingCompletedAt: json['loading_completed_at'] as dynamic,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'app_id': appId,
        'read_only': readOnly,
        'is_active': isActive,
        'source': source,
        'segment_status': segmentStatus,
        'loading_started_at': loadingStartedAt,
        'loading_completed_at': loadingCompletedAt,
      };
}
