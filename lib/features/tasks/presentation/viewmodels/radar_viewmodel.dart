// lib/features/tasks/presentation/viewmodels/radar_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/domain/entities/service_entity.dart' show ServiceCategory;
import '../../data/datasources/task_remote_datasource.dart';

export '../../data/datasources/task_remote_datasource.dart';

class RadarState {
  final bool isLoading;
  final List<UrgentTaskEntity> urgentTasks;
  final List<TaskRequestEntity> openTaskRequests;
  final List<TaskApplicationEntity> myApplications;
  final String? error;
  final String? successMessage;

  const RadarState({
    this.isLoading = false,
    this.urgentTasks = const [],
    this.openTaskRequests = const [],
    this.myApplications = const [],
    this.error,
    this.successMessage,
  });

  RadarState copyWith({
    bool? isLoading,
    List<UrgentTaskEntity>? urgentTasks,
    List<TaskRequestEntity>? openTaskRequests,
    List<TaskApplicationEntity>? myApplications,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return RadarState(
      isLoading: isLoading ?? this.isLoading,
      urgentTasks: urgentTasks ?? this.urgentTasks,
      openTaskRequests: openTaskRequests ?? this.openTaskRequests,
      myApplications: myApplications ?? this.myApplications,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  bool hasAppliedToUrgent(String urgentTaskId) =>
      myApplications.any((a) => a.urgentTaskId == urgentTaskId);

  bool hasAppliedToTaskRequest(String taskRequestId) =>
      myApplications.any((a) => a.taskRequestId == taskRequestId);
}

class RadarViewModel extends StateNotifier<RadarState> {
  final TaskRemoteDataSource _ds;
  RadarViewModel(this._ds) : super(const RadarState());

  Future<void> loadUrgentTasks({double? lat, double? lng}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tasks = await _ds.getNearbyUrgentTasks(lat: lat, lng: lng);
      state = state.copyWith(isLoading: false, urgentTasks: tasks);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadOpenTaskRequests({ServiceCategory? category}) async {
    try {
      final tasks = await _ds.getOpenTaskRequests(category: category);
      state = state.copyWith(openTaskRequests: tasks);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadMyApplications(String yoerId) async {
    try {
      final apps = await _ds.getMyApplications(yoerId);
      state = state.copyWith(myApplications: apps);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> applyToUrgent(String urgentTaskId, String yoerId, {String? proposal}) async {
    try {
      await _ds.applyToUrgentTask(urgentTaskId, yoerId, proposal: proposal);
      await loadMyApplications(yoerId);
      state = state.copyWith(successMessage: '¡Postulación enviada!');
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> applyToTaskRequest(String taskRequestId, String yoerId, {String? proposal, double? proposedPrice}) async {
    try {
      await _ds.applyToTaskRequest(taskRequestId, yoerId, proposal: proposal, proposedPrice: proposedPrice);
      await loadMyApplications(yoerId);
      state = state.copyWith(successMessage: '¡Postulación enviada!');
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearMessages() => state = state.copyWith(clearError: true, clearSuccess: true);
}

final taskDataSourceProvider = Provider<TaskRemoteDataSource>((ref) {
  return TaskRemoteDataSource(Supabase.instance.client);
});

final radarViewModelProvider = StateNotifierProvider<RadarViewModel, RadarState>((ref) {
  return RadarViewModel(ref.read(taskDataSourceProvider));
});
