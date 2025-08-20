import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/dashboard_controller.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> with TickerProviderStateMixin {
  final DashboardController dashboardController = Get.find<DashboardController>();
  final TextEditingController titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String priority = 'Low';
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 1));
  List<Map<String, dynamic>> checklist = [];
  bool _isLoading = false;

  // สีธีมสำหรับ priority
  final Map<String, Color> priorityColors = {
    'Low': Colors.green,
    'Medium': Colors.orange,
    'High': Colors.red,
  };

  final Map<String, IconData> priorityIcons = {
    'Low': Icons.keyboard_arrow_down,
    'Medium': Icons.remove,
    'High': Icons.keyboard_arrow_up,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    titleController.dispose();
    super.dispose();
  }

  Future<void> saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        _showErrorSnackbar('ไม่พบผู้ใช้');
        return;
      }

      final newTaskData = {
        'title': titleController.text.trim(),
        'priority': priority,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'status': 'todo',
        'uid': uid,
        'checklist': checklist,
        'createdAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('tasks').add(newTaskData);
      
      // Show success message and navigate back immediately
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('สร้าง Task "${titleController.text.trim()}" เรียบร้อยแล้ว'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      
      // Force navigate back using the most reliable method
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showErrorSnackbar('เกิดข้อผิดพลาดในการบันทึก: ${e.toString()}');
      print('Error saving task: $e'); // สำหรับ debug
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'เกิดข้อผิดพลาด ⚠️',
      message,
      backgroundColor: Colors.red.withOpacity(0.9),
      colorText: Colors.white,
      icon: const Icon(Icons.error_rounded, color: Colors.white),
      duration: const Duration(seconds: 4),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }

  Future<void> pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: priorityColors[priority],
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
          if (endDate.isBefore(startDate)) {
            endDate = startDate.add(const Duration(days: 1));
          }
        } else {
          if (picked.isBefore(startDate)) {
            _showErrorSnackbar('วันที่สิ้นสุดต้องไม่น้อยกว่าวันที่เริ่ม');
            return;
          }
          endDate = picked;
        }
      });
    }
  }

  void addChecklistItem() {
    setState(() {
      checklist.add({
        "title": "",
        "description": "",
        "done": false,
        "expanded": true,
        "id": DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  void removeChecklistItem(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('ยืนยันการลบ'),
          ],
        ),
        content: const Text('คุณต้องการลบงานย่อยนี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() {
        checklist.removeAt(index);
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return '${date.day} ${months[date.month]} ${date.year + 543}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text(
          'เพิ่ม Task ใหม่',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Task Title Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: priorityColors[priority]?.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.task_alt,
                              color: priorityColors[priority],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'รายละเอียด Task',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'ชื่อ Task *',
                          hintText: 'กรอกชื่อ Task ที่ต้องการทำ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.edit),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'กรุณากรอกชื่อ Task';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Priority and Dates Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                              Icons.settings,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'การตั้งค่า',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Priority Selector
                      const Text(
                        'ระดับความสำคัญ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: ['Low', 'Medium', 'High'].map((p) {
                            final isSelected = priority == p;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => priority = p),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? priorityColors[p] : Colors.transparent,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        priorityIcons[p],
                                        color: isSelected ? Colors.white : priorityColors[p],
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        p,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : priorityColors[p],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Date Pickers
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => pickDate(context, true),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, 
                                             size: 16, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          'วันที่เริ่ม',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(startDate),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => pickDate(context, false),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.event, 
                                             size: 16, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          'วันที่สิ้นสุด',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(endDate),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Checklist Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.checklist,
                                  color: Colors.purple,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Task ย่อย',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${checklist.length} รายการ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: addChecklistItem,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('เพิ่ม'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (checklist.isEmpty) ...[
                        const SizedBox(height: 20),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.checklist,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ยังไม่มี Task ย่อย',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'แตะปุ่ม "เพิ่ม" เพื่อเพิ่ม Task ย่อย',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        ...checklist.asMap().entries.map((entry) {
                          int index = entry.key;
                          var item = entry.value;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: item["done"] == true 
                                    ? Colors.green.shade200 
                                    : Colors.grey.shade300,
                              ),
                              color: item["done"] == true 
                                  ? Colors.green.shade50 
                                  : Colors.white,
                            ),
                            child: ExpansionTile(
                              key: ValueKey(item["id"]),
                              initiallyExpanded: item["expanded"] ?? true,
                              onExpansionChanged: (expanded) {
                                setState(() {
                                  item["expanded"] = expanded;
                                });
                              },
                              leading: Checkbox(
                                value: item["done"],
                                onChanged: (val) {
                                  setState(() {
                                    item["done"] = val!;
                                  });
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              title: TextField(
                                readOnly: item["done"] ?? false,
                                decoration: const InputDecoration(
                                  hintText: "ชื่องานย่อย",
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                controller: TextEditingController(text: item["title"])
                                  ..selection = TextSelection.collapsed(
                                    offset: item["title"]?.length ?? 0,
                                  ),
                                style: TextStyle(
                                  color: (item["done"] ?? false)
                                      ? Colors.grey
                                      : Colors.black,
                                  decoration: (item["done"] ?? false)
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                onChanged: (val) => item["title"] = val,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, 
                                                   color: Colors.red, size: 20),
                                    onPressed: () => removeChecklistItem(index),
                                  ),
                                  RotationTransition(
                                    turns: AlwaysStoppedAnimation(
                                      (item["expanded"] ?? true) ? 0.5 : 0.0,
                                    ),
                                    child: const Icon(Icons.expand_more),
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: TextField(
                                    readOnly: item["done"] ?? false,
                                    decoration: InputDecoration(
                                      hintText: "รายละเอียดงานย่อย (ไม่จำเป็น)",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                    ),
                                    maxLines: 2,
                                    controller: TextEditingController(
                                      text: item["description"],
                                    ),
                                    style: TextStyle(
                                      color: (item["done"] ?? false)
                                          ? Colors.grey
                                          : Colors.black,
                                      fontSize: 14,
                                    ),
                                    onChanged: (val) => item["description"] = val,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : saveTask,
              icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save, size: 22),
              label: Text(
                _isLoading ? 'กำลังบันทึก...' : 'บันทึก Task',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: priorityColors[priority],
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}