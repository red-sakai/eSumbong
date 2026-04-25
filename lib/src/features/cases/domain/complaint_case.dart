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
    this.evidenceUrls = const <String>[],
    this.noShowCount = 0,
    this.cfaGenerated = false,
    this.cfaRecord,
  });

  final String id;
  final String createdByUserId;
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

  ComplaintCase copyWith({
    String? id,
    String? createdByUserId,
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
