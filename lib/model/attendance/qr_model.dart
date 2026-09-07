class WorkerQrData {
  final int version;
  final String id;
  final String labourCode;
  final String firstName;
  final String lastName;
  final String field5;
  final String skill;
  final String bloodGroup;
  final String mobile;
  final String nationality;
  final String contractorId;
  final String contractorName;
  final String projectId;
  final String projectName;
  final String locationId;
  final String locationName;
  final String date;
  final String field17;
  final String address;

  WorkerQrData({
    required this.version,
    required this.id,
    required this.labourCode,
    required this.firstName,
    required this.lastName,
    required this.field5,
    required this.skill,
    required this.bloodGroup,
    required this.mobile,
    required this.nationality,
    required this.contractorId,
    required this.contractorName,
    required this.projectId,
    required this.projectName,
    required this.locationId,
    required this.locationName,
    required this.date,
    required this.field17,
    required this.address,
  });

  factory WorkerQrData.fromJson(List<dynamic> json) {
    return WorkerQrData(
      version: json[0] as int,
      id: json[1] as String,
      labourCode: json[2] as String,
      firstName: json[3] as String,
      lastName: json[4] as String,
      field5: json[5] as String,
      skill: json[6] as String,
      bloodGroup: json[7] as String,
      mobile: json[8] as String,
      nationality: json[9] as String,
      contractorId: json[10] as String,
      contractorName: json[11] as String,
      projectId: json[12] as String,
      projectName: json[13] as String,
      locationId: json[14] as String,
      locationName: json[15] as String,
      date: json[16] as String,
      field17: json[17] as String,
      address: json[18] as String,
    );
  }
}