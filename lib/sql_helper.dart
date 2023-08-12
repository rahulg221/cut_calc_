import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;

class SQLHelper {
  static Future<void> createTables(sql.Database database) async {
    await database.execute(
        """CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, weight REAL, notes TEXT, currentDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)""");
  }

  static Future<sql.Database> db() async {
    return sql.openDatabase(
      'weightTracker.db', version: 2, // Increment the version number
      onCreate: (sql.Database database, int version) async {
        await createTables(database);
      },
      onUpgrade: (sql.Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE items ADD COLUMN notes TEXT');
        }
      },
    );
  }

  static Future<int> addLog(double weight, String notes) async {
    final db = await SQLHelper.db();

    final data = {'weight': weight, 'notes': notes};
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

  static Future<double> getWeight(int id) async {
    final db = await SQLHelper.db();
    final result = await db.query('items',
        columns: ['weight'], where: "id = ?", whereArgs: [id], limit: 1);

    if (result.isNotEmpty) {
      return result.first['weight'] as double;
    }

    return 0.0; // Default value if the result is empty
  }

  static Future<List<Map<String, dynamic>>> getWeeklyLogs() async {
    final db = await SQLHelper.db();
    return db.query('items',
        orderBy: "id DESC", limit: 7); // Fetch the last 7 entries
  }

  static Future<List<Map<String, dynamic>>> getWeeklyChart() async {
    final db = await SQLHelper.db();
    return db.query('items',
        orderBy: "id ASC", limit: 7); // Fetch the last 7 entries
  }

  static Future<List<FlSpot>> getData() async {
    List<FlSpot> dataPts = [];

    int index = 0;
    double spotIndex = 8;
    final logs = await getWeeklyChart();

    for (var log in logs) {
      dataPts.insert(index, FlSpot(index + 1, log['weight']));
      index++;
      spotIndex--;
    }

    return dataPts;
  }

  static Future<double> calculateAverageWeight() async {
    final logs = await getWeeklyLogs();
    if (logs.isEmpty) {
      return 0.0; // Default value if there are no logs
    }

    double totalWeight = 0;
    for (var log in logs) {
      totalWeight += log['weight'] as double;
    }

    return totalWeight / logs.length;
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
//notes: additional notes
//currentDate: date logged on
