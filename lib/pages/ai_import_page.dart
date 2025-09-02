import 'package:ai_task_project_manager/controllers/dashboard_controller.dart';
import 'package:ai_task_project_manager/models/task_model.dart';
import 'package:ai_task_project_manager/services/ai_api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AiImportPage extends StatefulWidget {
  const AiImportPage({super.key});

  @override
  State<AiImportPage> createState() => _AiImportPageState();
}

class _AiImportPageState extends State<AiImportPage>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _mainTaskController = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _previewTasks = [];
  TaskModel? _aiMainTask;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
    _controller.dispose();
    _mainTaskController.dispose();
    super.dispose();
  }

  Future<void> _generateTasks() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _showSnackbar('กรุณาใส่ข้อความ', isError: true);
      return;
    }

    setState(() => _loading = true);
    _slideController.reset();

    try {
      final TaskModel task = await AiApiService.fetchTaskFromAi(text);

      // แปลง startDate / endDate ของ main task เป็น DateTime
      DateTime? parseDate(dynamic date) {
        if (date == null) return null;
        if (date is DateTime) return date;
        if (date is String) {
          try {
            // รองรับรูปแบบ dd/MM/yyyy
            if (date.contains('/')) {
              final parts = date.split('/');
              if (parts.length == 3) {
                return DateTime(
                  int.parse(parts[0]), // year
                  int.parse(parts[1]), // month
                  int.parse(parts[2]), // day
                );
              }
            }
            // รองรับ ISO format
            return DateTime.parse(date);
          } catch (e) {
            print('Failed to parse date: $date');
            return null;
          }
        }
        return null;
      }

      _aiMainTask = task.copyWith(
        startDate: parseDate(task.startDate),
        endDate: parseDate(task.endDate),
      );

      // แปลง checklist ให้เป็นรูปแบบที่ใช้ได้
      _previewTasks = [];

      if (task.checklist != null && task.checklist!.isNotEmpty) {
        _previewTasks = task.checklist!
            .map((item) {
              final Map<String, dynamic> taskItem = {};
              if (item is Map<String, dynamic>) {
                taskItem.addAll(item);
              } else if (item is String) {
                taskItem['title'] = item;
                taskItem['description'] = '';
              } else {
                taskItem['title'] = item.toString();
                taskItem['description'] = '';
              }

              final start = parseDate(taskItem['start_date']);
              final end = parseDate(taskItem['end_date']);

              // Debug Sub-task
              print('Raw start_date: ${task.startDate}');
              print('Raw end_date: ${task.endDate}');

              return {
                'title': taskItem['title'] ?? '',
                'description': taskItem['description'] ?? '',
                'done': taskItem['done'] ?? false,
                'expanded': taskItem['expanded'] ?? true,
                'priority': taskItem['priority']?.toString() ?? 'medium',
                'start_date': start,
                'end_date': end,
              };
            })
            .where((item) => item['title'].toString().isNotEmpty)
            .toList();
      }

      if (_previewTasks.isNotEmpty) {
        _mainTaskController.text = _aiMainTask!.title;
        _animationController.forward();
        _slideController.forward();
      } else {
        _showSnackbar('ไม่พบ Sub-tasks ที่สามารถแปลงได้', isError: true);
      }
    } catch (e) {
      String errorMessage = e.toString();

      try {
        // ถ้า error เป็น JSON string → parse ออกมา
        final regex = RegExp(r'"message"\s*:\s*"([^"]+)"');
        final match = regex.firstMatch(errorMessage);

        if (match != null) {
          errorMessage = match.group(1)!; // เอาเฉพาะข้อความใน "message"
        }
      } catch (_) {
        // fallback ถ้า parse ไม่ได้
      }

      print('Error generating tasks: $errorMessage');
      _showSnackbar('เกิดข้อผิดพลาดจาก AI: $errorMessage', isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveToProject() async {
    if (_previewTasks.isEmpty) return;

    final mainTaskTitle = _mainTaskController.text.trim();
    if (mainTaskTitle.isEmpty) {
      _showSnackbar('กรุณาใส่ชื่อ Task หลัก', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final taskController = Get.find<DashboardController>();
      final uid = taskController.auth.currentUser?.uid;
      if (uid == null) throw Exception("User not logged in");

      final mainTask = _aiMainTask!.copyWith(
        id: '',
        uid: uid,
        title: mainTaskTitle,
        checklist: _previewTasks,
      );

      await taskController.addTask(mainTask);

      _showSnackbar(
        'บันทึก Task หลักพร้อม ${_previewTasks.length} รายการย่อยเรียบร้อยแล้ว ✓',
      );

      _animationController.reverse();
      _slideController.reverse();

      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _previewTasks = [];
        _controller.clear();
        _mainTaskController.clear();
        _aiMainTask = null;
      });
    } catch (e) {
      print('Error saving main task: $e');
      _showSnackbar('ไม่สามารถบันทึก Task ได้', isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    Get.showSnackbar(
      GetSnackBar(
        message: message,
        duration: const Duration(seconds: 3),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        borderRadius: 12,
        margin: const EdgeInsets.all(20),
        snackPosition: SnackPosition.TOP,
        boxShadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        icon: Icon(
          isError
              ? Icons.error_outline_rounded
              : Icons.check_circle_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  // Helper methods for statistics

  String? formatDate(dynamic value) {
    if (value == null) return '';
    return DateFormat('dd/MM/yyyy').format(value);

    // if (value is Timestamp) {
    //   return dateFormatter.format(value.toDate());
    // } else if (value is DateTime) {
    //   return dateFormatter.format(value);
    // } else if (value is String) {
    //   try {
    //     final parsed = DateTime.tryParse(value);
    //     if (parsed != null) {
    //       return dateFormatter.format(parsed);
    //     }
    //     return value; // ถ้า parse ไม่ได้
    //   } catch (_) {
    //     return value;
    //   }
    // } else {
    //   return value.toString();
    // }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0D1117)
          : const Color(0xFFFAFBFC),
      body: Scrollbar(
        thumbVisibility: true,
        thickness: 6,
        radius: const Radius.circular(10),
        child: CustomScrollView(
          slivers: [
            // Modern App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary.withOpacity(0.1),
                        colorScheme.secondary.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Get.back(),
                                icon: Icon(
                                  Icons.arrow_back_rounded,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withOpacity(
                                        0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.auto_awesome_rounded,
                                  color: colorScheme.onPrimary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'AI Task Generator',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              'แปลงข้อความเป็น Task พร้อม Sub-tasks อัตโนมัติ',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),

                  // Input Section
                  _buildInputSection(theme, colorScheme),
                  const SizedBox(height: 24),

                  // Generate Button
                  _buildGenerateButton(theme, colorScheme),
                  const SizedBox(height: 32),

                  // Main Task Information Section
                  if (_previewTasks.isNotEmpty)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildMainTaskInfoSection(theme, colorScheme),
                      ),
                    ),

                  if (_previewTasks.isNotEmpty) const SizedBox(height: 24),

                  // Preview Tasks Section
                  _buildPreviewSection(theme, colorScheme),

                  const SizedBox(height: 32),

                  // Save Button
                  if (_previewTasks.isNotEmpty)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildSaveButton(theme, colorScheme),
                      ),
                    ),

                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'ข้อความที่ต้องการแปลง',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Stack(
              children: [
                TextField(
                  controller: _controller,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText:
                        'วางข้อความประชุม, อีเมล, หรือโน้ตที่ต้องการแปลงเป็น Task...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(
                      top: 12, // เผื่อระยะด้านบนให้ปุ่มไม่ทับข้อความ
                      left: 0,
                      right: 40, // กันพื้นที่ด้านขวาไว้ไม่ให้ข้อความทับปุ่ม
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: colorScheme.onSurface,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                    onPressed: () {
                      _controller.clear();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading ? null : _generateTasks,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_loading)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onPrimary,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: colorScheme.onPrimary,
                    size: 24,
                  ),
                const SizedBox(width: 12),
                Text(
                  _loading ? 'กำลังประมวลผลด้วย AI...' : 'สร้าง Task ด้วย AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainTaskInfoSection(ThemeData theme, ColorScheme colorScheme) {
    if (_aiMainTask == null) return const SizedBox();

    final mainTask = _aiMainTask!;
    final DateTime startDate = mainTask.startDate;
    final DateTime endDate = mainTask.endDate;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colorScheme.primaryContainer.withOpacity(0.3),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.task_alt_rounded,
                  color: colorScheme.onPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ข้อมูล Task หลัก',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Task Name Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.title_rounded,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ชื่อ Task',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _mainTaskController,
                  decoration: InputDecoration(
                    hintText: 'กำหนดชื่อ Task หลัก',
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Task Info Grid
          Row(
            children: [
              // Dates Section
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.date_range_rounded,
                            size: 18,
                            color: colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'วันที่',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...[
                        Row(
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              size: 14,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'เริ่ม: ${formatDate(startDate)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],

                      // แสดง End Date
                      ...[
                        Row(
                          children: [
                            Icon(
                              Icons.flag_rounded,
                              size: 14,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'สิ้นสุด: ${formatDate(endDate)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      // ignore: unnecessary_null_comparison
                      if (startDate == null && endDate == null)
                        Text(
                          'ไม่ระบุวันที่',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(ThemeData theme, ColorScheme colorScheme) {
    return Scrollbar(
      thumbVisibility: true,
      thickness: 6,
      radius: Radius.circular(10),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: _previewTasks.isEmpty
            ? _buildEmptyState(theme, colorScheme)
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.checklist_rounded,
                              color: colorScheme.secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sub-tasks (${_previewTasks.length})',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _previewTasks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final task = _previewTasks[index];
                            return _buildSimpleTaskCard(
                              task,
                              index,
                              theme,
                              colorScheme,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSimpleTaskCard(
    Map<String, dynamic> task,
    int index,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final title = task['title']?.toString() ?? '';
    final description = task['description']?.toString() ?? '';

    // ตรวจสอบว่า title มีข้อมูล name และ description หรือไม่
    String displayTitle = title;
    String displayDescription = description;

    // ถ้า title มีรูปแบบ "(name: ..., description: ...)"
    if (title.contains('name:') && title.contains('description:')) {
      final regex = RegExp(r'name:\s*([^,]*),\s*description:\s*(.*)}');
      final match = regex.firstMatch(title);
      if (match != null) {
        displayTitle = match.group(1)?.trim() ?? title;
        displayDescription = match.group(2)?.trim() ?? description;
      }
    }

    // ถ้า description ว่างเปล่า แต่ title มีข้อมูลยาว ให้แยกออกมา
    if (displayDescription.isEmpty && displayTitle.length > 50) {
      // แยก title ที่ยาวเป็น title และ description
      final sentences = displayTitle.split('.');
      if (sentences.length > 1) {
        displayTitle = sentences[0].trim();
        displayDescription = sentences.sublist(1).join('.').trim();
      }
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with task number
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Task Number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    'Sub-task ${index + 1}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Task content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.title_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ชื่อ Sub-task',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        displayTitle.isNotEmpty
                            ? displayTitle
                            : 'ไม่มีชื่อ Task',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                // Description
                if (displayDescription.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.description_rounded,
                              size: 16,
                              color: colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'รายละเอียด',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          displayDescription,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.8),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ไม่มีรายละเอียด',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.psychology_rounded,
              size: 48,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sub-tasks จะแสดงที่นี่',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ใส่ข้อความแล้วกดสร้าง Task',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            colorScheme.secondary,
            colorScheme.secondary.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading ? null : _saveToProject,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_loading)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onSecondary,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.save_rounded,
                    color: colorScheme.onSecondary,
                    size: 24,
                  ),
                const SizedBox(width: 12),
                Text(
                  _loading ? 'กำลังบันทึก...' : 'บันทึก Task หลัก',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
