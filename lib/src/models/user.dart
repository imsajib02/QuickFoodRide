import '../models/media.dart';
import '../models/address.dart';
import 'dart:convert';

class User {
  String id;
  String name;
  String email;
  String password;
  String apiToken;
  String deviceToken;
  String phone;
  int roleID;
  String address;
  String bio;
  Media image;
  Address defaultAddress;


  // used for indicate if client logged in or not
  bool auth;

//  String role;

  User();

  User.fromJSON(Map<String, dynamic> jsonMap) {
    try {
      id = jsonMap['id'].toString();
      name = jsonMap['name'] != null ? jsonMap['name'] : '';
      email = jsonMap['email'] != null ? jsonMap['email'] : '';
      apiToken = jsonMap['api_token'];
      deviceToken = jsonMap['device_token'];
      roleID = jsonMap['role_id'] ?? 0;
      try {
        phone = jsonMap['custom_fields']['phone']['view'];
      } catch (e) {
        phone = "";
      }
      try {
        defaultAddress = jsonMap['delivery_address'] == null ? Address() : Address.fromJSON(jsonMap['delivery_address']);
        address = defaultAddress == null ? "" : defaultAddress.address;
      } catch (e) {
        defaultAddress = Address();
        address = "";
      }
      try {
        bio = jsonMap['custom_fields']['bio']['view'];
      } catch (e) {
        bio = "";
      }
      image = jsonMap['media'] != null && (jsonMap['media'] as List).length > 0 ? Media.fromJSON(jsonMap['media'][0]) : new Media();
      image.url = jsonMap['avatar'] == null ? image.url : jsonMap['avatar'];
    } catch (e) {
      print(e);
    }
  }

  Map toMap() {
    var map = new Map<String, dynamic>();
    map["id"] = id;
    map["email"] = email;
    map["name"] = name;
    map["role_id"] = 4;
    map["password"] = password;
    map["api_token"] = apiToken;
    if (deviceToken != null) {
      map["device_token"] = deviceToken;
    }
    map["phone"] = phone;
    map["address"] = address;
    map["bio"] = bio;
    map["delivery_address"] = defaultAddress?.toMap();
    map["media"] = image?.toMap();
    return map;
  }

  Map toUpdate() {
    var map = new Map<String, dynamic>();
    map["id"] = id;
    map["email"] = email;
    map["name"] = name;
    map["role_id"] = 4;
    map["password"] = password;
    map["api_token"] = apiToken;
    map["phone"] = phone;
    map["address"] = address;
    map["bio"] = bio;
    map["delivery_address"] = defaultAddress?.toMap();
    map["media"] = image?.toMap();
    return map;
  }

  toJsonFormat() {

    List<Media> mediaList = List();
    mediaList.add(image);

    return {
      "id" : id,
      "email" : email,
      "name" : name,
      "role_id" : 4,
      "password" : password,
      "api_token" : apiToken,
      "deviceToken" : deviceToken == null ? "" : deviceToken,
      "phone" : phone,
      "address" : address,
      "bio" : bio,
      "delivery_address" : defaultAddress?.toJsonFormat(),
      "media" : mediaList.map((media) => media.toJsonFormat()).toList(),
    };
  }

  @override
  String toString() {
    var map = this.toMap();
    map["auth"] = this.auth;
    return map.toString();
  }

  bool profileCompleted() {
    return address != null && address != '' && email != null && email != '';
  }
}
