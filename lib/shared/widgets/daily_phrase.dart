// lib/shared/widgets/daily_phrase.dart
//
// Lema/saludo rotativo para YOERs, distinto según la hora del día y el día
// del año (docs/YOER.docx pide 365 lemas distintos; en vez de mantener 365
// strings casi idénticos se cicla un set curado por franja horaria, indexado
// por día del año — el usuario ve un lema distinto cada día igual).

const _morningPhrases = [
  'El día comienza antes del amanecer para los campeones.',
  'Hoy es un buen día para superarte.',
  'Cada mañana es una nueva oportunidad de demostrar tu talento.',
  'Empieza fuerte, termina mejor.',
  'Tu esfuerzo de hoy es el éxito de mañana.',
  'La constancia madruga contigo.',
  'Un gran YOER empieza el día con actitud.',
  'Hoy puede ser tu récord.',
  'El primer paso ya lo diste: te levantaste a triunfar.',
  'Disciplina y constancia vencen al talento sin acción.',
];

const _afternoonPhrases = [
  'A media tarde, la disciplina se nota más que el talento.',
  'Sigue avanzando: todo gran logro comienza pequeño.',
  'Tu trabajo habla por ti.',
  'El progreso diario construye resultados extraordinarios.',
  'No aflojes, ya vas a la mitad.',
  'Cada tarea bien hecha suma a tu reputación.',
  'La tarde es tuya, aprovéchala.',
  'Sigue así, se nota tu esfuerzo.',
];

const _nightPhrases = [
  'Mientras exista uno solo de nosotros, la construcción continuará…',
  'La noche también tiene oportunidades para quien se prepara.',
  'Termina el día como lo empezaste: con actitud.',
  'El descanso también es parte del éxito.',
  'Hoy diste lo mejor de ti, mañana será aún mejor.',
  'Buen trabajo hoy. Recarga y vuelve con todo mañana.',
];

/// Devuelve un lema distinto por franja horaria (mañana/tarde/noche, como
/// pide el doc de YOER) y por día del año, para que cambie cada día.
String dailyYoerPhrase({DateTime? now}) {
  final t = now ?? DateTime.now();
  final dayOfYear = t.difference(DateTime(t.year, 1, 1)).inDays;

  // A partir de las 18:30 se considera "noche" (turno de meseros, seguridad,
  // etc., como indica el doc de YOER).
  List<String> pool;
  if (t.hour < 12) {
    pool = _morningPhrases;
  } else if (t.hour < 18 || (t.hour == 18 && t.minute < 30)) {
    pool = _afternoonPhrases;
  } else {
    pool = _nightPhrases;
  }

  return pool[dayOfYear % pool.length];
}
