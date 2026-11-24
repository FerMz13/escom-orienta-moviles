import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/auth/auth_models.dart';
import '../../navigation/app_routes.dart';
import '../common/common_widgets.dart';
import '../providers.dart';
import 'auth_controller.dart';

/// Recuperación local de contraseña mediante la pregunta de seguridad (RF1).
///
/// Paso 1: el usuario escribe su correo y se recupera su pregunta.
/// Paso 2: responde la pregunta y define una nueva contraseña.
class RecoverPasswordScreen extends ConsumerStatefulWidget {
  const RecoverPasswordScreen({super.key});

  @override
  ConsumerState<RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends ConsumerState<RecoverPasswordScreen> {
  final _email = TextEditingController();
  final _answer = TextEditingController();
  final _newPassword = TextEditingController();
  final _step2Key = GlobalKey<FormState>();
  String? _question;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _answer.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _lookupQuestion() async {
    final error = AuthValidators.email(_email.text);
    if (error != null) {
      showSnack(context, error);
      return;
    }
    setState(() => _busy = true);
    final question = await ref.read(authRepositoryProvider).securityQuestionFor(_email.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (question == null || question.isEmpty) {
      showSnack(context, 'No existe una cuenta con ese correo.');
      return;
    }
    setState(() => _question = question);
  }

  Future<void> _reset() async {
    if (!_step2Key.currentState!.validate()) return;
    setState(() => _busy = true);
    final result = await ref.read(authRepositoryProvider).recoverPassword(
          email: _email.text.trim(),
          securityAnswer: _answer.text,
          newPassword: _newPassword.text,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result case AuthFailure(:final message)) {
      showSnack(context, message);
      return;
    }
    // Inicia sesión automáticamente con la nueva contraseña.
    await ref.read(authControllerProvider.notifier).login(
          email: _email.text.trim(),
          password: _newPassword.text,
        );
    if (!mounted) return;
    showSnack(context, 'Contraseña actualizada.');
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _question == null ? _buildStep1() : _buildStep2(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Escribe el correo de tu cuenta para mostrar tu pregunta de seguridad.'),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _lookupQuestion,
            child: _busy
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Continuar'),
          ),
        ],
      );

  Widget _buildStep2() => Form(
        key: _step2Key,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_question!, style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _answer,
              decoration: const InputDecoration(
                labelText: 'Tu respuesta',
                prefixIcon: Icon(Icons.vpn_key_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) => AuthValidators.notEmpty(v, field: 'La respuesta'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPassword,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña',
                helperText: 'Mínimo 8 caracteres, con letras y números.',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: AuthValidators.password,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _reset,
              child: _busy
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Restablecer contraseña'),
            ),
          ],
        ),
      );
}
