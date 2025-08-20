import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/dashboard_controller.dart';
import '../models/task_model.dart';

class TaskDetailPage extends StatefulWidget {
  final TaskModel task;
  const TaskDetailPage({super.key, required this.task});

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage>
    with TickerProviderStateMixin {
  late TextEditingController titleController;
  late String priority;
  late DateTime startDate;
  late DateTime endDate;
  late String status;
  late String editedPriority;
  late String editedStatus;
  late DateTime editedStartDate;
  late DateTime editedEndDate;
  final DashboardController controller = Get.find<DashboardController>();
  final dateFormat = DateFormat('dd MMM yyyy');
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> originalChecklist = [];
  List<Map<String, dynamic>> editedChecklist = [];

  List<Map<String, dynamic>> checklist = [];

  // Priority และ Status options พร้อมสีและไอคอน
  final Map<String, Map<String, dynamic>> priorityOptions = {
    'Low': {'label': 'ต่ำ', 'color': Colors.green, 'icon': Icons.low_priority},
    'Medium': {
      'label': 'ปานกลาง',
      'color': Colors.orange,
      'icon': Icons.remove,
    },
    'High': {'label': 'สูง', 'color': Colors.red, 'icon': Icons.priority_high},
  };

  final Map<String, Map<String, dynamic>> statusOptions = {
    'todo': {
      'label': 'รอดำเนินการ',
      'color': Colors.grey,
      'icon': Icons.pending_actions,
    },
    'in_progress': {
      'label': 'กำลังทำ',
      'color': Colors.orange,
      'icon': Icons.work,
    },
    'done': {
      'label': 'เสร็จแล้ว',
      'color': Colors.green,
      'icon': Icons.task_alt,
    },
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    final latestTask = controller.findTaskById(widget.task.id) ?? widget.task;

    // เก็บ checklist ของจริง
    originalChecklist = latestTask.checklist != null
        ? List<Map<String, dynamic>>.from(latestTask.checklist!)
        : [];

    // สร้างสำเนาสำหรับ UI
    editedChecklist = originalChecklist
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    titleController = TextEditingController(text: latestTask.title);
    // minitasktitleController = TextEditingController(text: );

    priority = latestTask.priority;
    startDate = latestTask.startDate;
    endDate = latestTask.endDate;
    editedStartDate = startDate;
    editedEndDate = endDate;
    status = latestTask.status;

    // โหลด checklist จาก TaskModel
    if (latestTask.checklist != null) {
      checklist = List<Map<String, dynamic>>.from(latestTask.checklist!);
      // เพิ่ม expanded flag
      for (var item in checklist) {
        item["expanded"] = true;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    titleController.dispose();
    checklist.clear();
    super.dispose();
  }

  Future<void> pickDate(BuildContext context, bool isStart) async {
    if (status == 'done') return;

    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? editedStartDate : editedEndDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          editedStartDate = picked;
          if (editedEndDate.isBefore(editedStartDate)) {
            editedEndDate = editedStartDate;
          }
        } else {
          editedEndDate = picked;
        }
      });
    }
  }

  void addChecklistItem() {
    setState(() {
      editedChecklist.add({
        "title": "",
        "description": "",
        "done": false,
        "expanded": true,
      });
    });
  }

  void removeChecklistItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_outline, color: Colors.red[600]),
            ),
            const SizedBox(width: 12),
            const Text('ยืนยันการลบ'),
          ],
        ),
        content: const Text('คุณต้องการลบงานย่อยนี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                editedChecklist.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  Future<void> saveTask() async {
    if (titleController.text.trim().isEmpty) {
      _showErrorSnackbar('กรุณาใส่ชื่องาน');
      return;
    }

    final updatedTask = widget.task.copyWith(
      title: titleController.text.trim(),
      priority: priority,
      startDate: editedStartDate,
      endDate: editedEndDate,
      status: status,
      checklist: editedChecklist,
    );

    try {
      await controller.updateTask(updatedTask);
      _showSuccessSnackbar('บันทึกงานเรียบร้อยแล้ว');

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } catch (e) {
      _showErrorSnackbar('ไม่สามารถบันทึกงานได้');
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDone = status == 'done';
    final statusInfo = statusOptions[status]!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: false,
            pinned: true,
            backgroundColor: statusInfo['color'],
            foregroundColor: Colors.white,
            title: const Text(
              'รายละเอียดงาน',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                onPressed: saveTask,
                icon: const Icon(Icons.save_rounded),
                tooltip: 'บันทึก',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ชื่องาน
                    _buildSectionCard(
                      title: 'ชื่องาน',
                      icon: Icons.title,
                      child: TextFormField(
                        controller: titleController,
                        readOnly: isDone,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDone ? Colors.grey : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'ใส่ชื่องาน...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isDone ? Colors.grey[100] : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Priority และ Status
                    Row(
                      children: [
                        Expanded(
                          child: _buildSectionCard(
                            title: 'ความสำคัญ',
                            icon: Icons.priority_high,
                            child: _buildPriorityDropdown(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSectionCard(
                            title: 'สถานะ',
                            icon: Icons.flag,
                            child: _buildStatusDropdown(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // วันที่
                    _buildSectionCard(
                      title: 'ช่วงเวลา',
                      icon: Icons.calendar_today,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildDateCard(
                              'เริ่ม',
                              editedStartDate,
                              true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDateCard(
                              'สิ้นสุด',
                              editedEndDate,
                              false,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Checklist Section
                    _buildChecklistSection(),

                    const SizedBox(height: 100), // พื้นที่สำหรับ FAB
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: saveTask,
        backgroundColor: statusInfo['color'],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.save_rounded),
        label: const Text(
          'บันทึก',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityDropdown() {
    final isDone = status == 'done';

    return DropdownButtonFormField<String>(
      value: priority,
      isExpanded: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: isDone ? Colors.grey[100] : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      items: priorityOptions.entries.map((entry) {
        final info = entry.value;
        return DropdownMenuItem(
          value: entry.key,
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: info['color'],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(info['icon'], size: 14, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(info['label'], overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: isDone ? null : (val) => setState(() => priority = val!),
    );
  }

  Widget _buildStatusDropdown() {
    final isDone = status == 'done';

    return DropdownButtonFormField<String>(
      value: status,
      isExpanded: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: isDone ? Colors.grey[100] : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      items: statusOptions.entries.map((entry) {
        final info = entry.value;
        return DropdownMenuItem(
          value: entry.key,
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: info['color'],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(info['icon'], size: 14, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(info['label'], overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: status == "done"
          ? null
          : (value) => setState(() => status = value!),
    );
  }

  Widget _buildDateCard(String label, DateTime date, bool isStart) {
    final isDone = status == 'done';
    final isOverdue = !isDone && date.isBefore(DateTime.now()) && !isStart;

    return InkWell(
      onTap: isDone ? null : () => pickDate(context, isStart),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDone ? Colors.grey[100] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOverdue ? Colors.red[300]! : Colors.grey[300]!,
            width: isOverdue ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isStart ? Icons.play_arrow : Icons.flag,
                  size: 16,
                  color: isOverdue ? Colors.red : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isOverdue ? Colors.red : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(date),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isOverdue ? Colors.red : Colors.black87,
              ),
            ),
            if (isOverdue) ...[
              const SizedBox(height: 4),
              Text(
                'เลยกำหนด',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.red[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistSection() {
    final isDone = status == 'done';
    final completedCount = checklist
        .where((item) => item['done'] == true)
        .length;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.checklist,
                    size: 20,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'งานย่อย',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (checklist.isNotEmpty)
                        Text(
                          'เสร็จแล้ว $completedCount จาก ${checklist.length} งาน',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isDone)
                  IconButton(
                    onPressed: addChecklistItem,
                    icon: const Icon(Icons.add_circle, color: Colors.blue),
                    tooltip: 'เพิ่มงานย่อย',
                  ),
              ],
            ),

            if (checklist.isNotEmpty) ...[
              const SizedBox(height: 16),
              // Progress Bar
              LinearProgressIndicator(
                value: checklist.isNotEmpty
                    ? completedCount / checklist.length
                    : 0,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  completedCount == checklist.length
                      ? Colors.green
                      : Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Checklist Items
            ...editedChecklist.asMap().entries.map((entry) {
              int index = entry.key;
              var item = entry.value;
              return _buildChecklistItem(item, index, isDone);
            }).toList(),

            if (checklist.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.checklist_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ยังไม่มีงานย่อย',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    if (!isDone) ...[
                      const SizedBox(height: 4),
                      Text(
                        'เพิ่มงานย่อยเพื่อแบ่งงานให้ชัดเจนขึ้น',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(
    Map<String, dynamic> item,
    int index,
    bool taskIsDone,
  ) {
    final done = item["done"] ?? false;
    final expanded = item["expanded"] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: done ? Colors.green[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done ? Colors.green[200]! : Colors.grey[200]!,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expanded,
          onExpansionChanged: (isExpanded) {
            setState(() => item["expanded"] = isExpanded);
          },
          leading: Checkbox(
            value: done,
            onChanged: taskIsDone
                ? null
                : (val) {
                    setState(() {
                      item["done"] = val ?? false;
                      if (val == true) item["expanded"] = false;
                    });
                  },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            activeColor: Colors.green,
          ),
          title: TextFormField(
            readOnly: done || taskIsDone,
            initialValue: item["title"] ?? "",
            style: TextStyle(
              color: done ? Colors.grey[600] : Colors.black87,
              decoration: done
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              hintText: "ชื่องานย่อย...",
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (val) => item["title"] = val,
          ),
          trailing: !taskIsDone
              ? IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => removeChecklistItem(index),
                  tooltip: 'ลบงานย่อย',
                )
              : null,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: TextFormField(
                readOnly: done || taskIsDone,
                initialValue: item["description"] ?? "",
                style: TextStyle(
                  color: done ? Colors.grey[600] : Colors.black87,
                ),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "รายละเอียดงานย่อย...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  filled: true,
                  fillColor: done || taskIsDone
                      ? Colors.grey[100]
                      : Colors.white,
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: (val) => item["description"] = val,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
