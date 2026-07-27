// test/features/auth/auth_node_datasource_test.dart
//
// Confirma que, cuando la app está configurada en modo "backend propio"
// (BackendMode.ownBackend), el datasource habla correctamente el contrato
// HTTP documentado en el proyecto standalone `yofreelancer-backend`
// (ver docs/BACKEND_CONFIG.md) — sin necesitar el backend real corriendo,
// usando un adaptador Dio falso.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yofreelancer/features/auth/data/datasources/auth_node_datasource.dart';
import 'package:yofreelancer/features/auth/domain/entities/user_entity.dart';

class _FakeAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) handler;
  _FakeAdapter(this.handler);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }
}

Dio _dioWithHandler(ResponseBody Function(RequestOptions options) handler) {
  final dio = Dio(BaseOptions(baseUrl: 'http://own-backend.test'));
  dio.httpClientAdapter = _FakeAdapter(handler);
  return dio;
}

ResponseBody _json(Object body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

Map<String, dynamic> _userJson({String id = 'user-1', String kycStatus = 'pending'}) => {
      'id': id,
      'email': 'ana@example.com',
      'username': 'ana',
      'full_name': 'Ana Pérez',
      'user_type': 'YOER',
      'status': 'DISPONIBLE',
      'kyc_status': kycStatus,
      'created_at': '2026-01-01T00:00:00.000Z',
      'updated_at': '2026-01-01T00:00:00.000Z',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Reinicia el almacenamiento seguro "en memoria" antes de cada test.
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('signUp: registra contra el backend propio y persiste la sesión', () async {
    final dio = _dioWithHandler((options) {
      expect(options.path, '/auth/register');
      expect(options.method, 'POST');
      final body = options.data as Map<String, dynamic>;
      expect(body['email'], 'ana@example.com');
      expect(body['user_type'], 'YOER');
      return _json({'user': _userJson(), 'token': 'tok-123'}, 200);
    });
    final datasource = AuthNodeDataSource(dio: dio);

    final user = await datasource.signUp(
      email: 'ana@example.com',
      password: 'supersecreta',
      username: 'ana',
      fullName: 'Ana Pérez',
      userType: UserType.yoer,
    );

    expect(user.id, 'user-1');
    expect(user.email, 'ana@example.com');
    expect(await datasource.isAuthenticated, isTrue);
    expect(await datasource.currentUserId, 'user-1');
  });

  test('signIn: inicia sesión contra el backend propio y guarda el token', () async {
    final dio = _dioWithHandler((options) {
      expect(options.path, '/auth/login');
      return _json({'user': _userJson(), 'token': 'tok-456'}, 200);
    });
    final datasource = AuthNodeDataSource(dio: dio);

    final user = await datasource.signIn(email: 'ana@example.com', password: 'supersecreta');

    expect(user.id, 'user-1');
    expect(await datasource.isAuthenticated, isTrue);
  });

  test('getCurrentUser: sin sesión previa devuelve null sin llamar a la red', () async {
    var called = false;
    final dio = _dioWithHandler((options) {
      called = true;
      return _json({}, 200);
    });
    final datasource = AuthNodeDataSource(dio: dio);

    final user = await datasource.getCurrentUser();

    expect(user, isNull);
    expect(called, isFalse);
  });

  test('getCurrentUser: con sesión previa, consulta el perfil con el token guardado', () async {
    // Primero deja una sesión guardada (p. ej. de un signIn anterior), con
    // su propio dio/handler dedicado a /auth/login.
    final loginDio = _dioWithHandler((options) {
      expect(options.path, '/auth/login');
      return _json({'user': _userJson(), 'token': 'tok-789'}, 200);
    });
    await AuthNodeDataSource(dio: loginDio).signIn(email: 'x', password: 'y');

    // El storage seguro (mockeado) es compartido entre instancias, así que
    // una nueva instancia con un dio distinto ya "ve" la sesión persistida.
    final datasource2 = AuthNodeDataSource(
      dio: _dioWithHandler((options) {
        expect(options.path, '/profile/user-1');
        expect(options.headers['Authorization'], 'Bearer tok-789');
        return _json(_userJson(), 200);
      }),
    );
    final user = await datasource2.getCurrentUser();
    expect(user?.id, 'user-1');
  });

  test('updateProfile: envía solo los campos no nulos y devuelve la entidad actualizada', () async {
    // Deja una sesión guardada primero (dio dedicado a /auth/register).
    final registerDio = _dioWithHandler(
      (options) => _json({'user': _userJson(), 'token': 'tok-1'}, 200),
    );
    await AuthNodeDataSource(dio: registerDio).signUp(
      email: 'ana@example.com',
      password: 'x',
      username: 'ana',
      fullName: 'Ana Pérez',
      userType: UserType.yoer,
    );

    final datasource = AuthNodeDataSource(
      dio: _dioWithHandler((options) {
        expect(options.path, '/profile/user-1');
        expect(options.method, 'PATCH');
        final body = options.data as Map<String, dynamic>;
        expect(body['full_name'], 'Ana P.');
        expect(body.containsKey('phone_number'), isFalse);
        return _json(_userJson(), 200);
      }),
    );

    final updated = await datasource.updateProfile(
      UserEntity(
        id: 'user-1',
        email: 'ana@example.com',
        username: 'ana',
        fullName: 'Ana P.',
        userType: UserType.yoer,
        status: UserStatus.disponible,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );

    expect(updated.id, 'user-1');
  });

  test('changePassword / resetPasswordForEmail: hablan con los endpoints propios del backend', () async {
    // Deja una sesión guardada primero (dio dedicado a /auth/register).
    final registerDio = _dioWithHandler(
      (options) => _json({'user': _userJson(), 'token': 'tok-1'}, 200),
    );
    await AuthNodeDataSource(dio: registerDio).signUp(
      email: 'ana@example.com',
      password: 'x',
      username: 'ana',
      fullName: 'Ana Pérez',
      userType: UserType.yoer,
    );

    final calledPaths = <String>[];
    final datasource = AuthNodeDataSource(
      dio: _dioWithHandler((options) {
        calledPaths.add(options.path);
        return _json({}, 200);
      }),
    );

    await datasource.changePassword('nueva-contraseña-larga');
    await datasource.resetPasswordForEmail('ana@example.com');

    expect(calledPaths, containsAll(['/auth/password', '/auth/reset-password']));
  });

  test('signOut: limpia la sesión localmente', () async {
    final dio = _dioWithHandler((options) => _json({'user': _userJson(), 'token': 't'}, 200));
    final datasource = AuthNodeDataSource(dio: dio);
    await datasource.signIn(email: 'a', password: 'b');
    expect(await datasource.isAuthenticated, isTrue);

    await datasource.signOut();

    expect(await datasource.isAuthenticated, isFalse);
    expect(await datasource.currentUserId, isNull);
  });
}
