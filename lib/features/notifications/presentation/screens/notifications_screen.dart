// lib/features/notifications/presentation/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) ref.read(notificationViewModelProvider.notifier).load(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final state = ref.watch(notificationViewModelProvider);

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: user == null
                  ? null
                  : () => ref.read(notificationViewModelProvider.notifier).markAllAsRead(user.id),
              child: const Text('Marcar todas'),
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: state.isLoading
              ? const Center(
                  key: ValueKey('loading'),
                  child: CircularProgressIndicator(),
                )
              : state.notifications.isEmpty
                  ? Center(
                      key: const ValueKey('empty'),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.notifications_none_rounded, color: context.textHint, size: 56),
                        const SizedBox(height: AppSpacing.md),
                        Text('Sin notificaciones', style: context.textTheme.bodyMedium),
                      ]),
                    )
                  : ListView.separated(
                      key: const ValueKey('list'),
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      itemCount: state.notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final n = state.notifications[i];
                        return Card(
                          shape: n.isRead
                              ? null
                              : RoundedRectangleBorder(
                                  borderRadius: AppRadius.xlR,
                                  side: BorderSide(color: context.colors.primary, width: 1),
                                ),
                          color: n.isRead ? null : context.colors.primaryContainer.withValues(alpha: 0.35),
                          child: InkWell(
                            borderRadius: AppRadius.xlR,
                            onTap: () {
                              if (!n.isRead) {
                                ref.read(notificationViewModelProvider.notifier).markAsRead(n.id);
                              }
                            },
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.xs,
                              ),
                              leading: Text(n.type.icon, style: const TextStyle(fontSize: 22)),
                              title: Text(n.title, style: context.textTheme.titleSmall),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (n.body != null && n.body!.isNotEmpty)
                                    Text(
                                      n.body!,
                                      style: context.textTheme.bodySmall,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    timeago.format(n.createdAt, locale: 'es'),
                                    style: TextStyle(color: context.textHint, fontSize: 11),
                                  ),
                                ],
                              ),
                              trailing: n.isRead
                                  ? null
                                  : Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: context.colors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
