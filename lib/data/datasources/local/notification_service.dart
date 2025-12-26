import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';

class NotificationService {
  static const String _portName = 'notification_send_port';
  ReceivePort? _port;
  final Function(String) onNotificationReceived;

  NotificationService({required this.onNotificationReceived});

  /// Starts listening for notifications.
  Future<void> startListening() async {
    if (!Platform.isAndroid) return;

    bool? hasPermission = await NotificationsListener.hasPermission;
    if (hasPermission != true) {
      print('Requesting notification permission...');
      // Note: This opens the system settings screen
      await NotificationsListener.openPermissionSettings();
      return;
    }

    // Register port for background communication
    _port = ReceivePort();
    IsolateNameServer.removePortNameMapping(_portName);
    IsolateNameServer.registerPortWithName(_port!.sendPort, _portName);

    // Listen to incoming messages from background isolate
    _port!.listen((message) {
      _onData(message);
    });

    try {
      // Initialize background callback
      await NotificationsListener.initialize(callbackHandle: notificationTapBackground);

      await NotificationsListener.startService(
        foreground: false, // Use background service
        title: "AI Assistant Listener",
        description: "Listening for notifications...",
      );
      print('Notification Listener started.');
    } catch (e) {
      print('Error starting notification listener: $e');
    }
  }

  /// Stops listening.
  Future<void> stopListening() async {
    if (!Platform.isAndroid) return;

    try {
      await NotificationsListener.stopService();
      IsolateNameServer.removePortNameMapping(_portName);
      _port?.close();
    } catch (e) {
      print('Error stopping notification listener: $e');
    }
  }

  void _onData(dynamic message) {
    // message is typically an NotificationEvent object or map.
    // However, across isolates, it might be serialized.
    // The package sends NotificationEvent.
    print('Notification received: $message');

    if (message is NotificationEvent) {
      final text = "${message.title ?? ''}: ${message.text ?? ''}";
      if (text.trim().length > 2) { // Filter empty or noise
        onNotificationReceived(text);
      }
    }
  }
}

// Global callback for background handling
@pragma('vm:entry-point')
void notificationTapBackground(NotificationEvent evt) {
  print("Background notification: $evt");
  final SendPort? send = IsolateNameServer.lookupPortByName('notification_send_port');
  if (send != null) {
    send.send(evt);
  }
}
