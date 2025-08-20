import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/task_model.dart';

class TaskController extends GetxController {
  var tasks = <TaskModel>[].obs;
  var isLoading = false.obs;
  var selectedStatus = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    loadTasks();
  }

  void loadTasks() {
    isLoading.value = true;
    final uid =
        'YOUR_CURRENT_USER_UID'; // เปลี่ยนเป็น FirebaseAuth.instance.currentUser!.uid
    FirebaseFirestore.instance
        .collection('tasks')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
          tasks.value = snapshot.docs
              .map((doc) => TaskModel.fromJson(doc.id, doc.data()))
              .toList();
          isLoading.value = false;
        });
  }

  List<TaskModel> get filteredTasks {
    switch (selectedStatus.value) {
      case 'todo':
        return tasks.where((t) => t.status.toLowerCase() == 'todo').toList();
      case 'in_progress':
        return tasks
            .where((t) => t.status.toLowerCase() == 'in_progress')
            .toList();
      case 'done':
        return tasks.where((t) => t.status.toLowerCase() == 'done').toList();
      case 'overdue':
        final now = DateTime.now();
        return tasks
            .where(
              (t) =>
                  t.endDate.isBefore(now) && t.status.toLowerCase() != 'done',
            )
            .toList();
      case 'all':
      default:
        return tasks;
    }
  }

  void changeStatusFilter(String status) {
    selectedStatus.value = status;
  }

  Future<void> addTask(TaskModel task) async {
    await FirebaseFirestore.instance.collection('tasks').add(task.toJson());
  }

  Future<void> updateTask(TaskModel task) async {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(task.id)
        .update(task.toJson());
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) tasks[index] = task;
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'status': status,
    });
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) tasks[index] = tasks[index].copyWith(status: status);
  }

  TaskModel? findTaskById(String id) {
    return tasks.firstWhereOrNull((t) => t.id == id);
  }
}
