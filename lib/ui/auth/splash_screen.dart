import 'package:material_ui/material_ui.dart';

/// Pantalla breve mientras se restaura la sesión guardada.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('ESCOM Orienta'),
            ],
          ),
        ),
      );
}
