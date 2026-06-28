class CccdData {
  final String cccdNumber;
  final String oldIdNumber;
  final String fullName;
  final String dateOfBirth;
  final String gender;
  final String permanentAddress;
  final String issueDate;
  final String hometown;

  const CccdData({
    this.cccdNumber = '',
    this.oldIdNumber = '',
    this.fullName = '',
    this.dateOfBirth = '',
    this.gender = '',
    this.permanentAddress = '',
    this.issueDate = '',
    this.hometown = '',
  });

  CccdData copyWith({
    String? cccdNumber,
    String? oldIdNumber,
    String? fullName,
    String? dateOfBirth,
    String? gender,
    String? permanentAddress,
    String? issueDate,
    String? hometown,
  }) {
    return CccdData(
      cccdNumber: cccdNumber ?? this.cccdNumber,
      oldIdNumber: oldIdNumber ?? this.oldIdNumber,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      issueDate: issueDate ?? this.issueDate,
      hometown: hometown ?? this.hometown,
    );
  }

  List<String> toSheetRow(String scanDate) => [
        cccdNumber,
        oldIdNumber,
        fullName,
        dateOfBirth,
        gender,
        permanentAddress,
        issueDate,
        hometown,
        scanDate,
      ];

  Map<String, dynamic> toJson() => {
        'cccdNumber': cccdNumber,
        'oldIdNumber': oldIdNumber,
        'fullName': fullName,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'permanentAddress': permanentAddress,
        'issueDate': issueDate,
        'hometown': hometown,
      };

  factory CccdData.fromJson(Map<String, dynamic> j) => CccdData(
        cccdNumber: j['cccdNumber'] ?? '',
        oldIdNumber: j['oldIdNumber'] ?? '',
        fullName: j['fullName'] ?? '',
        dateOfBirth: j['dateOfBirth'] ?? '',
        gender: j['gender'] ?? '',
        permanentAddress: j['permanentAddress'] ?? '',
        issueDate: j['issueDate'] ?? '',
        hometown: j['hometown'] ?? '',
      );
}
