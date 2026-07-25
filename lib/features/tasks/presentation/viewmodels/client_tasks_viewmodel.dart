// lib/features/tasks/presentation/viewmodels/client_tasks_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/domain/entities/service_entity.dart' show ServiceCategory;
import '../../data/datasources/task_remote_datasource.dart';
import 'radar_viewmodel.dart' show taskDataSourceProvider;

class ClientTasksState {
  final bool isLoading;
  final List<TaskRequestEntity> myTaskRequests;
  final Map<String, List<TaskApplicationEntity>> applicationsByTaskId;
  final String? error;
  final String? successMessage;

  const ClientTasksState({
    this.isLoading = false,
    this.myTaskRequests = const [],
    this.applicationsByTaskId = const {},
    this.error,
    this.successMessage,
  });

  ClientTasksState copyWith({
    bool? isLoading,
    List<TaskRequestEntity>? myTaskRequests,
    Map<String, List<TaskApplicationEntity>>? applicationsByTaskId,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ClientTasksState(
      isLoading: isLoading ?? this.isLoading,
      myTaskRequests: myTaskRequests ?? this.myTaskRequests,
      applicationsByTaskId: applicationsByTaskId ?? this.applicationsByTaskId,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ClientTasksViewModel extends StateNotifier<ClientTasksState> {
  final TaskRemoteDataSource _ds;
  ClientTasksViewModel(this._ds) : super(const ClientTasksState());

  Future<void> load(String clientId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tasks = await _ds.getMyTaskRequests(clientId);
      state = state.copyWith(isLoading: false, myTaskRequests: tasks);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> create({
    required String clientId,
    required String title,
    required String description,
    required ServiceCategory category,
    required TaskMode mode,
    required TaskServiceMode serviceMode,
    required double budget,
    double? estimatedHours,
    String? address,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _ds.createTaskRequest(
        clientId: clientId,
        title: title,
        description: description,
        category: category,
        mode: mode,
        serviceMode: serviceMode,
        budget: budget,
        estimatedHours: estimatedHours,
        address: address,
      );
      await load(clientId);
      state = state.copyWith(successMessage: '¡Tarea publicada!');
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> loadApplications(String taskRequestId) async {
    try {
      final apps = await _ds.getApplicationsForTaskRequest(taskRequestId);
      state = state.copyWith(applicationsByTaskId: {
        ...state.applicationsByTaskId,
        taskRequestId: apps,
      });
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> acceptApplication(TaskApplicationEntity app, String clientId) async {
    try {
      await _ds.acceptApplication(app);
      if (app.taskRequestId != null) await loadApplications(app.taskRequestId!);
      await load(clientId);
      state = state.copyWith(successMessage: 'YOER asignado a la tarea');
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> rejectApplication(String applicationId, String taskRequestId) async {
    try {
      await _ds.rejectApplication(applicationId);
      await loadApplications(taskRequestId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> cancel(String id, String clientId) async {
    try {
      await _ds.cancelTaskRequest(id);
      await load(clientId);
      state = state.copyWith(successMessage: 'Tarea cancelada');
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> complete(String id, String clientId) async {
    try {
      await _ds.completeTaskRequest(id);
      await load(clientId);
      state = state.copyWith(successMessage: '¡Tarea marcada como completada!');
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearMessages() => state = state.copyWith(clearError: true, clearSuccess: true);
}

final clientTasksViewModelProvider =
    StateNotifierProvider<ClientTasksViewModel, ClientTasksState>((ref) {
  return ClientTasksViewModel(ref.read(taskDataSourceProvider));
});
