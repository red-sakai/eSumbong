enum CaseStatus {
  pending,
  summonsSent,
  hearingScheduled,
  failedMediation,
  completed,
  dismissed,
}

extension CaseStatusX on CaseStatus {
  String get label {
    switch (this) {
      case CaseStatus.pending:
        return 'Pending';
      case CaseStatus.summonsSent:
        return 'Summons Sent';
      case CaseStatus.hearingScheduled:
        return 'Hearing Scheduled';
      case CaseStatus.failedMediation:
        return 'Failed Mediation';
      case CaseStatus.completed:
        return 'Completed';
      case CaseStatus.dismissed:
        return 'Dismissed';
    }
  }
}
