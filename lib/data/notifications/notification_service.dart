import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/schedule/schedule_models.dart';

/// Notificaciones locales (RF3). Programa recordatorios de clase a partir del
/// horario activo y las preferencias del usuario. 100% en el dispositivo, sin
/// red: usa `flutter_local_notifications` + `timezone`.
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const _channelId = 'class_reminders';
  static const _channelName = 'Recordatorios de clase';
  static const _androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: 'Avisos antes de cada clase de tu horario.',
    importance: Importance.high,
    priority: Priority.high,
  );
  static const _details = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  /// Inicializa el plugin y la base de datos de zonas horarias. Idempotente.
  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(await _resolveTimeZone()));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);
    _ready = true;
  }

  /// La zona por defecto es la de ESCOM-IPN; se intenta detectar la del
  /// dispositivo de forma tolerante al formato que devuelva el plugin.
  Future<String> _resolveTimeZone() async {
    var name = 'America/Mexico_City';
    try {
      final dynamic detected = await FlutterTimezone.getLocalTimezone();
      if (detected is String && detected.isNotEmpty) {
        name = detected;
      } else {
        final id = (detected as dynamic).identifier;
        if (id is String && id.isNotEmpty) name = id;
      }
      // Verifica que exista en la base de datos tz; si no, se queda el default.
      tz.getLocation(name);
    } catch (_) {
      name = 'America/Mexico_City';
    }
    return name;
  }

  /// Pide permisos de notificación (Android 13+ / iOS) y de alarmas exactas.
  Future<void> requestPermissions() async {
    await init();
    final android =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    final ios =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Reprograma todos los recordatorios según el horario y las preferencias.
  Future<void> syncClassReminders(ProcessedSchedule? schedule, LocalSettings settings) async {
    await init();
    await _plugin.cancelAll();
    if (schedule == null || schedule.classes.isEmpty) return;

    final selected = settings.notificationScope == NotificationScope.selectedSubjects
        ? settings.notificationSubjects
            .split(';')
            .map((s) => s.trim().toLowerCase())
            .where((s) => s.isNotEmpty)
            .toSet()
        : null;

    var id = 1;
    for (final session in schedule.classes) {
      if (selected != null && !selected.contains(session.subjectName.trim().toLowerCase())) {
        continue;
      }

      final start = _nextInstance(session.dayOfWeek, session.startMinutes);
      final room = session.classroomName == null ? '' : ' · Salón ${session.classroomName}';

      final minutesBefore = settings.classNotificationMinutes;
      if (minutesBefore > 0) {
        await _schedule(
          id++,
          'Tu clase empieza pronto',
          '${session.subjectName} en $minutesBefore min (${session.startTime})$room',
          start.subtract(Duration(minutes: minutesBefore)),
        );
      }
      if (settings.enableStartClassNotification) {
        await _schedule(
          id++,
          'Clase en curso',
          '${session.subjectName} (${session.startTime})$room',
          start,
        );
      }
    }
  }

  Future<void> _schedule(int id, String title, String body, tz.TZDateTime when) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      // No romper la app si falla una alarma puntual (p. ej. permiso exacto).
      debugPrint('NotificationService._schedule: $e');
    }
  }

  /// Próxima ocurrencia semanal de un día (1=lunes..6=sábado) y minuto del día.
  tz.TZDateTime _nextInstance(int dayOfWeek, int minutesOfDay) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minutesOfDay ~/ 60,
      minutesOfDay % 60,
    );
    // weekday: lunes=1..domingo=7, igual que el modelo (1..6).
    while (scheduled.weekday != dayOfWeek || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Notificación inmediata de prueba (botón en Perfil/Ajustes).
  Future<void> showTest() async {
    await init();
    await _plugin.show(
      9999,
      'Notificaciones activas',
      'Así se verán los recordatorios de tus clases.',
      _details,
    );
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
