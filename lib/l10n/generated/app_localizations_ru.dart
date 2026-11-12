// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Kalan';

  @override
  String get languageNativeName => 'Русский';

  @override
  String get actionSave => 'Сохранить';

  @override
  String get actionCancel => 'Отмена';

  @override
  String get actionDelete => 'Удалить';

  @override
  String get actionEdit => 'Изменить';

  @override
  String get actionAddPlan => 'Добавить план';

  @override
  String get actionMoreDetails => 'Подробнее';

  @override
  String get navHome => 'Этот период';

  @override
  String get navPlans => 'Планы';

  @override
  String get navSettings => 'Настройки';

  @override
  String get frequencyMonthly => 'Раз в месяц';

  @override
  String get frequencyBiweekly => 'Раз в две недели';

  @override
  String get frequencyWeekly => 'Раз в неделю';

  @override
  String get onboardingTitle => 'Настроим за минуту.';

  @override
  String get onboardingIntro =>
      'Укажи, когда получаешь зарплату. Данные остаются на этом телефоне.';

  @override
  String get fieldCurrency => 'Валюта';

  @override
  String get fieldPayFrequency => 'Как часто ты получаешь зарплату?';

  @override
  String get fieldPayDay => 'День зарплаты';

  @override
  String get payDayHelp => 'В коротких месяцах считается последний день.';

  @override
  String get fieldLastPayday => 'Последняя зарплата';

  @override
  String get fieldPayWeekday => 'День зарплаты';

  @override
  String get fieldNetIncome => 'Зарплата на руки за раз';

  @override
  String get netIncomeHelp =>
      'Необязательно. Без этого покажу только то, что уже распределено.';

  @override
  String get onboardingStart => 'Начать';

  @override
  String get errorRequired => 'Это поле обязательно.';

  @override
  String errorAmountInvalid(String example) {
    return 'Введи сумму цифрами, например $example.';
  }

  @override
  String get errorCountInvalid => 'Введи число от 1 до 120.';

  @override
  String get errorRemainingTooHigh => 'Не может быть больше общего числа.';

  @override
  String get errorTotalTooSmall =>
      'Эту сумму нельзя разделить на столько платежей.';

  @override
  String get errorDayInvalid => 'Введи день от 1 до 31.';

  @override
  String get errorNameRequired => 'Введи название.';

  @override
  String get errorEndBeforeStart =>
      'Дата окончания не может быть раньше первой даты.';

  @override
  String get errorDeferInvalid => 'Введи число от 0 до 12.';

  @override
  String get errorStepInvalid => 'Введи число от 1 до 365.';

  @override
  String get errorCardRequired => 'Выбери карту.';

  @override
  String get homeLeftLabel => 'Остаётся';

  @override
  String get homeSpokenForLabel => 'Распределено';

  @override
  String get homeIncomeLabel => 'Доход';

  @override
  String periodRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String homeSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'В этом периоде $count платежа. Всего $total.',
      many: 'В этом периоде $count платежей. Всего $total.',
      few: 'В этом периоде $count платежа. Всего $total.',
      one: 'В этом периоде $count платёж. Всего $total.',
      zero: 'В этом периоде платежей нет.',
    );
    return '$_temp0';
  }

  @override
  String homeTight(String threshold) {
    return 'Напряжённый период. Остаток ниже твоего порога $threshold.';
  }

  @override
  String homeNegative(String amount) {
    return 'В этом периоде не хватает $amount.';
  }

  @override
  String get homeNoIncomeHint =>
      'Укажи зарплату на руки в настройках, и я покажу остаток.';

  @override
  String get homeOverdueTitle => 'Не оплачено';

  @override
  String get homeOverdueHelp =>
      'Дата прошла, а платёж не отмечен как оплаченный.';

  @override
  String get homePaymentsTitle => 'Платежи этого периода';

  @override
  String homeBarLabel(String spokenFor, String income) {
    return 'Из $income распределено $spokenFor.';
  }

  @override
  String progressLabel(int seq, int count) {
    return '$seq/$count';
  }

  @override
  String progressSemantics(int seq, int count) {
    return 'Платёж $seq из $count';
  }

  @override
  String get paidLabel => 'Оплачено';

  @override
  String get markAsPaid => 'Отметить как оплаченный';

  @override
  String get markAsUnpaid => 'Отметить как неоплаченный';

  @override
  String get markedPaid => 'Отмечено как оплаченное.';

  @override
  String get markedUnpaid => 'Отмечено как неоплаченное.';

  @override
  String get recurringTag => 'Регулярный';

  @override
  String get dueToday => 'Сегодня';

  @override
  String get dueTomorrow => 'Завтра';

  @override
  String get plansTabOpen => 'Открытые';

  @override
  String get plansTabRecurring => 'Регулярные';

  @override
  String get plansTabFinished => 'Завершённые';

  @override
  String get plansEmptyOpen => 'Открытых планов нет.';

  @override
  String get plansEmptyFinished =>
      'Завершённых планов пока нет. План попадает сюда, когда все платежи оплачены.';

  @override
  String get recurringEmpty =>
      'Регулярных платежей нет. Можно добавить аренду, счета или подписки.';

  @override
  String planPaidOf(int paid, int count) {
    return 'Оплачено $paid/$count';
  }

  @override
  String planToPay(String amount) {
    return 'К оплате $amount';
  }

  @override
  String planNext(String date) {
    return 'Следующий платёж $date';
  }

  @override
  String planTotal(String amount) {
    return 'Всего $amount';
  }

  @override
  String planPurchaseDate(String date) {
    return 'Покупка $date';
  }

  @override
  String planStartedMidway(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'До добавления плана было сделано $count платежа.',
      many: 'До добавления плана было сделано $count платежей.',
      few: 'До добавления плана было сделано $count платежа.',
      one: 'До добавления плана был сделан $count платёж.',
    );
    return '$_temp0';
  }

  @override
  String freeLimitReached(int limit) {
    return 'В бесплатной версии до $limit открытых планов. Новый можно добавить, когда один завершится.';
  }

  @override
  String get addRecurring => 'Добавить регулярный платёж';

  @override
  String get kindPayIn4 => 'Оплата в 4 платежа';

  @override
  String get kindMonthly => 'Ежемесячная рассрочка';

  @override
  String get kindCard => 'Рассрочка по карте';

  @override
  String get kindManual => 'Вручную';

  @override
  String get kindMidway => 'Уже начат';

  @override
  String get kindCashAdvance => 'Снятие наличных в рассрочку';

  @override
  String get planPaymentsTitle => 'Платежи';

  @override
  String get planDelete => 'Удалить план';

  @override
  String get planDeleteConfirm => 'План и все его платежи будут удалены.';

  @override
  String get planDeleted => 'План удалён.';

  @override
  String get planNotFound => 'Этого плана больше нет.';

  @override
  String get editPaymentTitle => 'Изменить платёж';

  @override
  String get editPaymentHelp =>
      'Разница распределяется на следующие платежи. Сумма плана не меняется.';

  @override
  String get editRejectedPaid =>
      'Оплаченный платёж нельзя изменить. Сначала отметь его как неоплаченный.';

  @override
  String get editRejectedNoAbsorbers =>
      'Нет следующего платежа, на который можно перенести разницу. Дату изменить можно.';

  @override
  String get editRejectedAbsorber =>
      'Это изменение обнулит следующий платёж. Попробуй изменить меньше.';

  @override
  String get editedTag => 'Изменён';

  @override
  String get paymentUpdated => 'Платёж обновлён.';

  @override
  String paymentRowSemantics(String name, String amount, String date) {
    return '$name, $amount, $date';
  }

  @override
  String get addPlanTitle => 'Добавить план';

  @override
  String get addPlanTypeLabel => 'Тип плана';

  @override
  String get fieldSource => 'Источник';

  @override
  String get fieldSourceHint => 'например, Klarna или твой банк';

  @override
  String get fieldCard => 'Карта';

  @override
  String get fieldTotal => 'Общая сумма';

  @override
  String get fieldCount => 'Число платежей';

  @override
  String get fieldFirstDate => 'Дата первого платежа';

  @override
  String get fieldPurchaseDate => 'Дата покупки';

  @override
  String get fieldIntervalStep => 'Каждые';

  @override
  String get fieldIntervalUnit => 'Единица';

  @override
  String get unitDays => 'дней';

  @override
  String get unitWeeks => 'недель';

  @override
  String get unitMonths => 'месяцев';

  @override
  String get fieldTotalCount => 'Всего платежей';

  @override
  String get fieldUnpaidCount => 'Неоплаченных платежей';

  @override
  String get fieldInstallment => 'Сумма платежа';

  @override
  String get fieldNextDate => 'Дата следующего платежа';

  @override
  String get fieldTitle => 'Название плана';

  @override
  String get fieldTitleHint => 'например, Телефон';

  @override
  String get fieldDefer => 'Отсрочка первого платежа (мес.)';

  @override
  String get fieldCashAdvance => 'Снятие наличных в рассрочку';

  @override
  String get noCards => 'Карт пока нет.';

  @override
  String get addCard => 'Добавить карту';

  @override
  String get previewTitle => 'Платежи';

  @override
  String previewSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count платежа, всего $total.',
      many: '$count платежей, всего $total.',
      few: '$count платежа, всего $total.',
      one: '$count платёж, всего $total.',
    );
    return '$_temp0';
  }

  @override
  String get previewEmpty => 'Заполни поля, и здесь появятся платежи.';

  @override
  String get planSaved => 'План добавлен.';

  @override
  String get fieldPaymentDate => 'Дата платежа';

  @override
  String get sourcesTitle => 'Источники и карты';

  @override
  String get sourcesEmpty =>
      'Источников пока нет. Те, что ты введёшь при добавлении плана, появятся здесь.';

  @override
  String get addSource => 'Добавить источник';

  @override
  String get editSource => 'Изменить источник';

  @override
  String get fieldName => 'Название';

  @override
  String get fieldSourceKind => 'Тип';

  @override
  String get sourceKindProvider => 'Сервис «купи сейчас, плати потом»';

  @override
  String get sourceKindCard => 'Кредитная карта';

  @override
  String get fieldStatementDay => 'Дата выписки';

  @override
  String get statementDayHelp => 'День месяца, когда формируется выписка.';

  @override
  String get fieldDueDay => 'Срок оплаты';

  @override
  String get dueDayHelp => 'День месяца, до которого нужно оплатить выписку.';

  @override
  String get fieldShiftWeekend =>
      'Переносить на следующий рабочий день, если выпадает на выходные';

  @override
  String get cardDaysChangeNote =>
      'Если изменить эти дни, даты неоплаченных и не изменённых платежей по карте пересчитаются.';

  @override
  String get sourceInUse =>
      'Этот источник используется в планах. Сначала удали эти планы.';

  @override
  String get sourceDeleted => 'Источник удалён.';

  @override
  String get sourceSaved => 'Сохранено.';

  @override
  String cardSummary(int statement, int due) {
    return 'Выписка $statement-го, оплата до $due-го';
  }

  @override
  String get recurringNewTitle => 'Добавить регулярный платёж';

  @override
  String get recurringEditTitle => 'Изменить регулярный платёж';

  @override
  String get fieldRecurringNameHint => 'например, Аренда';

  @override
  String get fieldAmount => 'Сумма';

  @override
  String get fieldRecurrence => 'Повтор';

  @override
  String get recurrenceWeekly => 'Каждую неделю';

  @override
  String get recurrenceBiweekly => 'Раз в две недели';

  @override
  String get recurrenceMonthly => 'Каждый месяц';

  @override
  String get recurrenceYearly => 'Каждый год';

  @override
  String get fieldEndDate => 'Дата окончания';

  @override
  String get noEndDate => 'Без даты окончания';

  @override
  String get clearEndDate => 'Убрать дату окончания';

  @override
  String get recurringDeleteConfirm => 'Этот регулярный платёж будет удалён.';

  @override
  String get recurringDeleted => 'Регулярный платёж удалён.';

  @override
  String get recurringSaved => 'Сохранено.';

  @override
  String recurringNext(String date) {
    return 'Следующий $date';
  }

  @override
  String get recurringEnded => 'Завершён';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get languageSystem => 'Язык системы';

  @override
  String get settingsCurrency => 'Валюта';

  @override
  String get settingsCurrencyNote =>
      'Суммы не пересчитываются, меняется только обозначение валюты.';

  @override
  String currencyName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'TRY': 'Турецкая лира',
      'USD': 'Доллар США',
      'EUR': 'Евро',
      'GBP': 'Британский фунт',
      'BRL': 'Бразильский реал',
      'MXN': 'Мексиканское песо',
      'COP': 'Колумбийское песо',
      'CLP': 'Чилийское песо',
      'RUB': 'Российский рубль',
      'KZT': 'Казахстанский тенге',
      'CNY': 'Китайский юань',
      'SGD': 'Сингапурский доллар',
      'MYR': 'Малайзийский ринггит',
      'IDR': 'Индонезийская рупия',
      'CAD': 'Канадский доллар',
      'AUD': 'Австралийский доллар',
      'CHF': 'Швейцарский франк',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get currencySearch => 'Найти валюту';

  @override
  String get currencyNoMatch => 'Такой валюты нет.';

  @override
  String get currencyChangeTitle => 'Сменить валюту';

  @override
  String currencyChangePreview(String before, String after) {
    return 'Пример: $before → $after';
  }

  @override
  String get currencyChangeRounding =>
      'У этой валюты другое число знаков после запятой, поэтому суммы округлятся.';

  @override
  String get currencyChangeConfirm => 'Сменить';

  @override
  String get settingsPay => 'Зарплата';

  @override
  String paySummaryMonthly(int day) {
    return 'Раз в месяц, $day-го числа';
  }

  @override
  String paySummaryBiweekly(String date) {
    return 'Раз в две недели, последняя зарплата $date';
  }

  @override
  String paySummaryWeekly(String weekday) {
    return 'Раз в неделю, $weekday';
  }

  @override
  String get settingsNetIncome => 'Зарплата на руки';

  @override
  String get notSet => 'Не указано';

  @override
  String get settingsTight => 'Порог напряжённого периода';

  @override
  String get settingsTightHelp =>
      'Период считается напряжённым, если остаток ниже этой суммы. Оставь пустым, чтобы отключить.';

  @override
  String get off => 'Выключено';

  @override
  String get settingsSources => 'Источники и карты';

  @override
  String get settingsRoadmap => 'Планы развития';

  @override
  String get settingsPrivacy =>
      'Данные хранятся только на этом телефоне. Без аккаунта, без подключения банка, без рекламы.';

  @override
  String get settingsDebugPro => 'Pro (только отладочные сборки)';

  @override
  String get settingsSaved => 'Сохранено.';

  @override
  String get roadmapEmpty => 'Пока здесь нечего показать.';

  @override
  String get roadmapError => 'Не удалось прочитать планы развития.';

  @override
  String get roadmapPlanned => 'Запланировано';

  @override
  String get roadmapInProgress => 'В работе';

  @override
  String get roadmapShipped => 'Выпущено';

  @override
  String roadmapTarget(String version) {
    return 'Целевая версия $version';
  }
}
