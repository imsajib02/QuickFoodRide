import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {

  static Database database;
  static const String DATABASE_NAME = "QuickRideSharing.db";
  static const String TABLE_ROUTE_PATH = "RoutePath";
  static const int DB_VERSION = 1;
  static const List<String> TABLE_ROUTE_PATH_COLUMNS = <String> ['id', 'position'];


  Future<Database> get db async {

    if(database != null) {
      return database;
    }
    else {
      database = await _initDB();
      return database;
    }
  }


  _initDB() async {

    final dirPath = await getDatabasesPath();
    final dbPath = join(dirPath, DATABASE_NAME);

    var db = await openDatabase(dbPath, version: DB_VERSION, onConfigure: _onConfigure, onCreate: _onCreate);
    return db;
  }


  _onCreate(Database db, int version) async {

    String sql = "CREATE TABLE $TABLE_ROUTE_PATH (" + TABLE_ROUTE_PATH_COLUMNS[0] + " INTEGER PRIMARY KEY AUTOINCREMENT, " + TABLE_ROUTE_PATH_COLUMNS[1] + " TEXT)";
    await db.execute(sql);
  }


  _onConfigure(Database db) async {
    await db.rawQuery("PRAGMA journal_mode = PERSIST");
  }


  Future<void> storePath(Position position) async {

    var dbClient = await db;

    Map<String, dynamic> value = {
      TABLE_ROUTE_PATH_COLUMNS[1]: json.encode(position.toJson())
    };

    dbClient.transaction((txn) async {

      await txn.insert(TABLE_ROUTE_PATH, value);
    });
  }


  Future<List<LatLng>> getTotalRoutePath() async {

    List<LatLng> paths = [];

    var dbClient = await db;

    dbClient.transaction((txn) async {

      List<Map> list = await txn.query(TABLE_ROUTE_PATH, columns: [TABLE_ROUTE_PATH_COLUMNS[1]]);

      if(list.length > 0) {

        for(int i=0; i<list.length; i++) {

          Position position = Position.fromMap(json.decode(list[i]['position']));
          paths.add(LatLng(position.latitude, position.longitude));
        }
      }
    });

    return paths;
  }


  Future<void> clearRoutePath() async {

    var dbClient = await db;

    dbClient.transaction((txn) async {

      txn.delete(TABLE_ROUTE_PATH);
    });
  }


  Future close() async {

    var dbClient = await db;
    dbClient.close();
  }
}