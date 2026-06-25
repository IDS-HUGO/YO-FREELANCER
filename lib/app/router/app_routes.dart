// lib/app/router/app_routes.dart

abstract class AppRoutes {
  static const splash         = '/splash';
  static const welcome        = '/welcome';
  static const login          = '/login';
  static const register       = '/register';

  // YOER
  static const yoerHome       = '/yoer/home';
  static const yoerVitrina    = '/yoer/vitrina';
  static const yoerProfile    = '/yoer/profile';
  static const yoerAgenda     = '/yoer/agenda';
  static const yoerRadar      = '/yoer/radar';

  // CLIENT
  static const clientHome     = '/client/home';
  static const clientBookings = '/client/bookings';
  static const clientProfile  = '/client/profile';
  static const clientPayments = '/client/payments';

  // Shared
  static const serviceDetail  = '/service/:id';
  static const createService  = '/service/create';
  static const bookingDetail  = '/booking/:id';
  static const payment        = '/payment/:bookingId';
}
