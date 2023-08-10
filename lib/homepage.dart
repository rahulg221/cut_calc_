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
  List<double> weeklyLogs = [180, 179, 181];

  Color primaryColor = Color.fromARGB(255, 255, 111, 0);
  Color secondaryColor = Color.fromARGB(255, 255, 125, 49);

  String fontStyle = 'Arvo';

  //Fetches data from database
  void _refreshLogs() async {
    final data = await SQLHelper.getLogs();
    setState(() {
      _logs = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshLogs(); // Load in all logs
  }

  final TextEditingController _weightController = TextEditingController();

  void _showForm(int? id) async {
    // update existing log
    if (id != null) {
      final existingLog = _logs.firstWhere((element) => element['id'] == id);
      _weightController.text = existingLog['weight'];
    } else {
      showModalBottomSheet(
          context: context,
          elevation: 5,
          isScrollControlled: true,
          builder: (_) => Container(
              color: Colors.black,
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
                      hintText: 'Enter weight',
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
                  TextButton(
                    onPressed: () async {
                      await _addLog();

                      _weightController.text = '';

                      if (!mounted) return;
                      Navigator.of(context).pop();
                    },
                    child: Text('Add',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: fontStyle)),
                  )
                ],
              )));
    }
  }

  Future<void> _addLog() async {
    double weight = double.tryParse(_weightController.text) ?? 0.0;
    await SQLHelper.addLog(weight);
    _refreshLogs();
  }

  void _deleteLog(int id) async {
    await SQLHelper.deleteLog(id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Log deleted.', style: TextStyle(fontFamily: fontStyle)),
      backgroundColor: Colors.black,
    ));

    _refreshLogs();
  }

  Widget _logView() => ListView.builder(
        itemCount: _logs.length,
        itemBuilder: (context, index) {
          final weight = _logs[index]['weight'] as double;
          final currentDate = DateTime.parse(_logs[index]
              ['currentDate']); // Assuming you're storing the date as a String
          final formattedDate = DateFormat('MMM dd, yyyy').format(currentDate);

          return Card(
            color: secondaryColor,
            margin: const EdgeInsets.all(15),
            child: ListTile(
                title: Text(weight.toString() + ' lbs',
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        fontSize: 25,
                        fontFamily: fontStyle)),
                subtitle: Text(formattedDate,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: fontStyle)),
                trailing: SizedBox(
                    width: 30,
                    child: IconButton(
                      icon: const Icon(Icons.clear, color: Colors.black),
                      onPressed: () => _deleteLog(_logs[index]['id']),
                    ))),
          );
        },
      );

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(widget.title,
            style: TextStyle(
                fontWeight: FontWeight.w300,
                color: Colors.black,
                fontSize: 30,
                fontFamily: fontStyle)),
        actions: [
          IconButton(
            onPressed: () {
              // Navigate to the other page
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MyStatsPage(
                          title: 'Stats',
                          weeklyLogs: [1, 2, 3],
                        )),
              );
            },
            icon: Icon(Icons.insert_chart,
                color: Colors.black,
                size: 25), // Wrap the icon with Icon widget
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logView(),
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
