import 'dart:convert';

import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:axiomos_workforce/constants/app_strings.dart';
import 'package:axiomos_workforce/services/location_service.dart';
import 'package:axiomos_workforce/services/shared_preferences.dart';

//for dev login nev config----------------------------------------
Future<bool> isTokenValid() async {
  String? token = await SharedPrefService().getString("token");
  String user = await SharedPrefService().getString("userDetails") ?? "";
  final userDetails = jsonDecode(user);
  Strings.locationName = await LocationService().determineLocationName() ?? "";
  if (token != null && !JwtDecoder.isExpired(token)) {
    Map<String, dynamic>? decodedData = JwtDecoder.tryDecode(token);
    Strings.userId = userDetails["_id"] ?? "";
    var assignedRole = userDetails["role"];
    Strings.endpointToList["userDetails"] = userDetails;
    // List<dynamic> roles = await ApiService().getRequest("role");
    // List<dynamic> users = await ApiService().getRequest("user");

    var userName = userDetails;

    if (userName != null) {
      Strings.userName = userName["name"];
      print("dbhjdshbhnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn${userName["project"]}");
      Strings.endpointToList["mappedProjects"] = userName["project"];
      Strings.endpointToList["project"] = userName["project"][0];
    }

    if (assignedRole != null) {
      // Store roleName and permissions in variables
      Strings.roleName = assignedRole["roleName"];
      Strings.permisssions = List<String>.from(assignedRole["permissions"]);
    } else {
      print("Role not found");
    }

    return true;
  } else {
    return false;
  }
}





//for prod just testing purpose---------------------------
// Future<bool> isTokenValid() async {
//   String? token = await SharedPrefService().getString("token");
//   Strings.locationName = await LocationService().determineLocationName() ?? "";
//   if (token != null && !JwtDecoder.isExpired(token)) {
//     Map<String, dynamic>? decodedData = JwtDecoder.tryDecode(token);
//     Strings.userId = decodedData?["userId"] ?? "";
//     String role = decodedData?["role"] ?? "";

//     List<dynamic> roles = await ApiService().getRequest("role");
//     List<dynamic> users = await ApiService().getRequest("user");

//     var userName =
//         users.firstWhere((e) => e["_id"] == Strings.userId, orElse: () => null);

//     var assignedRole =
//         roles.firstWhere((e) => e["_id"] == role, orElse: () => null);
//     if (userName != null) {
//       Strings.endpointToList["userDetails"] = userName;
//       Strings.userName = userName["name"];
//       print("dbhjdshbhnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn${userName["project"]}");
//       Strings.endpointToList["mappedProjects"] = userName["project"];
//       Strings.endpointToList["project"] = userName["project"][0];
//     }

//     if (assignedRole != null) {
//       // Store roleName and permissions in variables
//       Strings.roleName = assignedRole["roleName"];
//       Strings.permisssions = List<String>.from(assignedRole["permissions"]);
//     } else {
//       print("Role not found");
//     }

//     return true;
//   } else {
//     return false;
//   }
// }