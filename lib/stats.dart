import 'package:flutter/material.dart';
import 'package:myjournal/sql_helper.dart';
import 'package:intl/intl.dart';
import 'package:myjournal/main.dart';
import 'package:fl_chart/fl_chart.dart';

class MyStatsPage extends StatefulWidget {
  const MyStatsPage({super.key, required this.title, required this.weeklyLogs});

  final String title;
  final List<double> weeklyLogs;

  @override
  State<MyStatsPage> createState() => _MyStatsPageState();
}

class _MyStatsPageState extends State<MyStatsPage> {
  Color primaryColor = Color.fromARGB(255, 255, 111, 0);
  Color secondaryColor = Color.fromARGB(255, 255, 125, 49);

  String fontStyle = 'Arvo';

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(widget.title,
            style: TextStyle(
                fontWeight: FontWeight.w300,
                color: Colors.black,
                fontSize: 25,
                fontFamily: fontStyle)),
      ),
      body: Text('Under construction'),
    );
  }
}
