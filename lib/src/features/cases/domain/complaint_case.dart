import 'case_event.dart';
import 'case_status.dart';
import 'cfa_record.dart';

class ComplaintCase {
  const ComplaintCase({
    required this.id,
    required this.createdByUserId,
    required this.complainantName,
    required this.respondentName,
    required this.description,
    required this.incidentDate,
    required this.status,
    required this.events,
    this.createdByPhone = '',
    this.evidenceUrls = const <String>[],
    this.noShowCount = 0,
    this.cfaGenerated = false,
    this.cfaRecord,
  });

  final String id;
  final String createdByUserId;
  /// Phone number or email of the user who filed this case.
  /// Used as a stable identifier across anonymous auth re-logins.
  final String createdByPhone;
  final String complainantName;
  final String respondentName;
  final String description;
  final DateTime incidentDate;
  final CaseStatus status;
  final List<CaseEvent> events;
  final List<String> evidenceUrls;
  final int noShowCount;
  final bool cfaGenerated;
  final CfaRecord? cfaRecord;

  factory ComplaintCase.fromJson(String id, Map<String, dynamic> json) {
    final eventsRaw = json['events'] as List<dynamic>? ?? <dynamic>[];
    final cfaRaw = json['cfaRecord'] as Map<String, dynamic>?;
    final statusStr = json['status'] as String? ?? 'pending';
    return ComplaintCase(
      id: id,
      createdByUserId: json['createdByUserId'] as String? ?? '',
      createdByPhone: json['createdByPhone'] as String? ?? '',
      complainantName: json['complainantName'] as String? ?? '',
      respondentName: json['respondentName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      incidentDate:
          DateTime.tryParse(json['incidentDate'] as String? ?? '') ??
          DateTime.now(),
      status: CaseStatus.values.byName(statusStr),
      events: eventsRaw
          .map((e) => CaseEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      evidenceUrls:
          (json['evidenceUrls'] as List<dynamic>? ?? <dynamic>[])
              .cast<String>(),
      noShowCount: json['noShowCount'] as int? ?? 0,
      cfaGenerated: json['cfaGenerated'] as bool? ?? false,
      cfaRecord: cfaRaw != null ? CfaRecord.fromJson(cfaRaw) : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'createdByUserId': createdByUserId,
        'createdByPhone': createdByPhone,
        'complainantName': complainantName,
        'respondentName': respondentName,
        'description': description,
        'incidentDate': incidentDate.toIso8601String(),
        'status': status.name,
        'events': events.map((e) => e.toJson()).toList(),
        'evidenceUrls': evidenceUrls,
        'noShowCount': noShowCount,
        'cfaGenerated': cfaGenerated,
        if (cfaRecord != null) 'cfaRecord': cfaRecord!.toJson(),
      };

  ComplaintCase copyWith({
    String? id,
    String? createdByUserId,
    String? createdByPhone,
    String? complainantName,
    String? respondentName,
    String? description,
    DateTime? incidentDate,
    CaseStatus? status,
    List<CaseEvent>? events,
    List<String>? evidenceUrls,
    int? noShowCount,
    bool? cfaGenerated,
    CfaRecord? cfaRecord,
  }) {
    return ComplaintCase(
      id: id ?? this.id,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByPhone: createdByPhone ?? this.createdByPhone,
      complainantName: complainantName ?? this.complainantName,
      respondentName: respondentName ?? this.respondentName,
      description: description ?? this.description,
      incidentDate: incidentDate ?? this.incidentDate,
      status: status ?? this.status,
      events: events ?? this.events,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      noShowCount: noShowCount ?? this.noShowCount,
      cfaGenerated: cfaGenerated ?? this.cfaGenerated,
      cfaRecord: cfaRecord ?? this.cfaRecord,
    );
  }
}
