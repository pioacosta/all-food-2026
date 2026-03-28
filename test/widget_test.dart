import 'package:flutter_test/flutter_test.dart';

import 'package:all_food/src/all_food_app.dart';

void main() {
  testWidgets('Muestra la pantalla de inicio de sesion', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const AllFoodApp(
        supabaseReady: false,
        initializationMessage: 'Configuracion pendiente.',
      ),
    );

    expect(find.text('All Food'), findsOneWidget);
    expect(find.text('Inicio de sesión'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
