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
  String get errorRemainingTooHigh => 'Bu sayı toplamdan büyük olamaz.';

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
  String get homeOverdueTitle => 'Ödenmemiş';

  @override
  String get homeOverdueHelp => 'Tarihi geçti, ödendi olarak işaretlenmedi.';

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
  String planPaidOf(int paid, int count) {
    return '$paid/$count ödendi';
  }

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
  String get kindMidway => 'Yarıda başlayan';

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
  String get fieldTotalCount => 'Toplam ödeme sayısı';

  @override
  String get fieldUnpaidCount => 'Ödenmemiş ödeme sayısı';

  @override
  String get fieldInstallment => 'Ödeme tutarı';

  @override
  String get fieldNextDate => 'Sonraki ödeme tarihi';

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
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get currencySearch => 'Para birimi ara';

  @override
  String get currencyNoMatch => 'Eşleşen para birimi yok.';

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
  String get overdueBadge => 'Gecikti';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';
}
