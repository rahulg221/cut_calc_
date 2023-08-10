import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;

class SQLHelper {
  static Future<void> createTables(sql.Database database) async {
    await database.execute(
        """CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, weight REAL, currentDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)""");
  }

  static Future<sql.Database> db() async {
    return sql.openDatabase('weightTracker.db', version: 1,
        onCreate: (sql.Database database, int version) async {
      await createTables(database);
    });
  }

  static Future<int> addLog(double weight) async {
    final db = await SQLHelper.db();

    final data = {'weight': weight};
    final id = await db.insert('items', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  static Future<List<Map<String, dynamic>>> getLogs() async {
    final db = await SQLHelper.db();
    return db.query('items', orderBy: "id");
  }

  static Future<List<Map<String, dynamic>>> getLog(int id) async {
    final db = await SQLHelper.db();

    return db.query('items', where: "id = ?", whereArgs: [id], limit: 1);
  }

  static Future<void> deleteLog(int id) async {
    final db = await SQLHelper.db();

    try {
      await db.delete("items", where: "id = ?", whereArgs: [id]);
    } catch (err) {
      debugPrint("Error");
    }
  }
}

//id: id of entry
//weight: logged weight
//currentDate: date logged on


