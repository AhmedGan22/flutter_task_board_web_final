import 'package:flutter/material.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'لوحة المهام',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TaskBoard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TaskBoard extends StatefulWidget {
  const TaskBoard({super.key});

  @override
  State<TaskBoard> createState() => _TaskBoardState();
}

class _TaskBoardState extends State<TaskBoard> {
  final TextEditingController _taskController = TextEditingController();

  List<List<String>> columns = [
    [], [], [], [], []
  ];

  final List<String> titles = [
    "💡 أفكار",
    "📋 ما أريد عمله",
    "🔧 قيد التنفيذ",
    "✅ تم إنجازه",
    "❌ لم يتم إنجازه",
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (int i = 0; i < columns.length; i++) {
        final data = prefs.getString('column_$i');
        if (data != null) {
          columns[i] = List<String>.from(jsonDecode(data));
        }
      }
    });
  }

  void _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < columns.length; i++) {
      prefs.setString('column_$i', jsonEncode(columns[i]));
    }
  }

  void _addTask(String task) {
    setState(() {
      columns[0].add(task);
      _taskController.clear();
      _saveData();
    });
  }

  void _showEditDialog(int listIndex, int itemIndex) {
    final editController = TextEditingController(text: columns[listIndex][itemIndex]);
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("تعديل المهمة"),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(labelText: "المحتوى الجديد"),
          ),
          actions: [
            TextButton(
              child: const Text("إلغاء"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("حفظ"),
              onPressed: () {
                setState(() {
                  columns[listIndex][itemIndex] = editController.text;
                  _saveData();
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📋 لوحة المهام")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      labelText: "أدخل مهمة جديدة في (أفكار)...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _addTask(_taskController.text),
                  child: const Text("إضافة"),
                )
              ],
            ),
          ),
          Expanded(
            child: DragAndDropLists(
              axis: Axis.horizontal,
              children: List.generate(columns.length, (i) {
                return DragAndDropList(
                  header: Container(
                    padding: const EdgeInsets.all(8),
                    child: Text(titles[i], style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  children: List.generate(columns[i].length, (j) {
                    return DragAndDropItem(
                      child: Card(
                        child: ListTile(
                          title: Text(columns[i][j]),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.orange),
                                onPressed: () {
                                  _showEditDialog(i, j);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    columns[i].removeAt(j);
                                    _saveData();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }),
              onItemReorder: (oldItemIndex, oldListIndex, newItemIndex, newListIndex) {
                setState(() {
                  final movedItem = columns[oldListIndex].removeAt(oldItemIndex);
                  columns[newListIndex].insert(newItemIndex, movedItem);
                  _saveData();
                });
              },
              onListReorder: (_, __) {},
              listWidth: 250,
              listPadding: const EdgeInsets.all(8),
            ),
          )
        ],
      ),
    );
  }
}