
class RiderType {

  String id;
  String name;
  String fee;
  String adminCommission;
  String cancelFee;
  String icon;
  String markerIcon;
  String speed;
  bool isActive;
  bool isNidRequired;
  bool isLicenseRequired;

  RiderType({this.id, this.name, this.fee, this.cancelFee, this.isActive});

  RiderType.fromJSON(Map<String, dynamic> jsonMap) {
    try {
      id = jsonMap['id'].toString();
      name = jsonMap['name'] ?? "";
      fee = jsonMap['ride_fee'] ?? "6";
      adminCommission = jsonMap['commision'] ?? "0";
      icon = jsonMap['icon'];
      markerIcon = jsonMap['marker_icon'];
      speed = jsonMap['speed'];
      cancelFee = jsonMap['ride_cancalation_fee'] ?? "0";
      isActive = jsonMap['is_active'] != null && jsonMap['is_active'] == "1" ? true : false;
      isNidRequired = jsonMap['is_nid_required'] != null && jsonMap['is_nid_required'] == "1" ? true : false;
      isLicenseRequired = jsonMap['is_license_required'] != null && jsonMap['is_license_required'] == "1" ? true : false;
    } catch (e) {
      print(e);
    }
  }

  Map toMap() {
    var map = new Map<String, dynamic>();
    map["id"] = id;
    map["name"] = name;
    map["ride_fee"] = fee;
    map["commision"] = adminCommission;
    map["icon"] = icon;
    map["ride_cancalation_fee"] = cancelFee;
    map["is_active"] = isActive ? "1" : "2";
    map["is_nid_required"] = isNidRequired ? "1" : "2";
    map["is_license_required"] = isLicenseRequired ? "1" : "2";
    return map;
  }
}

class RiderTypes {

  List<RiderType> list;

  RiderTypes({this.list});

  RiderTypes.fromJson(Map<String, dynamic> json) {

    list = List();

    if(json['riderTypes'] != null) {

      json['riderTypes'].forEach((type) {

        list.add(RiderType.fromJSON(type));
      });
    }
  }
}
