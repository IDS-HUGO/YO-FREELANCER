// test/app/config/backend_mode_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:yofreelancer/app/config/backend_mode.dart';

void main() {
  group('parseBackendMode', () {
    test("'own_backend' selecciona el backend propio", () {
      expect(parseBackendMode('own_backend'), BackendMode.ownBackend);
    });

    test("'supabase' selecciona Supabase", () {
      expect(parseBackendMode('supabase'), BackendMode.supabase);
    });

    test('cualquier otro valor (incluido vacío) usa Supabase por defecto', () {
      expect(parseBackendMode(''), BackendMode.supabase);
      expect(parseBackendMode('algo-invalido'), BackendMode.supabase);
      expect(parseBackendMode('OWN_BACKEND'), BackendMode.supabase); // sensible al case, a propósito
    });
  });

  test('BackendModeConfig.current usa el default (supabase) sin --dart-define', () {
    // Este test corre sin --dart-define=BACKEND_MODE=..., así que confirma
    // el comportamiento histórico de la app (hablar directo con Supabase)
    // sigue siendo el default. Para probar el otro modo de punta a punta,
    // correr: flutter test --dart-define=BACKEND_MODE=own_backend
    expect(BackendModeConfig.current, BackendMode.supabase);
  });
}
