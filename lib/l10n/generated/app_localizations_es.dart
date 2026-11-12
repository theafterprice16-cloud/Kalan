// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Kalan';

  @override
  String get languageNativeName => 'Español';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionAddPlan => 'Añadir plan';

  @override
  String get actionMoreDetails => 'Más detalles';

  @override
  String get navHome => 'Este periodo';

  @override
  String get navPlans => 'Planes';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get frequencyMonthly => 'Mensual';

  @override
  String get frequencyBiweekly => 'Cada dos semanas';

  @override
  String get frequencyWeekly => 'Semanal';

  @override
  String get onboardingTitle => 'Lo configuramos en un minuto.';

  @override
  String get onboardingIntro =>
      'Dile a Kalan cuándo cobras. Tus datos se quedan en este teléfono.';

  @override
  String get fieldCurrency => 'Moneda';

  @override
  String get fieldPayFrequency => '¿Cada cuánto cobras?';

  @override
  String get fieldPayDay => 'Día de cobro';

  @override
  String get payDayHelp => 'En los meses más cortos cuenta el último día.';

  @override
  String get fieldLastPayday => 'Último día de cobro';

  @override
  String get fieldPayWeekday => 'Día de cobro';

  @override
  String get fieldNetIncome => 'Sueldo neto por cobro';

  @override
  String get netIncomeHelp => 'Opcional. Sin él, solo muestro lo comprometido.';

  @override
  String get onboardingStart => 'Empezar';

  @override
  String get errorRequired => 'Este campo es obligatorio.';

  @override
  String errorAmountInvalid(String example) {
    return 'Escribe el importe en números, por ejemplo $example.';
  }

  @override
  String get errorCountInvalid => 'Escribe un número del 1 al 120.';

  @override
  String get errorRemainingTooHigh => 'No puede ser mayor que el total.';

  @override
  String get errorTotalTooSmall =>
      'Este importe no se puede dividir en tantos pagos.';

  @override
  String get errorDayInvalid => 'Escribe un día del 1 al 31.';

  @override
  String get errorNameRequired => 'Escribe un nombre.';

  @override
  String get errorEndBeforeStart =>
      'La fecha de fin no puede ser anterior a la primera.';

  @override
  String get errorDeferInvalid => 'Escribe un número del 0 al 12.';

  @override
  String get errorStepInvalid => 'Escribe un número del 1 al 365.';

  @override
  String get errorCardRequired => 'Elige una tarjeta.';

  @override
  String get homeLeftLabel => 'Te queda';

  @override
  String get homeSpokenForLabel => 'Comprometido';

  @override
  String get homeIncomeLabel => 'Ingresos';

  @override
  String periodRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String homeSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Este periodo hay $count pagos. Total $total.',
      one: 'Este periodo hay 1 pago. Total $total.',
      zero: 'No hay pagos este periodo.',
    );
    return '$_temp0';
  }

  @override
  String homeTight(String threshold) {
    return 'Periodo ajustado. Lo que te queda está por debajo de tu umbral de $threshold.';
  }

  @override
  String homeNegative(String amount) {
    return 'Este periodo faltan $amount.';
  }

  @override
  String get homeNoIncomeHint =>
      'Añade tu sueldo neto en Ajustes para ver lo que te queda.';

  @override
  String get homeOverdueTitle => 'Sin pagar';

  @override
  String get homeOverdueHelp =>
      'La fecha ya pasó y no están marcados como pagados.';

  @override
  String get homePaymentsTitle => 'Pagos de este periodo';

  @override
  String homeBarLabel(String spokenFor, String income) {
    return '$spokenFor de $income ya está comprometido.';
  }

  @override
  String progressLabel(int seq, int count) {
    return '$seq/$count';
  }

  @override
  String progressSemantics(int seq, int count) {
    return 'Pago $seq de $count';
  }

  @override
  String get paidLabel => 'Pagado';

  @override
  String get markAsPaid => 'Marcar como pagado';

  @override
  String get markAsUnpaid => 'Marcar como no pagado';

  @override
  String get markedPaid => 'Marcado como pagado.';

  @override
  String get markedUnpaid => 'Marcado como no pagado.';

  @override
  String get recurringTag => 'Fijo';

  @override
  String get dueToday => 'Hoy';

  @override
  String get dueTomorrow => 'Mañana';

  @override
  String get plansTabOpen => 'Abiertos';

  @override
  String get plansTabRecurring => 'Fijos';

  @override
  String get plansTabFinished => 'Terminados';

  @override
  String get plansEmptyOpen => 'No hay planes abiertos.';

  @override
  String get plansEmptyFinished =>
      'Aún no hay planes terminados. Un plan pasa aquí cuando todos sus pagos están pagados.';

  @override
  String get recurringEmpty =>
      'No hay pagos fijos. Puedes añadir alquiler, facturas o suscripciones.';

  @override
  String planPaidOf(int paid, int count) {
    return '$paid/$count pagados';
  }

  @override
  String planToPay(String amount) {
    return 'Por pagar $amount';
  }

  @override
  String planNext(String date) {
    return 'Próximo pago $date';
  }

  @override
  String planTotal(String amount) {
    return 'Total $amount';
  }

  @override
  String planPurchaseDate(String date) {
    return 'Compra $date';
  }

  @override
  String planStartedMidway(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se hicieron $count pagos antes de añadir este plan.',
      one: 'Se hizo 1 pago antes de añadir este plan.',
    );
    return '$_temp0';
  }

  @override
  String freeLimitReached(int limit) {
    return 'La versión gratuita admite hasta $limit planes abiertos. Podrás añadir otro cuando termine uno.';
  }

  @override
  String get addRecurring => 'Añadir pago fijo';

  @override
  String get kindPayIn4 => 'Pago en 4';

  @override
  String get kindMonthly => 'Cuotas mensuales';

  @override
  String get kindCard => 'Cuotas con tarjeta';

  @override
  String get kindManual => 'Personalizado';

  @override
  String get kindMidway => 'Ya empezado';

  @override
  String get kindCashAdvance => 'Adelanto de efectivo en cuotas';

  @override
  String get planPaymentsTitle => 'Pagos';

  @override
  String get planDelete => 'Eliminar plan';

  @override
  String get planDeleteConfirm => 'Se eliminarán este plan y todos sus pagos.';

  @override
  String get planDeleted => 'Plan eliminado.';

  @override
  String get planNotFound => 'Este plan ya no existe.';

  @override
  String get editPaymentTitle => 'Corregir pago';

  @override
  String get editPaymentHelp =>
      'La diferencia se reparte entre los pagos siguientes. El total del plan no cambia.';

  @override
  String get editRejectedPaid =>
      'Un pago pagado no se puede corregir. Márcalo primero como no pagado.';

  @override
  String get editRejectedNoAbsorbers =>
      'No hay un pago posterior que absorba la diferencia. Aún puedes cambiar la fecha.';

  @override
  String get editRejectedAbsorber =>
      'Este cambio dejaría un pago posterior en cero. Prueba un cambio menor.';

  @override
  String get editedTag => 'Corregido';

  @override
  String get paymentUpdated => 'Pago actualizado.';

  @override
  String paymentRowSemantics(String name, String amount, String date) {
    return '$name, $amount, $date';
  }

  @override
  String get addPlanTitle => 'Añadir plan';

  @override
  String get addPlanTypeLabel => 'Tipo de plan';

  @override
  String get fieldSource => 'Origen';

  @override
  String get fieldSourceHint => 'p. ej. Klarna o tu banco';

  @override
  String get fieldCard => 'Tarjeta';

  @override
  String get fieldTotal => 'Importe total';

  @override
  String get fieldCount => 'Número de pagos';

  @override
  String get fieldFirstDate => 'Fecha del primer pago';

  @override
  String get fieldPurchaseDate => 'Fecha de compra';

  @override
  String get fieldIntervalStep => 'Cada';

  @override
  String get fieldIntervalUnit => 'Unidad';

  @override
  String get unitDays => 'días';

  @override
  String get unitWeeks => 'semanas';

  @override
  String get unitMonths => 'meses';

  @override
  String get fieldTotalCount => 'Pagos en total';

  @override
  String get fieldUnpaidCount => 'Pagos pendientes';

  @override
  String get fieldInstallment => 'Importe del pago';

  @override
  String get fieldNextDate => 'Fecha del próximo pago';

  @override
  String get fieldTitle => 'Nombre del plan';

  @override
  String get fieldTitleHint => 'p. ej. Teléfono';

  @override
  String get fieldDefer => 'Aplazar el primer pago (meses)';

  @override
  String get fieldCashAdvance => 'Adelanto de efectivo en cuotas';

  @override
  String get noCards => 'Aún no hay tarjetas.';

  @override
  String get addCard => 'Añadir tarjeta';

  @override
  String get previewTitle => 'Pagos';

  @override
  String previewSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pagos, $total en total.',
      one: '1 pago, $total en total.',
    );
    return '$_temp0';
  }

  @override
  String get previewEmpty => 'Completa los campos para ver aquí los pagos.';

  @override
  String get planSaved => 'Plan añadido.';

  @override
  String get fieldPaymentDate => 'Fecha de pago';

  @override
  String get sourcesTitle => 'Orígenes y tarjetas';

  @override
  String get sourcesEmpty =>
      'Aún no hay orígenes. Los que escribas al añadir un plan aparecerán aquí.';

  @override
  String get addSource => 'Añadir origen';

  @override
  String get editSource => 'Editar origen';

  @override
  String get fieldName => 'Nombre';

  @override
  String get fieldSourceKind => 'Tipo';

  @override
  String get sourceKindProvider => 'Servicio de compra ahora, paga después';

  @override
  String get sourceKindCard => 'Tarjeta de crédito';

  @override
  String get fieldStatementDay => 'Fecha de corte';

  @override
  String get statementDayHelp => 'El día del mes en que se cierra tu extracto.';

  @override
  String get fieldDueDay => 'Fecha límite de pago';

  @override
  String get dueDayHelp => 'El día del mes en que debes pagar el extracto.';

  @override
  String get fieldShiftWeekend =>
      'Pasar al siguiente día hábil si cae en fin de semana';

  @override
  String get cardDaysChangeNote =>
      'Si cambias estos días, se recalculan las fechas de los pagos pendientes y no corregidos de esta tarjeta.';

  @override
  String get sourceInUse =>
      'Hay planes que usan este origen. Elimina esos planes primero.';

  @override
  String get sourceDeleted => 'Origen eliminado.';

  @override
  String get sourceSaved => 'Guardado.';

  @override
  String cardSummary(int statement, int due) {
    return 'Fecha de corte $statement, fecha límite $due';
  }

  @override
  String get recurringNewTitle => 'Añadir pago fijo';

  @override
  String get recurringEditTitle => 'Editar pago fijo';

  @override
  String get fieldRecurringNameHint => 'p. ej. Alquiler';

  @override
  String get fieldAmount => 'Importe';

  @override
  String get fieldRecurrence => 'Se repite';

  @override
  String get recurrenceWeekly => 'Cada semana';

  @override
  String get recurrenceBiweekly => 'Cada dos semanas';

  @override
  String get recurrenceMonthly => 'Cada mes';

  @override
  String get recurrenceYearly => 'Cada año';

  @override
  String get fieldEndDate => 'Fecha de fin';

  @override
  String get noEndDate => 'Sin fecha de fin';

  @override
  String get clearEndDate => 'Quitar fecha de fin';

  @override
  String get recurringDeleteConfirm => 'Se eliminará este pago fijo.';

  @override
  String get recurringDeleted => 'Pago fijo eliminado.';

  @override
  String get recurringSaved => 'Guardado.';

  @override
  String recurringNext(String date) {
    return 'Próximo $date';
  }

  @override
  String get recurringEnded => 'Terminado';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get languageSystem => 'Idioma del sistema';

  @override
  String get settingsCurrency => 'Moneda';

  @override
  String get settingsCurrencyNote =>
      'Los importes no se convierten; solo cambia la etiqueta de la moneda.';

  @override
  String currencyName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'TRY': 'Lira turca',
      'USD': 'Dólar estadounidense',
      'EUR': 'Euro',
      'GBP': 'Libra esterlina',
      'BRL': 'Real brasileño',
      'MXN': 'Peso mexicano',
      'COP': 'Peso colombiano',
      'CLP': 'Peso chileno',
      'RUB': 'Rublo ruso',
      'KZT': 'Tenge kazajo',
      'CNY': 'Yuan chino',
      'SGD': 'Dólar de Singapur',
      'MYR': 'Ringgit malayo',
      'IDR': 'Rupia indonesia',
      'CAD': 'Dólar canadiense',
      'AUD': 'Dólar australiano',
      'CHF': 'Franco suizo',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get currencySearch => 'Buscar moneda';

  @override
  String get currencyNoMatch => 'Ninguna moneda coincide.';

  @override
  String get currencyChangeTitle => 'Cambiar moneda';

  @override
  String currencyChangePreview(String before, String after) {
    return 'Ejemplo: $before → $after';
  }

  @override
  String get currencyChangeRounding =>
      'Esta moneda usa otro número de decimales, así que los importes se redondean.';

  @override
  String get currencyChangeConfirm => 'Cambiar';

  @override
  String get settingsPay => 'Sueldo';

  @override
  String paySummaryMonthly(int day) {
    return 'Mensual, día $day';
  }

  @override
  String paySummaryBiweekly(String date) {
    return 'Cada dos semanas, último cobro $date';
  }

  @override
  String paySummaryWeekly(String weekday) {
    return 'Semanal, $weekday';
  }

  @override
  String get settingsNetIncome => 'Sueldo neto';

  @override
  String get notSet => 'Sin definir';

  @override
  String get settingsTight => 'Umbral de periodo ajustado';

  @override
  String get settingsTightHelp =>
      'Un periodo es ajustado cuando lo que te queda baja de este importe. Déjalo vacío para desactivarlo.';

  @override
  String get off => 'Desactivado';

  @override
  String get settingsSources => 'Orígenes y tarjetas';

  @override
  String get settingsRoadmap => 'Hoja de ruta';

  @override
  String get settingsPrivacy =>
      'Tus datos se quedan en este teléfono. Sin cuenta, sin conexión bancaria, sin anuncios.';

  @override
  String get settingsDebugPro => 'Pro (solo en compilaciones debug)';

  @override
  String get settingsSaved => 'Guardado.';

  @override
  String get roadmapEmpty => 'Por ahora no hay nada que compartir aquí.';

  @override
  String get roadmapError => 'No se pudo leer la hoja de ruta.';

  @override
  String get roadmapPlanned => 'Planeado';

  @override
  String get roadmapInProgress => 'En curso';

  @override
  String get roadmapShipped => 'Publicado';

  @override
  String roadmapTarget(String version) {
    return 'Versión prevista $version';
  }
}
