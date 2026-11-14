// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Kalan';

  @override
  String get actionSave => 'Kaydet';

  @override
  String get actionCancel => 'Vazgeç';

  @override
  String get actionUndo => 'Geri al';

  @override
  String get actionDelete => 'Sil';

  @override
  String get actionEdit => 'Düzenle';

  @override
  String get actionAddPlan => 'Plan ekle';

  @override
  String get actionMoreDetails => 'Ayrıntı ekle';

  @override
  String get navHome => 'Bu dönem';

  @override
  String get navPlans => 'Planlar';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get frequencyMonthly => 'Ayda bir';

  @override
  String get frequencyBiweekly => 'İki haftada bir';

  @override
  String get frequencyWeekly => 'Haftada bir';

  @override
  String get onboardingTitle => 'Bir dakikada kuralım.';

  @override
  String get onboardingIntro =>
      'Maaşının ne zaman yattığını söyle, gerisini Kalan hesaplasın. Veriler yalnızca bu telefonda durur.';

  @override
  String get fieldCurrency => 'Para birimi';

  @override
  String get fieldPayFrequency => 'Maaş ne sıklıkla yatıyor?';

  @override
  String get fieldPayDay => 'Maaş günü';

  @override
  String get payDayHelp => 'Ay kısaysa ayın son günü sayılır.';

  @override
  String get fieldLastPayday => 'Son maaş tarihi';

  @override
  String get fieldPayWeekday => 'Maaş günü';

  @override
  String get fieldNetIncome => 'Bir maaşın net tutarı';

  @override
  String get netIncomeHelp =>
      'İsteğe bağlı. Girmezsen yalnızca söz verilmiş tutarı gösteririm.';

  @override
  String get onboardingStart => 'Başla';

  @override
  String get errorRequired => 'Bu alan gerekli.';

  @override
  String errorAmountInvalid(String example) {
    return 'Tutarı rakamla yaz, örneğin $example.';
  }

  @override
  String get errorCountInvalid => '1 ile 120 arasında bir sayı yaz.';

  @override
  String get errorTotalTooSmall => 'Bu tutar bu kadar ödemeye bölünemiyor.';

  @override
  String get errorDayInvalid => '1 ile 31 arasında bir gün yaz.';

  @override
  String get errorNameRequired => 'Bir ad yaz.';

  @override
  String get errorEndBeforeStart => 'Bitiş tarihi ilk tarihten önce olamaz.';

  @override
  String get errorDeferInvalid => '0 ile 12 arasında bir sayı yaz.';

  @override
  String get errorStepInvalid => '1 ile 365 arasında bir sayı yaz.';

  @override
  String get errorCardRequired => 'Bir kart seç.';

  @override
  String get homeLeftLabel => 'Kalan';

  @override
  String get homeSpokenForLabel => 'Söz verilmiş';

  @override
  String get homeIncomeLabel => 'Gelir';

  @override
  String periodRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String homeSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bu dönem $count ödeme var. Toplam $total.',
      one: 'Bu dönem 1 ödeme var. Toplam $total.',
      zero: 'Bu dönem ödeme yok.',
    );
    return '$_temp0';
  }

  @override
  String homeTight(String threshold) {
    return 'Sıkışık dönem. Kalan, belirlediğin $threshold eşiğinin altında.';
  }

  @override
  String homeNegative(String amount) {
    return 'Bu dönem $amount eksik kalıyor.';
  }

  @override
  String get homeNoIncomeHint =>
      'Net tutarı Ayarlar\'da girersen kalanı da gösteririm.';

  @override
  String get homePaymentsTitle => 'Bu dönemin ödemeleri';

  @override
  String homeBarLabel(String spokenFor, String income) {
    return '$income gelirin $spokenFor kadarı söz verilmiş.';
  }

  @override
  String progressLabel(int seq, int count) {
    return '$seq/$count';
  }

  @override
  String progressSemantics(int seq, int count) {
    return '$count ödemenin $seq. ödemesi';
  }

  @override
  String get paidLabel => 'Ödendi';

  @override
  String get markAsPaid => 'Ödendi olarak işaretle';

  @override
  String get markAsUnpaid => 'Ödenmedi olarak işaretle';

  @override
  String get markedPaid => 'Ödendi olarak işaretlendi.';

  @override
  String get markedUnpaid => 'Ödenmedi olarak işaretlendi.';

  @override
  String get recurringTag => 'Sabit';

  @override
  String get dueToday => 'Bugün';

  @override
  String get dueTomorrow => 'Yarın';

  @override
  String get plansTabOpen => 'Açık';

  @override
  String get plansTabRecurring => 'Sabit';

  @override
  String get plansTabFinished => 'Biten';

  @override
  String get plansEmptyOpen => 'Açık plan yok.';

  @override
  String get plansEmptyFinished =>
      'Biten plan yok. Bir planın bütün ödemeleri ödenince buraya gelir.';

  @override
  String get recurringEmpty =>
      'Sabit ödeme yok. Kira, fatura ya da abonelik ekleyebilirsin.';

  @override
  String planToPay(String amount) {
    return 'Ödenecek $amount';
  }

  @override
  String planNext(String date) {
    return 'Sonraki ödeme $date';
  }

  @override
  String planTotal(String amount) {
    return 'Toplam $amount';
  }

  @override
  String planPurchaseDate(String date) {
    return 'Alışveriş $date';
  }

  @override
  String planStartedMidway(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bu plan eklenmeden önce $count ödeme yapılmış.',
    );
    return '$_temp0';
  }

  @override
  String freeLimitReached(int limit) {
    return 'Ücretsiz sürümde en çok $limit açık plan olur. Bir plan bitince yenisini ekleyebilirsin.';
  }

  @override
  String get addRecurring => 'Sabit ödeme ekle';

  @override
  String get kindPayIn4 => '4 ödemeli plan';

  @override
  String get kindMonthly => 'Aylık taksit';

  @override
  String get kindCard => 'Kredi kartı taksidi';

  @override
  String get kindManual => 'Elle giriş';

  @override
  String get kindCashAdvance => 'Taksitli nakit avans';

  @override
  String get planPaymentsTitle => 'Ödemeler';

  @override
  String get planDelete => 'Planı sil';

  @override
  String get planDeleteConfirm => 'Bu plan ve bütün ödemeleri silinecek.';

  @override
  String get planDeleted => 'Plan silindi.';

  @override
  String get planNotFound => 'Bu plan artık yok.';

  @override
  String get editPaymentTitle => 'Ödemeyi düzelt';

  @override
  String get editPaymentHelp =>
      'Fark sonraki ödemelere dağıtılır. Plan toplamı değişmez.';

  @override
  String get editRejectedPaid =>
      'Ödenmiş bir ödeme düzeltilemez. Önce ödenmedi olarak işaretle.';

  @override
  String get editRejectedNoAbsorbers =>
      'Farkı alacak sonraki ödeme yok. Yalnızca tarihi değiştirebilirsin.';

  @override
  String get editRejectedAbsorber =>
      'Bu değişiklik sonraki bir ödemeyi sıfıra indiriyor. Daha küçük bir değişiklik dene.';

  @override
  String get editedTag => 'Düzeltildi';

  @override
  String get paymentUpdated => 'Ödeme güncellendi.';

  @override
  String paymentRowSemantics(String name, String amount, String date) {
    return '$name, $amount, $date';
  }

  @override
  String get addPlanTitle => 'Plan ekle';

  @override
  String get addPlanTypeLabel => 'Plan türü';

  @override
  String get fieldSource => 'Kaynak';

  @override
  String get fieldSourceHint => 'Örneğin Klarna ya da banka adı';

  @override
  String get fieldCard => 'Kart';

  @override
  String get fieldTotal => 'Toplam tutar';

  @override
  String get fieldCount => 'Ödeme sayısı';

  @override
  String get fieldFirstDate => 'İlk ödeme tarihi';

  @override
  String get fieldPurchaseDate => 'Alışveriş tarihi';

  @override
  String get fieldIntervalStep => 'Aralık';

  @override
  String get fieldIntervalUnit => 'Birim';

  @override
  String get unitDays => 'gün';

  @override
  String get unitWeeks => 'hafta';

  @override
  String get unitMonths => 'ay';

  @override
  String get fieldTitle => 'Plan adı';

  @override
  String get fieldTitleHint => 'Örneğin Telefon';

  @override
  String get fieldDefer => 'İlk ödemeyi ertele (ay)';

  @override
  String get fieldCashAdvance => 'Taksitli nakit avans';

  @override
  String get noCards => 'Henüz kart yok.';

  @override
  String get addCard => 'Kart ekle';

  @override
  String get previewTitle => 'Ödemeler';

  @override
  String previewSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ödeme, toplam $total.',
    );
    return '$_temp0';
  }

  @override
  String get previewEmpty => 'Alanları doldurunca ödemeleri burada görürsün.';

  @override
  String get planSaved => 'Plan eklendi.';

  @override
  String get fieldPaymentDate => 'Ödeme tarihi';

  @override
  String get sourcesTitle => 'Kaynaklar ve kartlar';

  @override
  String get sourcesEmpty =>
      'Henüz kaynak yok. Plan eklerken yazdığın kaynaklar burada görünür.';

  @override
  String get addSource => 'Kaynak ekle';

  @override
  String get editSource => 'Kaynağı düzenle';

  @override
  String get fieldName => 'Ad';

  @override
  String get fieldSourceKind => 'Tür';

  @override
  String get sourceKindProvider => 'Sonra öde sağlayıcısı';

  @override
  String get sourceKindCard => 'Kredi kartı';

  @override
  String get fieldStatementDay => 'Ekstre günü';

  @override
  String get statementDayHelp => 'Hesap kesim günü, ayın kaçı.';

  @override
  String get fieldDueDay => 'Son ödeme günü';

  @override
  String get dueDayHelp => 'Ekstrenin ödenmesi gereken son gün, ayın kaçı.';

  @override
  String get fieldShiftWeekend =>
      'Hafta sonuna denk gelirse sonraki iş gününe kaydır';

  @override
  String get cardDaysChangeNote =>
      'Bu günleri değiştirirsen bu karttaki ödenmemiş ve düzeltilmemiş ödemelerin tarihleri yeniden hesaplanır.';

  @override
  String get sourceInUse =>
      'Bu kaynağa bağlı planlar var. Önce o planları sil.';

  @override
  String get sourceDeleted => 'Kaynak silindi.';

  @override
  String get sourceSaved => 'Kaydedildi.';

  @override
  String cardSummary(int statement, int due) {
    return 'Ekstre günü $statement, son ödeme günü $due';
  }

  @override
  String get recurringNewTitle => 'Sabit ödeme ekle';

  @override
  String get recurringEditTitle => 'Sabit ödemeyi düzenle';

  @override
  String get fieldRecurringNameHint => 'Örneğin Kira';

  @override
  String get fieldAmount => 'Tutar';

  @override
  String get fieldRecurrence => 'Tekrar';

  @override
  String get recurrenceWeekly => 'Her hafta';

  @override
  String get recurrenceBiweekly => 'İki haftada bir';

  @override
  String get recurrenceMonthly => 'Her ay';

  @override
  String get recurrenceYearly => 'Her yıl';

  @override
  String get fieldEndDate => 'Bitiş tarihi';

  @override
  String get noEndDate => 'Bitiş yok';

  @override
  String get clearEndDate => 'Bitiş tarihini kaldır';

  @override
  String get recurringDeleteConfirm => 'Bu sabit ödeme silinecek.';

  @override
  String get recurringDeleted => 'Sabit ödeme silindi.';

  @override
  String get recurringSaved => 'Kaydedildi.';

  @override
  String recurringNext(String date) {
    return 'Sonraki $date';
  }

  @override
  String get recurringEnded => 'Bitti';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get languageSystem => 'Sistem dili';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageEnglish => 'English';

  @override
  String get settingsCurrency => 'Para birimi';

  @override
  String get settingsCurrencyNote =>
      'Tutarlar çevrilmez, yalnızca para birimi etiketi değişir.';

  @override
  String currencyName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'TRY': 'Türk lirası',
      'USD': 'ABD doları',
      'EUR': 'Euro',
      'GBP': 'İngiliz sterlini',
      'BRL': 'Brezilya reali',
      'MXN': 'Meksika pesosu',
      'COP': 'Kolombiya pesosu',
      'CLP': 'Şili pesosu',
      'RUB': 'Rus rublesi',
      'KZT': 'Kazak tengesi',
      'CNY': 'Çin yuanı',
      'SGD': 'Singapur doları',
      'MYR': 'Malezya ringgiti',
      'IDR': 'Endonezya rupisi',
      'CAD': 'Kanada doları',
      'AUD': 'Avustralya doları',
      'CHF': 'İsviçre frangı',
      'NZD': 'Yeni Zelanda doları',
      'ZAR': 'Güney Afrika randı',
      'ARS': 'Arjantin pesosu',
      'PEN': 'Peru solü',
      'UYU': 'Uruguay pesosu',
      'PYG': 'Paraguay guaranisi',
      'BOB': 'Bolivya bolivianosu',
      'VES': 'Venezuela bolivarı',
      'CRC': 'Kosta Rika kolonu',
      'GTQ': 'Guatemala quetzalı',
      'HNL': 'Honduras lempirası',
      'NIO': 'Nikaragua kordobası',
      'DOP': 'Dominik pesosu',
      'PAB': 'Panama balboası',
      'AOA': 'Angola kvanzası',
      'MZN': 'Mozambik metikali',
      'XOF': 'Batı Afrika CFA frangı',
      'XAF': 'Orta Afrika CFA frangı',
      'BYN': 'Belarus rublesi',
      'KGS': 'Kırgızistan somu',
      'UZS': 'Özbekistan somu',
      'TWD': 'Yeni Tayvan doları',
      'HKD': 'Hong Kong doları',
      'MOP': 'Makao patakası',
      'SAR': 'Suudi riyali',
      'AED': 'BAE dirhemi',
      'QAR': 'Katar riyali',
      'KWD': 'Kuveyt dinarı',
      'BHD': 'Bahreyn dinarı',
      'OMR': 'Umman riyali',
      'EGP': 'Mısır lirası',
      'JOD': 'Ürdün dinarı',
      'IQD': 'Irak dinarı',
      'MAD': 'Fas dirhemi',
      'DZD': 'Cezayir dinarı',
      'TND': 'Tunus dinarı',
      'LBP': 'Lübnan lirası',
      'LYD': 'Libya dinarı',
      'INR': 'Hindistan rupisi',
      'PKR': 'Pakistan rupisi',
      'NGN': 'Nijerya nairası',
      'PHP': 'Filipin pesosu',
      'KES': 'Kenya şilini',
      'CDF': 'Kongo frangı',
      'GNF': 'Gine frangı',
      'HTG': 'Haiti gurdu',
      'MGA': 'Madagaskar ariarisi',
      'SRD': 'Surinam doları',
      'TJS': 'Tacikistan somonisi',
      'SDG': 'Sudan lirası',
      'YER': 'Yemen riyali',
      'SYP': 'Suriye lirası',
      'MRU': 'Moritanya ugiyası',
      'ILS': 'İsrail şekeli',
      'PLN': 'Polonya zlotisi',
      'SEK': 'İsveç kronu',
      'JPY': 'Japon yeni',
      'VND': 'Vietnam dongu',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get currencySearch => 'Para birimi ara';

  @override
  String get currencyNoMatch => 'Eşleşen para birimi yok.';

  @override
  String get currencySuggested => 'Önerilen';

  @override
  String get currencyAll => 'Tüm para birimleri';

  @override
  String get currencyChangeTitle => 'Para birimini değiştir';

  @override
  String currencyChangePreview(String before, String after) {
    return 'Örnek: $before → $after';
  }

  @override
  String get currencyChangeRounding =>
      'Bu para biriminin ondalık sayısı farklı, tutarlar yuvarlanır.';

  @override
  String get currencyChangeConfirm => 'Değiştir';

  @override
  String get settingsPay => 'Maaş';

  @override
  String paySummaryMonthly(int day) {
    return 'Ayda bir, ayın $day. günü';
  }

  @override
  String paySummaryBiweekly(String date) {
    return 'İki haftada bir, son maaş $date';
  }

  @override
  String paySummaryWeekly(String weekday) {
    return 'Haftada bir, $weekday';
  }

  @override
  String get settingsNetIncome => 'Net tutar';

  @override
  String get notSet => 'Girilmedi';

  @override
  String get settingsTight => 'Sıkışık dönem eşiği';

  @override
  String get settingsTightHelp =>
      'Kalan bu tutarın altına düşerse dönem sıkışık sayılır. Boş bırakırsan kapalı olur.';

  @override
  String get off => 'Kapalı';

  @override
  String get settingsSources => 'Kaynaklar ve kartlar';

  @override
  String get settingsRoadmap => 'Yol Haritası';

  @override
  String get settingsPrivacy =>
      'Veriler yalnızca bu telefonda durur. Hesap, banka bağlantısı ve reklam yok.';

  @override
  String get settingsDebugPro => 'Pro (yalnızca debug derlemede)';

  @override
  String get settingsSaved => 'Kaydedildi.';

  @override
  String get roadmapEmpty => 'Şu an burada paylaşılacak bir şey yok.';

  @override
  String get roadmapError => 'Yol haritası okunamadı.';

  @override
  String get roadmapPlanned => 'Planlandı';

  @override
  String get roadmapInProgress => 'Yapılıyor';

  @override
  String get roadmapShipped => 'Yayınlandı';

  @override
  String roadmapTarget(String version) {
    return 'Hedef sürüm $version';
  }

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get reminderChannelName => 'Ödeme hatırlatmaları';

  @override
  String get reminderChannelDescription =>
      'Ödeme gününden önce kısa hatırlatmalar.';

  @override
  String get reminderPromptTitle => 'Hatırlatmalar';

  @override
  String get reminderPromptBody =>
      'Ödeme gününden önce sana haber verelim. Hatırlatmalar yalnızca bu telefonda kurulur.';

  @override
  String get reminderPromptAccept => 'Hatırlatmaları aç';

  @override
  String get reminderPromptLater => 'Şimdi değil';

  @override
  String get settingsReminders => 'Hatırlatmalar';

  @override
  String get remindersEnabled => 'Hatırlatmalar';

  @override
  String get reminderTime => 'Saat';

  @override
  String get remindersPermissionOff => 'Bildirim izni kapalı';

  @override
  String get openPhoneSettings => 'Ayarları aç';

  @override
  String get remindersHelpLink => 'Bildirimler gelmiyor mu?';

  @override
  String get remindersHelpIntro =>
      'Telefonun hatırlatmaları bekletebilir. En sık nedenler bunlar.';

  @override
  String get remindersHelpPermissionTitle => 'Bildirim izni';

  @override
  String get remindersHelpPermissionBody =>
      'Telefon ayarlarını aç, Kalan’ı bul ve bildirimleri aç.';

  @override
  String get remindersHelpIosTitle => 'iPhone: Odak';

  @override
  String get remindersHelpIosBody =>
      'Rahatsız Etme ya da Uyku gibi bir Odak modu hatırlatmaları susturabilir. Ayarlar > Odak bölümünde modu seç ve İzin Verilen Uygulamalar’a Kalan’ı ekle.';

  @override
  String get remindersHelpAndroidTitle => 'Android: pil tasarrufu';

  @override
  String get remindersHelpAndroidBody =>
      'Pil tasarrufu hatırlatmaları geciktirebilir. Ayarlar > Uygulamalar > Kalan > Pil bölümünde Kısıtlanmamış’ı seç. Hatırlatmalar yine de birkaç dakika geç gelebilir.';

  @override
  String get remindersWebOnly => 'Bu özellik telefonda çalışır.';

  @override
  String get debugTestNotification => 'Deneme bildirimi (10 saniye sonra)';

  @override
  String get testNotificationScheduled =>
      '10 saniye içinde bir deneme bildirimi gelecek.';

  @override
  String get testNotificationText =>
      'Deneme: hatırlatmalar bu telefonda çalışıyor.';

  @override
  String get reminderActionPaid => 'Ödendi';

  @override
  String get reminderActionAllPaid => 'Hepsi ödendi';

  @override
  String get reminderActionRemindTonight => 'Akşam hatırlat';

  @override
  String get reminderActionRemindTomorrow => 'Yarın hatırlat';

  @override
  String get debugTestReminderActions =>
      'Eylemli deneme bildirimi (10 saniye sonra)';

  @override
  String get testReminderNoPayment => 'Denemek için ödenmemiş ödeme yok.';

  @override
  String get remindersEnabledHint => 'Ödeme gününden önce ve ödeme günü';

  @override
  String reminderAhead(int count, String date, String name, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$date günü $count ödeme var, toplam $total',
      one: '$date günü 1 ödeme var: $name, $total',
    );
    return '$_temp0';
  }

  @override
  String reminderAheadHidden(int count, String date, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$date günü $count ödeme var',
      one: '$date günü 1 ödeme var: $name',
    );
    return '$_temp0';
  }

  @override
  String reminderAheadMixed(int count, String date, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$date gününden itibaren $count ödeme var, toplam $total',
      one: '$date gününden itibaren 1 ödeme var, toplam $total',
    );
    return '$_temp0';
  }

  @override
  String reminderAheadMixedHidden(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$date gününden itibaren $count ödeme var',
      one: '$date gününden itibaren 1 ödeme var',
    );
    return '$_temp0';
  }

  @override
  String reminderToday(int count, String name, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bugün $count ödeme var, toplam $total',
      one: 'Bugün 1 ödeme var: $name, $total',
    );
    return '$_temp0';
  }

  @override
  String reminderTodayHidden(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bugün $count ödeme var',
      one: 'Bugün 1 ödeme var: $name',
    );
    return '$_temp0';
  }

  @override
  String reminderExpanded(String body, String names) {
    return '$body\n$names';
  }

  @override
  String get reminderNameSeparator => ', ';

  @override
  String get reminderLeadDays => 'Kaç gün önce';

  @override
  String reminderLeadDaysValue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days gün önce',
      one: '1 gün önce',
    );
    return '$_temp0';
  }

  @override
  String reminderLeadDaysSemantics(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days gün',
      one: '1 gün',
    );
    return 'Kaç gün önce, şu an $_temp0';
  }

  @override
  String get reminderShowAmount => 'Bildirimde tutarı göster';

  @override
  String get planReminder => 'Hatırlatma';

  @override
  String planReminderGeneral(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days gün önce',
      one: '1 gün önce',
    );
    return 'Genel ayar ($_temp0)';
  }

  @override
  String get planReminderOff => 'Kapalı';

  @override
  String get planReminderCustom => 'Farklı gün';

  @override
  String get underwayToggle => 'Bu plan zaten sürüyor';

  @override
  String get underwayHint =>
      'Daha önce ödediğin taksitleri tek tek girmen gerekmez.';

  @override
  String get fieldTotalInstallments => 'Toplam taksit';

  @override
  String get fieldPaidInstallments => 'Ödenmiş taksit';

  @override
  String get fieldNextPaymentDate => 'Sıradaki ödeme tarihi';

  @override
  String get underwayCardSuggested => 'Kartının kesim gününe göre önerildi.';

  @override
  String get errorPaidAll =>
      'Bütün taksitler ödendiyse bu planı eklemene gerek yok.';

  @override
  String get errorPaidMin => 'Kaç taksit ödediğini yaz, en az 1.';

  @override
  String errorPaidMax(int max) {
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'Burada en fazla $maxString olabilir.',
    );
    return '$_temp0';
  }

  @override
  String paidBeforeSummary(int count, String amount) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString taksit Kalan\'dan önce ödendi',
    );
    return '$_temp0 · $amount';
  }

  @override
  String progressPaidOfSemantics(int paid, int total) {
    final intl.NumberFormat paidNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String paidString = paidNumberFormat.format(paid);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$totalString taksitten $paidString tanesi ödendi',
    );
    return '$_temp0';
  }

  @override
  String planPaidOf(int paid, int count) {
    final intl.NumberFormat paidNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String paidString = paidNumberFormat.format(paid);
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$paidString/$countString ödendi';
  }

  @override
  String numberValue(int value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '$valueString';
  }

  @override
  String get planEdit => 'Planı düzenle';

  @override
  String get planUpdated => 'Plan güncellendi.';

  @override
  String underwayRevert(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString taksit ödenmemiş olarak geri gelecek.',
    );
    return '$_temp0';
  }

  @override
  String get underwayRevertConfirm => 'Devam et';

  @override
  String get resizeHint =>
      'Plan toplamı aynı kalır; ödenmemiş taksitler yeniden bölünür.';

  @override
  String errorCountMin(int min) {
    final intl.NumberFormat minNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String minString = minNumberFormat.format(min);

    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'Burada en az $minString olabilir; ödenmiş taksitler kalır.',
    );
    return '$_temp0';
  }

  @override
  String pastDueTitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Günü geçen $countString ödeme',
      one: 'Günü geçen 1 ödeme',
    );
    return '$_temp0';
  }

  @override
  String pastDueDaysAgo(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$daysString gün önce',
      one: '1 gün önce',
    );
    return '$_temp0';
  }

  @override
  String get pastDueDeducted =>
      'Ödenmemiş olanlar bu dönemin kalanından düşüldü.';

  @override
  String get pastDueMarkPaid => 'Ödendi';

  @override
  String pastDueShowAll(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tümünü göster ($countString)',
    );
    return '$_temp0';
  }

  @override
  String pastDueRowSemantics(String plan, String amount, int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$plan, $amount, son ödeme günü $daysString gün önce geçti',
      one: '$plan, $amount, son ödeme günü 1 gün önce geçti',
    );
    return '$_temp0';
  }

  @override
  String get paidWhenTitle => 'Ne zaman ödedin?';

  @override
  String get paidWhenToday => 'Bugün';

  @override
  String get paidWhenTodayHint => 'Bu dönemin hesabında kalır.';

  @override
  String paidWhenOnDue(String date) {
    return 'Gününde, $date';
  }

  @override
  String get paidWhenOnDueHint => 'Ödeme o döneme yazılır.';

  @override
  String reminderOverdue(
    int count,
    String date,
    String month,
    String name,
    String total,
  ) {
    String _temp0 = intl.Intl.selectLogic(month, {
      '1': '$date\'taki',
      '2': '$date\'taki',
      '3': '$date\'taki',
      '4': '$date\'daki',
      '5': '$date\'taki',
      '6': '$date\'daki',
      '7': '$date\'daki',
      '8': '$date\'taki',
      '9': '$date\'deki',
      '10': '$date\'deki',
      '11': '$date\'daki',
      '12': '$date\'taki',
      'other': '$date',
    });
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ödeme henüz işaretlenmedi, toplam $total',
      one: '$_temp0 1 ödeme henüz işaretlenmedi: $name, $total',
    );
    return '$_temp1';
  }

  @override
  String reminderOverdueHidden(
    int count,
    String date,
    String month,
    String name,
  ) {
    String _temp0 = intl.Intl.selectLogic(month, {
      '1': '$date\'taki',
      '2': '$date\'taki',
      '3': '$date\'taki',
      '4': '$date\'daki',
      '5': '$date\'taki',
      '6': '$date\'daki',
      '7': '$date\'daki',
      '8': '$date\'taki',
      '9': '$date\'deki',
      '10': '$date\'deki',
      '11': '$date\'daki',
      '12': '$date\'taki',
      'other': '$date',
    });
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ödeme henüz işaretlenmedi',
      one: '$_temp0 1 ödeme henüz işaretlenmedi: $name',
    );
    return '$_temp1';
  }

  @override
  String get repeatReminders => 'Israrlı hatırlatma';

  @override
  String get repeatModeOff => 'Kapalı';

  @override
  String get repeatModeEvening => 'Akşam bir kez daha';

  @override
  String get repeatModeDaily => 'Her gün';

  @override
  String repeatModeGeneral(String mode) {
    return 'Genel ayar ($mode)';
  }

  @override
  String get repeatRemindersHelp =>
      'Ödendi diyene kadar sakin aralıklarla yeniden hatırlatır. Son günden en fazla 7 gün sonrasına kadar sürer.';

  @override
  String repeatDailyHint(String time) {
    return 'Senin bildirim saatinde ve akşam $time\'de.';
  }

  @override
  String get repeatRemindersOn => 'Israrlı hatırlatma açık';

  @override
  String get debugRepeatTest =>
      'Israrlı deneme (1\'er dakika arayla 3 bildirim)';

  @override
  String get kindPayLater => 'Sonra öde';

  @override
  String get kindPayLaterHint => 'Tek ödeme, belli bir günde';

  @override
  String get payLaterAmount => 'Tutar';

  @override
  String get payLaterStore => 'Mağaza adı (isteğe bağlı)';

  @override
  String get payLaterSource => 'Kaynak (isteğe bağlı)';

  @override
  String get payLaterWhen => 'Ne zaman ödeyeceksin?';

  @override
  String payLaterDaysChip(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$daysString gün',
      one: '1 gün',
    );
    return '$_temp0';
  }

  @override
  String get payLaterNextMonthChip => 'Gelecek ayın …';

  @override
  String payLaterNextMonthDay(int day) {
    final intl.NumberFormat dayNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String dayString = dayNumberFormat.format(day);

    return 'Gelecek ayın $dayString. günü';
  }

  @override
  String get payLaterCustomDays => 'Gün sayısı';

  @override
  String get payLaterDayOfMonth => 'Ayın günü';

  @override
  String get payLaterPickDate => 'Tarih seç';

  @override
  String get payLaterDueDate => 'Son ödeme günü';

  @override
  String get payLaterPurchaseDate => 'Alışveriş tarihi';

  @override
  String get payLaterToday => 'Bugün';

  @override
  String payLaterDueOn(String date) {
    return 'Son ödeme günü: $date';
  }

  @override
  String payLaterDaysLeft(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$daysString gün sonra',
      one: '1 gün sonra',
      zero: 'Ödeme günü bugün',
    );
    return '$_temp0';
  }

  @override
  String payLaterAutoName(String date) {
    return 'Sonra öde · $date';
  }

  @override
  String payLaterRuleDays(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$daysString gün sonra',
      one: '1 gün sonra',
    );
    return '$_temp0';
  }

  @override
  String get payLaterRuleChosen => 'Seçilen tarih';

  @override
  String payLaterRuleLine(String rule) {
    return 'Ne zaman: $rule';
  }

  @override
  String get errorPayLaterDays => 'Gün sayısı 1 ile 180 arasında olmalı.';

  @override
  String get errorPayLaterDay => 'Gün 1 ile 31 arasında olmalı.';

  @override
  String payLaterSourceLine(String name) {
    return 'Kaynak: $name';
  }
}
