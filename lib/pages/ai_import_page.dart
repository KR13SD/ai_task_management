import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AiImportPage extends StatefulWidget {
  const AiImportPage({super.key});
  @override
  State<AiImportPage> createState() => _AiImportPageState();
}

class _AiImportPageState extends State<AiImportPage> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _previewTasks = [];

  Future<void> _generateTasks() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      Get.snackbar('Error', 'กรุณาใส่ข้อความ');
      return;
    }

    setState(() => _loading = true);
    try {
      // TODO: เรียก AiApiService.parseTasks(text, projectId, userId)
      // ตัวอย่าง mock:
      await Future.delayed(const Duration(seconds: 1));
      _previewTasks = [
        {'title': 'ทำ slide', 'priority': 'high', 'due_date': '2025-08-07'},
        {'title': 'โทรหาลูกค้า', 'priority': 'medium', 'due_date': '2025-08-08'},
      ];
    } catch (e) {
      Get.snackbar('AI Error', e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _saveToProject() {
    // TODO: บันทึก _previewTasks ลง Firestore (เรียก Task Controller)
    Get.snackbar('Saved', 'บันทึกงานเรียบร้อย (mock)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import from AI')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'วางข้อความประชุมที่นี่...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _generateTasks,
                    child: const Text('Generate Tasks'),
                  ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _previewTasks.length,
                itemBuilder: (context, i) {
                  final t = _previewTasks[i];
                  return Card(
                    child: ListTile(
                      title: Text(t['title']),
                      subtitle: Text('Priority: ${t['priority']} • Due: ${t['due_date']}'),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(onPressed: _previewTasks.isEmpty ? null : _saveToProject, child: const Text('Save to Project')),
          ],
        ),
      ),
    );
  }
}
