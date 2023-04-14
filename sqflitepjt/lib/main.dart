import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = openDatabase(
    join(await getDatabasesPath(), 'student_database.db'),
    onCreate: (db, version) {
      return db.execute(
        "CREATE TABLE students(id INTEGER PRIMARY KEY, name TEXT, age INTEGER)",
      );
    },
    version: 1,
  );
  runApp(MyApp(database: database));
}

class MyApp extends StatefulWidget {
  final Future<Database> database;

  const MyApp({Key? key, required this.database}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  Future<void> _addStudent() async {
    final db = await widget.database;

    await db.insert(
      'students',
      {'name': _nameController.text, 'age': int.parse(_ageController.text)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _nameController.clear();
    _ageController.clear();

    setState(() {});
  }

  Future<List<Map<String, dynamic>>> _getStudents() async {
    final db = await widget.database;

    return db.query('students');
  }

  Future<void> _deleteStudent(int id) async {
    final db = await widget.database;

    await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Database',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Student Database'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _addStudent,
              child: const Text('Add Student'),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _getStudents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    final students = snapshot.data ?? [];

                    return ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];

                        return ListTile(
                          title: Text(student['name']),
                          subtitle: Text('Age: ${student['age']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteStudent(student['id']),
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
