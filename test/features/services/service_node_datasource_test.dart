// test/features/services/service_node_datasource_test.dart
//
// Confirma que, en modo "backend propio", las operaciones de "proyectos"
// (tabla `services`) hablan correctamente el contrato HTTP del backend
// standalone (ver docs/BACKEND_CONFIG.md), usando un adaptador Dio falso.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yofreelancer/features/services/data/datasources/service_node_datasource.dart';
import 'package:yofreelancer/features/services/domain/entities/service_entity.dart';

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

Map<String, dynamic> _serviceJson({String id = 'svc-1'}) => {
      'id': id,
      'yoer_id': 'user-1',
      'title': 'Reparación de tuberías',
      'description': 'Plomería a domicilio',
      'category': 'CONSTRUCCION',
      'specialties': <String>[],
      'service_type': 'A_DOMICILIO',
      'price_type': 'PRECIO_FIJO',
      'price': 350.0,
      'currency': 'MXN',
      'images': <String>[],
      'videos': <String>[],
      'is_active': true,
      'is_promoted': false,
      'requirements': <String>[],
      'included_items': <String>[],
      'created_at': '2026-01-01T00:00:00.000Z',
      'updated_at': '2026-01-01T00:00:00.000Z',
    };

ServiceEntity _serviceEntity() => ServiceEntity(
      id: 'svc-1',
      yoerId: 'user-1',
      yoerName: 'Ana',
      title: 'Reparación de tuberías',
      description: 'Plomería a domicilio',
      category: ServiceCategory.construccion,
      serviceType: ServiceType.aDomicilio,
      priceType: PriceType.precioFijo,
      price: 350.0,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  test('getAllServices: pagina correctamente contra el backend propio', () async {
    final dio = _dioWithHandler((options) {
      expect(options.path, '/services');
      expect(options.queryParameters['limit'], 20);
      expect(options.queryParameters['offset'], 0);
      return _json([_serviceJson()], 200);
    });
    final datasource = ServiceNodeDataSource(dio: dio, tokenProvider: () async => 'tok');

    final services = await datasource.getAllServices();

    expect(services, hasLength(1));
    expect(services.first.id, 'svc-1');
  });

  test('createService: envía el payload esperado y adjunta el token', () async {
    final dio = _dioWithHandler((options) {
      expect(options.path, '/services');
      expect(options.method, 'POST');
      expect(options.headers['Authorization'], 'Bearer tok-abc');
      final body = options.data as Map<String, dynamic>;
      expect(body['title'], 'Reparación de tuberías');
      return _json(_serviceJson(), 200);
    });
    final datasource = ServiceNodeDataSource(dio: dio, tokenProvider: () async => 'tok-abc');

    final created = await datasource.createService(_serviceEntity());

    expect(created.id, 'svc-1');
  });

  test('searchServices: manda el término de búsqueda como query param', () async {
    final dio = _dioWithHandler((options) {
      expect(options.path, '/services');
      expect(options.queryParameters['search'], 'plomería');
      return _json([_serviceJson()], 200);
    });
    final datasource = ServiceNodeDataSource(dio: dio, tokenProvider: () async => null);

    final results = await datasource.searchServices('plomería');

    expect(results, hasLength(1));
  });

  test('deleteService: llama DELETE al recurso correcto', () async {
    var called = false;
    final dio = _dioWithHandler((options) {
      called = true;
      expect(options.path, '/services/svc-1');
      expect(options.method, 'DELETE');
      return ResponseBody.fromString('', 204);
    });
    final datasource = ServiceNodeDataSource(dio: dio, tokenProvider: () async => 'tok');

    await datasource.deleteService('svc-1');

    expect(called, isTrue);
  });

  test('toggleServiceStatus: hace PATCH al endpoint de estado', () async {
    final dio = _dioWithHandler((options) {
      expect(options.path, '/services/svc-1/toggle-status');
      expect((options.data as Map<String, dynamic>)['is_active'], false);
      return _json(_serviceJson(), 200);
    });
    final datasource = ServiceNodeDataSource(dio: dio, tokenProvider: () async => 'tok');

    final updated = await datasource.toggleServiceStatus('svc-1', false);

    expect(updated.id, 'svc-1');
  });
}
