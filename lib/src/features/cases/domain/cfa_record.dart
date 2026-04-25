class CfaRecord {
  const CfaRecord({
    required this.certificateNumber,
    required this.issuedAt,
    required this.signatoryName,
    required this.qrPayload,
    required this.verificationHash,
  });

  final String certificateNumber;
  final DateTime issuedAt;
  final String signatoryName;
  final String qrPayload;
  final String verificationHash;

  factory CfaRecord.fromJson(Map<String, dynamic> json) => CfaRecord(
        certificateNumber: json['certificateNumber'] as String? ?? '',
        issuedAt:
            DateTime.tryParse(json['issuedAt'] as String? ?? '') ??
            DateTime.now(),
        signatoryName: json['signatoryName'] as String? ?? '',
        qrPayload: json['qrPayload'] as String? ?? '',
        verificationHash: json['verificationHash'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'certificateNumber': certificateNumber,
        'issuedAt': issuedAt.toIso8601String(),
        'signatoryName': signatoryName,
        'qrPayload': qrPayload,
        'verificationHash': verificationHash,
      };
}
