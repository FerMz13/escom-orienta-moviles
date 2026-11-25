import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/schedule/reminder_planner.dart';
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
    await _plugin.initialize(settings: settings);
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

  bool _askedPermission = false;

  /// Reprograma todos los recordatorios según el horario y las preferencias
  /// (RF-17, RF-23). Se llama cada vez que cambia el horario o la configuración
  /// y al abrir la app; tras reiniciar el teléfono, el `ScheduledNotificationBootReceiver`
  /// del AndroidManifest restaura las alarmas guardadas por el plugin.
  Future<void> syncClassReminders(ProcessedSchedule? schedule, LocalSettings settings) async {
    await init();
    await _plugin.cancelAll();
    final reminders = ReminderPlanner.plan(schedule, settings);
    if (reminders.isEmpty) return;

    // Android 13+: sin este permiso los avisos no se muestran. Se pide una sola
    // vez por ejecución y solo si de verdad hay recordatorios que programar.
    if (!_askedPermission) {
      _askedPermission = true;
      await _android?.requestNotificationsPermission();
    }
    final mode = await _scheduleMode();

    var id = 1;
    for (final r in reminders) {
      await _schedule(id++, r.title, r.body, _nextInstance(r.dayOfWeek, r.minutesOfDay), mode);
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Alarmas exactas si el usuario las concedió; si no, inexactas (pueden
  /// retrasarse unos minutos, pero se entregan).
  Future<AndroidScheduleMode> _scheduleMode() async {
    try {
      final exact = await _android?.canScheduleExactNotifications() ?? true;
      return exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;
    } catch (_) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  Future<void> _schedule(
    int id,
    String title,
    String body,
    tz.TZDateTime when,
    AndroidScheduleMode mode,
  ) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: _details,
        androidScheduleMode: mode,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      // No romper la app si falla una alarma puntual (p. ej. permiso exacto).
      debugPrint('NotificationService._schedule: $e');
    }
  }

  /// Próxima ocurrencia semanal de un día (1=lunes..7=domingo) y minuto del día.
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
      id: 9999,
      title: 'Notificaciones activas',
      body: 'Así se verán los recordatorios de tus clases.',
      notificationDetails: _details,
    );
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
