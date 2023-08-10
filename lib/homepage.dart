import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:myjournal/sql_helper.dart';
import 'package:intl/intl.dart';
import 'package:myjournal/stats.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //Logs
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  Color primaryColor = Color.fromARGB(255, 255, 111, 0);
  Color secondaryColor = Color.fromARGB(255, 255, 125, 49);

  String fontStyle = 'Arvo';

  double weeklyAvg = 0.0;

  List<double> week = [0, 0, 0, 0, 0, 0, 0];

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  //Fetches data from database
  void _refreshLogs() async {
    final data = await SQLHelper.getLogs();
    setState(() {
      _logs = data;
      _isLoading = false;
    });
  }

  Future<void> _addLog() async {
    double weight = double.tryParse(_weightController.text) ?? 0.0;
    String notes = _noteController.text;
    await SQLHelper.addLog(weight, notes);
    _refreshLogs();
  }

  void _deleteLog(int id) async {
    await SQLHelper.deleteLog(id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Log deleted.',
            style: TextStyle(
                fontFamily: fontStyle, color: Colors.black, fontSize: 18)),
        backgroundColor: secondaryColor));

    _refreshLogs();
  }

  Future<void> _calculateAvg() async {
    double avg = await SQLHelper.calculateAverageWeight();

    setState(() {
      weeklyAvg = avg;
    });
  }

  Future<void> _weeklyLog() async {
    setState(() async {
      for (int i = 0; i < 6; i++) {
        week[0] = await SQLHelper.getWeight(i);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshLogs(); // Load in all logs
  }

  @override
  void dispose() {
    _noteController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _showForm(int? id) async {
    // update existing log
    if (id != null) {
      final existingLog = _logs.firstWhere((element) => element['id'] == id);
      _weightController.text = existingLog['weight'];
      _noteController.text = existingLog['notes'];
    } else {
      showModalBottomSheet(
          context: context,
          elevation: 5,
          isScrollControlled: true,
          builder: (_) => Container(
                color: secondaryColor,
                padding: EdgeInsets.only(
                  top: 15,
                  left: 15,
                  right: 15,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: _weightController,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Weight',
                        hintStyle: TextStyle(fontFamily: fontStyle),
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 15.0, horizontal: 20.0), // Adjust padding
                        filled: true,
                        fillColor: Colors.white, // Set the background color
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Notes',
                        hintStyle: TextStyle(fontFamily: fontStyle),
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 15.0, horizontal: 20.0), // Adjust padding
                        filled: true,
                        fillColor: Colors.white, // Set the background color
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white),
                      onPressed: () async {
                        await _addLog();

                        _calculateAvg();

                        _weeklyLog();

                        _weightController.clear();
                        _noteController.clear();

                        if (!mounted) return;
                        Navigator.of(context).pop();
                      },
                      child: Text('Add',
                          style:
                              TextStyle(fontSize: 20, fontFamily: fontStyle)),
                    )
                  ],
                ),
              ));
    }
  }

  Widget _logView() => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        child: ListView.builder(
          itemCount: _logs.length,
          itemBuilder: (context, index) {
            final weight = _logs[index]['weight'] as double;
            final notes = _logs[index]['notes'] ?? '';
            final currentDate = DateTime.parse(_logs[index][
                'currentDate']); // Assuming you're storing the date as a String
            final formattedDate =
                DateFormat('MMM dd, yyyy').format(currentDate);
            return Card(
              elevation: 3.0,
              color: secondaryColor,
              margin: const EdgeInsets.all(15),
              child: GestureDetector(
                onTap: () {
                  if (notes != '') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          notes,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: fontStyle,
                          ),
                        ),
                        backgroundColor: secondaryColor,
                      ),
                    );
                  }
                },
                child: ListTile(
                  title: Text(
                    weight.toString() + ' lbs',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontSize: 25,
                      fontFamily: fontStyle,
                    ),
                  ),
                  subtitle: Text(
                    formattedDate,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: fontStyle,
                    ),
                  ),
                  trailing: SizedBox(
                    width: 30,
                    child: IconButton(
                        icon: const Icon(Icons.clear, color: Colors.black),
                        onPressed: () {
                          _deleteLog(_logs[index]['id']);

                          _calculateAvg();
                        }),
                  ),
                ),
              ),
            );
          },
        ),
      );

  Widget _dashboard() => Material(
        elevation: 3.0, // Adjust the elevation value as needed
        borderRadius: BorderRadius.circular(15.0),
        child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            width: MediaQuery.of(context).size.width - 30,
            decoration: BoxDecoration(
              color: secondaryColor,
              borderRadius:
                  BorderRadius.circular(15.0), // Adjust the radius as needed
            ),
            child: Center(
                child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.02,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    width: double.infinity,
                    height: 300,
                    child: LineChart(
                      LineChartData(
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(spots: [
                              FlSpot(1, week[0]),
                              FlSpot(2, week[1]),
                              FlSpot(3, week[2]),
                              FlSpot(4, week[3]),
                              FlSpot(5, week[4]),
                              FlSpot(6, week[5]),
                              FlSpot(7, week[6]),
                            ])
                          ]),
                    ),
                  ),
                  Text(
                    '${weeklyAvg.toStringAsFixed(1)} lbs',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontSize: 30,
                      fontFamily: fontStyle,
                    ),
                  ),
                  Text(
                    'weekly avg.',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: fontStyle,
                    ),
                  ),
                ],
              ),
            ))),
      );

  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(widget.title,
            style: TextStyle(
                fontWeight: FontWeight.w300,
                color: Colors.black,
                fontSize: 30,
                fontFamily: fontStyle)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _dashboard(),
                _logView(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(null),
        tooltip: 'Add Log',
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(30.0), // Adjust the value for roundness
        ),
      ),
    );
  }
}
