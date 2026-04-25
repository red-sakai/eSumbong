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
}
