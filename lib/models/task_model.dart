import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String priority;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String uid;
  final List<Map<String, dynamic>>? checklist;

  TaskModel({
    required this.id,
    required this.title,
    required this.priority,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.uid,
    this.checklist,
  });

  factory TaskModel.fromJson(String id, Map<String, dynamic> json) {
    return TaskModel(
      id: id,
      title: json['title'] ?? '',
      priority: json['priority'] ?? 'Low',
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      status: json['status'] ?? 'todo',
      uid : json['uid'] ?? '',
      checklist: json['checklist'] != null
          ? List<Map<String, dynamic>>.from(json['checklist'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'priority': priority,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status,
      'uid': uid,
      'checklist': checklist ?? [],
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? uid,
    List<Map<String, dynamic>>? checklist,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      uid: uid ?? this.uid,
      checklist: checklist ?? this.checklist,
    );
  }
}
