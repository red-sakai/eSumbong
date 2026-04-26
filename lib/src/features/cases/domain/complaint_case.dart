import 'case_event.dart';
import 'case_status.dart';
import 'cfa_record.dart';

class ComplaintCase {
  const ComplaintCase({
    required this.id,
    required this.createdByUserId,
    this.createdByPhone = '',
    required this.complainantName,
    required this.respondentName,
    this.respondentPhone = '',
    required this.description,
    required this.incidentDate,
    required this.status,
    required this.events,
    this.evidenceUrls = const <String>[],
    this.noShowCount = 0,
    this.cfaGenerated = false,
    this.cfaDeclined = false,
    this.cfaRecord,
  });

  final String id;
  final String createdByUserId;
  /// Phone number or email of the user who filed this case.
  /// Used as a stable identifier across anonymous auth re-logins.
  final String createdByPhone;
  final String complainantName;
  final String respondentName;
  /// E.164-formatted respondent phone used by the UniSMS demo flow.
  final String respondentPhone;
  final String description;
  final DateTime incidentDate;
  final CaseStatus status;
  final List<CaseEvent> events;
  final List<String> evidenceUrls;
  final int noShowCount;
  final bool cfaGenerated;
  final bool cfaDeclined;
  final CfaRecord? cfaRecord;
  
  /// Returns the date the case was filed, based on the first event.
  DateTime get filingDate {
    if (events.isEmpty) return incidentDate;
    final filedEvent = events.firstWhere(
      (e) => e.title.contains('Case Filed'),
      orElse: () => events.first,
    );
    return filedEvent.timestamp;
  }

  /// Whether a CFA should be automatically generated based on business rules.
  bool get shouldAutoGenerateCfa {
    if (cfaGenerated) return false;
    if (status == CaseStatus.dismissed) return false;
    
    // Rule 1: 3 no-shows (Still automatic)
    if (noShowCount >= 3) return true;
    
    return false;
  }

  /// Whether a staff member needs to approve CFA generation for this case.
  bool get isCfaApprovalPending {
    if (cfaGenerated || cfaDeclined) return false;
    if (status == CaseStatus.dismissed) return false;

    // Rule 2: Older than 30 days (Manual approval required)
    final age = DateTime.now().difference(filingDate).inDays;
    return age >= 30;
  }

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
      cfaDeclined: json['cfaDeclined'] as bool? ?? false,
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
        'cfaDeclined': cfaDeclined,
        if (cfaRecord != null) 'cfaRecord': cfaRecord!.toJson(),
      };

  ComplaintCase copyWith({
    String? id,
    String? createdByUserId,
    String? createdByPhone,
    String? complainantName,
    String? respondentName,
    String? respondentPhone,
    String? description,
    DateTime? incidentDate,
    CaseStatus? status,
    List<CaseEvent>? events,
    List<String>? evidenceUrls,
    int? noShowCount,
    bool? cfaGenerated,
    bool? cfaDeclined,
    CfaRecord? cfaRecord,
  }) {
    return ComplaintCase(
      id: id ?? this.id,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByPhone: createdByPhone ?? this.createdByPhone,
      complainantName: complainantName ?? this.complainantName,
      respondentName: respondentName ?? this.respondentName,
      respondentPhone: respondentPhone ?? this.respondentPhone,
      description: description ?? this.description,
      incidentDate: incidentDate ?? this.incidentDate,
      status: status ?? this.status,
      events: events ?? this.events,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      noShowCount: noShowCount ?? this.noShowCount,
      cfaGenerated: cfaGenerated ?? this.cfaGenerated,
      cfaDeclined: cfaDeclined ?? this.cfaDeclined,
      cfaRecord: cfaRecord ?? this.cfaRecord,
    );
  }
}
