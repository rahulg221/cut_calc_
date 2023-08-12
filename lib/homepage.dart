import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:myjournal/sql_helper.dart';
import 'package:intl/intl.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  //Logs
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  double maxY = 300;
  double minY = 0;
  double max_X = 2;
  double min_X = 0;
  //Color.fromARGB(255, 255, 111, 0);
  Color primaryColor = Colors.white;

  //Color.fromARGB(255, 255, 125, 49);
  Color secondaryColor = Color.fromARGB(255, 36, 185, 253);

  String fontStyle = 'Arvo';

  double weeklyAvg = 0.0;

  List<FlSpot> dataPoints = [];

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  int index = 0;
  //Fetches data from database
  void _refreshLogs() async {
    final data = await SQLHelper.getLogs();
    List<FlSpot> dataPts = [];
    dataPts = await SQLHelper.getData();
    double count = await SQLHelper.getRecordCount();

    setState(() {
      _logs = data;
      _isLoading = false;
      dataPoints = dataPts;
      max_X = count + 1;

      _calculateAvg();
    });
  }

  Future<void> _addLog() async {
    double weight = double.tryParse(_weightController.text) ?? 0.0;
    String notes = _noteController.text;
    await SQLHelper.addLog(weight, notes);
    print('max x: $max_X');

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

      if (weeklyAvg > 0) {
        maxY = ((weeklyAvg + 10) / 10).ceil() * 10;
        minY = ((weeklyAvg - 10) / 10).floor() * 10;
      } else if (weeklyAvg == 0) {
        maxY = 300;
        minY = 0;
      }
    });
  }

  Future<void> _setMaxX() async {
    final count = await SQLHelper.getRecordCount;
    print('count: $count');
    /* if (count != 0) {
      setState(() {
        //maxX = count as double;
        maxX++;
      });
    }*/
  }

  @override
  void initState() {
    super.initState();
    _refreshLogs(); // Load in all logs
    //_setMaxX();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _weightController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    SQLHelper.closeDatabase(); // Call closeDatabase when disposing of the page
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      print('Paused');
      SQLHelper
          .closeDatabase(); // Call closeDatabase when the app goes inactive or paused
    }
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

                        _weightController.clear();
                        _noteController.clear();

                        if (!mounted) return;
                        Navigator.of(context).pop();
                      },
                      child: Text('Add',
                          style:
                              TextStyle(fontSize: 16, fontFamily: fontStyle)),
                    )
                  ],
                ),
              ));
    }
  }

  Widget _logView() => Container(
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
              margin:
                  const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
              child: ListTile(
                title: Text(
                  weight.toString() + ' lbs',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: fontStyle,
                  ),
                ),
                subtitle: Text(
                  formattedDate,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: fontStyle,
                  ),
                ),
                trailing: SizedBox(
                  width: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      notes != ''
                          ? IconButton(
                              icon: const Icon(Icons.bookmark,
                                  color: Colors.black),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(
                                        'Notes',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                          fontSize: 20,
                                          fontFamily: fontStyle,
                                        ),
                                      ),
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
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop(); // Close the AlertDialog
                                          },
                                          child: Text(
                                            'Close',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                              fontSize: 16,
                                              fontFamily: fontStyle,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              })
                          : IconButton(
                              icon: Icon(Icons.bookmark_border,
                                  color: Colors.black),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(
                                        'Uh Oh!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                          fontSize: 20,
                                          fontFamily: fontStyle,
                                        ),
                                      ),
                                      content: Text(
                                        'No notes found for this entry.',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontFamily: fontStyle,
                                        ),
                                      ),
                                      backgroundColor: secondaryColor,
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop(); // Close the AlertDialog
                                          },
                                          child: Text(
                                            'Close',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                              fontSize: 16,
                                              fontFamily: fontStyle,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }),
                      IconButton(
                          icon: const Icon(Icons.clear, color: Colors.black),
                          onPressed: () {
                            _deleteLog(_logs[index]['id']);
                          }),
                    ],
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
            height: MediaQuery.of(context).size.height * 0.35,
            width: MediaQuery.of(context).size.width - 30,
            decoration: BoxDecoration(
              color: secondaryColor.withOpacity(0.6),
              borderRadius:
                  BorderRadius.circular(15.0), // Adjust the radius as needed
            ),
            child: Center(
                child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.008,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    width: double.infinity,
                    height: 200,
                    child: LineChart(
                      LineChartData(
                          maxX: max_X,
                          minY: minY,
                          maxY: maxY,
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            rightTitles: AxisTitles(
                                sideTitles: SideTitles(
                              showTitles: false,
                            )),
                            topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              color: Colors.black,
                              spots: dataPoints,
                            )
                          ]),
                    ),
                  ),
                  Text(
                    '${weeklyAvg.toStringAsFixed(1)} lbs',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontSize: 35,
                      fontFamily: fontStyle,
                    ),
                  ),
                  Text(
                    '7-day avg.',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontSize: 13,
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
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontSize: 25,
                fontFamily: fontStyle)),
        actions: [
          IconButton(
            onPressed: () async {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(
                      'Warning',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        fontSize: 20,
                        fontFamily: fontStyle,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to delete all your entries?',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: fontStyle,
                      ),
                    ),
                    backgroundColor: secondaryColor,
                    actions: <Widget>[
                      Row(
                        children: [
                          TextButton(
                            onPressed: () async {
                              await SQLHelper.deleteAllLogs();
                              _refreshLogs();
                              Navigator.of(context)
                                  .pop(); // Close the AlertDialog
                            },
                            child: Text(
                              'Yes',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                fontSize: 16,
                                fontFamily: fontStyle,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .pop(); // Close the AlertDialog
                            },
                            child: Text(
                              'No',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                fontSize: 16,
                                fontFamily: fontStyle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
            icon: Icon(Icons.delete_outline, size: 28, color: Colors.black),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _dashboard(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text('Entries',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            fontSize: 25,
                            fontFamily: fontStyle)),
                  ),
                ),
                Expanded(child: _logView()),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(null),
        tooltip: 'Add Log',
        child: Icon(Icons.edit, color: Colors.white),
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(30.0), // Adjust the value for roundness
        ),
      ),
    );
  }
}
