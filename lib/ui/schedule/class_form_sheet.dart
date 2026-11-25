import 'package:material_ui/material_ui.dart';

import '../../domain/schedule/classroom_rules.dart';
import '../../domain/schedule/schedule_models.dart';
import '../common/common_widgets.dart';

/// Formulario para crear o editar una clase. Devuelve el borrador o `null`.
Future<ClassSessionDraft?> showClassForm(
  BuildContext context, {
  ClassSessionData? initial,
  int? initialDay,
}) =>
    showModalBottomSheet<ClassSessionDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ClassForm(initial: initial, initialDay: initialDay),
    );

class _ClassForm extends StatefulWidget {
  const _ClassForm({this.initial, this.initialDay});
  final ClassSessionData? initial;
  final int? initialDay;

  @override
  State<_ClassForm> createState() => _ClassFormState();
}

class _ClassFormState extends State<_ClassForm> {
  final _formKey = GlobalKey<FormState>();
  late final _subject = TextEditingController(text: widget.initial?.subjectName);
  late final _group = TextEditingController(text: widget.initial?.groupName);
  late final _teacher = TextEditingController(text: widget.initial?.teacherName);
  late final _classroom = TextEditingController(text: widget.initial?.classroomName);
  late int _day = widget.initial?.dayOfWeek ?? widget.initialDay ?? 1;
  late TimeOfDay _start = _parse(widget.initial?.startTime) ?? const TimeOfDay(hour: 7, minute: 0);
  late TimeOfDay _end = _parse(widget.initial?.endTime) ?? const TimeOfDay(hour: 8, minute: 30);
  String? _timeError;

  /// Bloques institucionales de 90 minutos.
  static const _blocks = [(7, 0), (8, 30), (10, 30), (12, 0), (13, 30), (15, 0), (16, 30), (18, 30), (20, 0)];

  static TimeOfDay? _parse(String? value) {
    if (value == null) return null;
    final minutes = timeToMinutes(value);
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  static String _format(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _subject.dispose();
    _group.dispose();
    _teacher.dispose();
    _classroom.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool start) async {
    final picked = await showTimePicker(context: context, initialTime: start ? _start : _end);
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
        final end = picked.hour * 60 + picked.minute + 90;
        if (end < 24 * 60) _end = TimeOfDay(hour: end ~/ 60, minute: end % 60);
      } else {
        _end = picked;
      }
      _timeError = _validateTimes();
    });
  }

  /// Validación inmediata del rango horario (se ejecuta en cada cambio).
  String? _validateTimes() {
    final startMinutes = _start.hour * 60 + _start.minute;
    final endMinutes = _end.hour * 60 + _end.minute;
    return endMinutes <= startMinutes ? 'La hora de fin debe ser posterior al inicio.' : null;
  }

  void _submit() {
    setState(() => _timeError = _validateTimes());
    if (!_formKey.currentState!.validate() || _timeError != null) return;

    String? optional(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    final classroom = optional(_classroom);
    Navigator.pop(
      context,
      ClassSessionDraft(
        subjectName: _subject.text.trim(),
        groupName: optional(_group)?.toUpperCase(),
        teacherName: optional(_teacher),
        dayOfWeek: _day,
        startTime: _format(_start),
        endTime: _format(_end),
        classroomName: classroom,
        classroomStatus: classroom == null ? ClassroomStatus.pending : ClassroomStatus.available,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.initial == null ? 'Agregar materia' : 'Editar clase', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subject,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Materia *', hintText: 'ej. Cálculo Diferencial'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Escribe el nombre de la materia.' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _group,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'Grupo', hintText: '3CM1'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _classroom,
                      decoration: const InputDecoration(labelText: 'Salón', hintText: 'ej. 1104'),
                      validator: (v) {
                        final value = (v ?? '').trim();
                        if (RegExp(r'^\d{4}$').hasMatch(value) && !isKnownClassroom(value)) {
                          return 'Ese salón no existe en ESCOM.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _teacher,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Profesor titular'),
              ),
              const SizedBox(height: 16),
              Text('Día', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  for (var d = 1; d <= 6; d++)
                    ChoiceChip(
                      label: Text(weekDayShortNames[d - 1]),
                      selected: _day == d,
                      onSelected: (_) => setState(() => _day = d),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(true),
                      icon: const Icon(Icons.schedule),
                      label: Text('Inicio ${_format(_start)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(false),
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text('Fin ${_format(_end)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Bloques predefinidos:', style: theme.textTheme.bodySmall),
              Wrap(
                spacing: 6,
                children: [
                  for (final (h, m) in _blocks)
                    ActionChip(
                      label: Text(_format(TimeOfDay(hour: h, minute: m))),
                      onPressed: () => setState(() {
                        _start = TimeOfDay(hour: h, minute: m);
                        final end = h * 60 + m + 90;
                        _end = TimeOfDay(hour: end ~/ 60, minute: end % 60);
                        _timeError = _validateTimes();
                      }),
                    ),
                ],
              ),
              if (_timeError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_timeError!, style: TextStyle(color: theme.colorScheme.error)),
                ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _submit, child: const Text('Guardar')),
            ],
          ),
        ),
      ),
    );
  }
}
