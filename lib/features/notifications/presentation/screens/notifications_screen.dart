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
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
            : state.notifications.isEmpty
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.notifications_none_rounded, color: context.textHint, size: 56),
                      const SizedBox(height: 12),
                      Text('Sin notificaciones', style: TextStyle(color: context.textSecondary)),
                    ]),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: state.notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final n = state.notifications[i];
                      return GestureDetector(
                        onTap: () {
                          if (!n.isRead) {
                            ref.read(notificationViewModelProvider.notifier).markAsRead(n.id);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: n.isRead ? context.card : context.cardInner,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: n.isRead ? context.border : AppTheme.brandGreen.withValues(alpha: 0.4),
                              width: n.isRead ? 0.5 : 1,
                            ),
                          ),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(n.type.icon, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(n.title,
                                    style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                                if (n.body != null && n.body!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(n.body!,
                                      style: TextStyle(color: context.textSecondary, fontSize: 12),
                                      maxLines: 2, overflow: TextOverflow.ellipsis),
                                ],
                                const SizedBox(height: 6),
                                Text(timeago.format(n.createdAt, locale: 'es'),
                                    style: TextStyle(color: context.textHint, fontSize: 11)),
                              ]),
                            ),
                            if (!n.isRead)
                              Container(
                                width: 8, height: 8,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: const BoxDecoration(color: AppTheme.brandGreen, shape: BoxShape.circle),
                              ),
                          ]),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
