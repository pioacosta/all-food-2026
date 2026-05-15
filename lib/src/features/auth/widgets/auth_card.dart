import 'package:flutter/material.dart';
import 'package:all_food/src/shared/theme/app_ui.dart';

// Contenedor visual comun para formularios de login/registro.
class AuthCard extends StatelessWidget {
  final List<Widget> children;

  const AuthCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    // Layout robusto para teclado: scroll + padding inferior dinámico.
    final keyboardBottom = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + keyboardBottom),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Card(
            color: Colors.transparent,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: Container(
                decoration: AppUi.panelDecoracion(radius: 22),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
