// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Kalan';

  @override
  String get languageNativeName => 'Bahasa Indonesia';

  @override
  String get actionSave => 'Simpan';

  @override
  String get actionCancel => 'Batal';

  @override
  String get actionDelete => 'Hapus';

  @override
  String get actionEdit => 'Ubah';

  @override
  String get actionAddPlan => 'Tambah rencana';

  @override
  String get actionMoreDetails => 'Detail lainnya';

  @override
  String get navHome => 'Periode ini';

  @override
  String get navPlans => 'Rencana';

  @override
  String get navSettings => 'Pengaturan';

  @override
  String get frequencyMonthly => 'Bulanan';

  @override
  String get frequencyBiweekly => 'Setiap dua minggu';

  @override
  String get frequencyWeekly => 'Mingguan';

  @override
  String get onboardingTitle => 'Kita atur dalam satu menit.';

  @override
  String get onboardingIntro =>
      'Beri tahu Kalan kapan kamu gajian. Datamu tetap di ponsel ini.';

  @override
  String get fieldCurrency => 'Mata uang';

  @override
  String get fieldPayFrequency => 'Seberapa sering kamu gajian?';

  @override
  String get fieldPayDay => 'Hari gajian';

  @override
  String get payDayHelp =>
      'Di bulan yang lebih pendek, dihitung hari terakhir.';

  @override
  String get fieldLastPayday => 'Gajian terakhir';

  @override
  String get fieldPayWeekday => 'Hari gajian';

  @override
  String get fieldNetIncome => 'Gaji bersih per gajian';

  @override
  String get netIncomeHelp =>
      'Opsional. Tanpa ini, aku hanya menampilkan yang sudah terikat.';

  @override
  String get onboardingStart => 'Mulai';

  @override
  String get errorRequired => 'Kolom ini wajib diisi.';

  @override
  String errorAmountInvalid(String example) {
    return 'Tulis jumlahnya dengan angka, misalnya $example.';
  }

  @override
  String get errorCountInvalid => 'Tulis angka 1 sampai 120.';

  @override
  String get errorRemainingTooHigh => 'Tidak boleh lebih dari total.';

  @override
  String get errorTotalTooSmall =>
      'Jumlah ini tidak bisa dibagi menjadi pembayaran sebanyak itu.';

  @override
  String get errorDayInvalid => 'Tulis tanggal 1 sampai 31.';

  @override
  String get errorNameRequired => 'Tulis nama.';

  @override
  String get errorEndBeforeStart =>
      'Tanggal akhir tidak boleh sebelum tanggal pertama.';

  @override
  String get errorDeferInvalid => 'Tulis angka 0 sampai 12.';

  @override
  String get errorStepInvalid => 'Tulis angka 1 sampai 365.';

  @override
  String get errorCardRequired => 'Pilih kartu.';

  @override
  String get homeLeftLabel => 'Sisa';

  @override
  String get homeSpokenForLabel => 'Terikat';

  @override
  String get homeIncomeLabel => 'Pendapatan';

  @override
  String periodRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String homeSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ada $count pembayaran periode ini. Total $total.',
      zero: 'Tidak ada pembayaran periode ini.',
    );
    return '$_temp0';
  }

  @override
  String homeTight(String threshold) {
    return 'Periode ketat. Sisamu di bawah batas $threshold yang kamu tetapkan.';
  }

  @override
  String homeNegative(String amount) {
    return 'Periode ini kurang $amount.';
  }

  @override
  String get homeNoIncomeHint =>
      'Isi gaji bersihmu di Pengaturan untuk melihat sisanya.';

  @override
  String get homeOverdueTitle => 'Belum dibayar';

  @override
  String get homeOverdueHelp =>
      'Tanggalnya sudah lewat dan belum ditandai lunas.';

  @override
  String get homePaymentsTitle => 'Pembayaran periode ini';

  @override
  String homeBarLabel(String spokenFor, String income) {
    return '$spokenFor dari $income sudah terikat.';
  }

  @override
  String progressLabel(int seq, int count) {
    return '$seq/$count';
  }

  @override
  String progressSemantics(int seq, int count) {
    return 'Pembayaran $seq dari $count';
  }

  @override
  String get paidLabel => 'Lunas';

  @override
  String get markAsPaid => 'Tandai lunas';

  @override
  String get markAsUnpaid => 'Tandai belum lunas';

  @override
  String get markedPaid => 'Ditandai lunas.';

  @override
  String get markedUnpaid => 'Ditandai belum lunas.';

  @override
  String get recurringTag => 'Rutin';

  @override
  String get dueToday => 'Hari ini';

  @override
  String get dueTomorrow => 'Besok';

  @override
  String get plansTabOpen => 'Aktif';

  @override
  String get plansTabRecurring => 'Rutin';

  @override
  String get plansTabFinished => 'Selesai';

  @override
  String get plansEmptyOpen => 'Tidak ada rencana aktif.';

  @override
  String get plansEmptyFinished =>
      'Belum ada rencana selesai. Rencana pindah ke sini saat semua pembayarannya lunas.';

  @override
  String get recurringEmpty =>
      'Tidak ada pembayaran rutin. Kamu bisa menambah sewa, tagihan, atau langganan.';

  @override
  String planPaidOf(int paid, int count) {
    return '$paid/$count lunas';
  }

  @override
  String planToPay(String amount) {
    return 'Harus dibayar $amount';
  }

  @override
  String planNext(String date) {
    return 'Pembayaran berikutnya $date';
  }

  @override
  String planTotal(String amount) {
    return 'Total $amount';
  }

  @override
  String planPurchaseDate(String date) {
    return 'Dibeli $date';
  }

  @override
  String planStartedMidway(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count pembayaran sudah dilakukan sebelum rencana ini ditambahkan.',
    );
    return '$_temp0';
  }

  @override
  String freeLimitReached(int limit) {
    return 'Versi gratis bisa memuat hingga $limit rencana aktif. Kamu bisa menambah yang baru saat satu rencana selesai.';
  }

  @override
  String get addRecurring => 'Tambah pembayaran rutin';

  @override
  String get kindPayIn4 => 'Bayar 4 kali';

  @override
  String get kindMonthly => 'Cicilan bulanan';

  @override
  String get kindCard => 'Cicilan kartu kredit';

  @override
  String get kindManual => 'Atur sendiri';

  @override
  String get kindMidway => 'Sudah berjalan';

  @override
  String get kindCashAdvance => 'Tarik tunai cicilan';

  @override
  String get planPaymentsTitle => 'Pembayaran';

  @override
  String get planDelete => 'Hapus rencana';

  @override
  String get planDeleteConfirm =>
      'Rencana ini dan semua pembayarannya akan dihapus.';

  @override
  String get planDeleted => 'Rencana dihapus.';

  @override
  String get planNotFound => 'Rencana ini sudah tidak ada.';

  @override
  String get editPaymentTitle => 'Ubah pembayaran';

  @override
  String get editPaymentHelp =>
      'Selisihnya dibagi ke pembayaran berikutnya. Total rencana tetap sama.';

  @override
  String get editRejectedPaid =>
      'Pembayaran yang sudah lunas tidak bisa diubah. Tandai belum lunas dulu.';

  @override
  String get editRejectedNoAbsorbers =>
      'Tidak ada pembayaran berikutnya untuk menampung selisihnya. Kamu masih bisa mengubah tanggalnya.';

  @override
  String get editRejectedAbsorber =>
      'Perubahan ini membuat pembayaran berikutnya menjadi nol. Coba ubah lebih sedikit.';

  @override
  String get editedTag => 'Diubah';

  @override
  String get paymentUpdated => 'Pembayaran diperbarui.';

  @override
  String paymentRowSemantics(String name, String amount, String date) {
    return '$name, $amount, $date';
  }

  @override
  String get addPlanTitle => 'Tambah rencana';

  @override
  String get addPlanTypeLabel => 'Jenis rencana';

  @override
  String get fieldSource => 'Sumber';

  @override
  String get fieldSourceHint => 'mis. Klarna atau bankmu';

  @override
  String get fieldCard => 'Kartu';

  @override
  String get fieldTotal => 'Jumlah total';

  @override
  String get fieldCount => 'Jumlah pembayaran';

  @override
  String get fieldFirstDate => 'Tanggal pembayaran pertama';

  @override
  String get fieldPurchaseDate => 'Tanggal pembelian';

  @override
  String get fieldIntervalStep => 'Setiap';

  @override
  String get fieldIntervalUnit => 'Satuan';

  @override
  String get unitDays => 'hari';

  @override
  String get unitWeeks => 'minggu';

  @override
  String get unitMonths => 'bulan';

  @override
  String get fieldTotalCount => 'Total pembayaran';

  @override
  String get fieldUnpaidCount => 'Pembayaran belum lunas';

  @override
  String get fieldInstallment => 'Jumlah pembayaran';

  @override
  String get fieldNextDate => 'Tanggal pembayaran berikutnya';

  @override
  String get fieldTitle => 'Nama rencana';

  @override
  String get fieldTitleHint => 'mis. Ponsel';

  @override
  String get fieldDefer => 'Tunda pembayaran pertama (bulan)';

  @override
  String get fieldCashAdvance => 'Tarik tunai cicilan';

  @override
  String get noCards => 'Belum ada kartu.';

  @override
  String get addCard => 'Tambah kartu';

  @override
  String get previewTitle => 'Pembayaran';

  @override
  String previewSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pembayaran, total $total.',
    );
    return '$_temp0';
  }

  @override
  String get previewEmpty => 'Isi kolomnya untuk melihat pembayaran di sini.';

  @override
  String get planSaved => 'Rencana ditambahkan.';

  @override
  String get fieldPaymentDate => 'Tanggal pembayaran';

  @override
  String get sourcesTitle => 'Sumber dan kartu';

  @override
  String get sourcesEmpty =>
      'Belum ada sumber. Sumber yang kamu ketik saat menambah rencana akan muncul di sini.';

  @override
  String get addSource => 'Tambah sumber';

  @override
  String get editSource => 'Ubah sumber';

  @override
  String get fieldName => 'Nama';

  @override
  String get fieldSourceKind => 'Jenis';

  @override
  String get sourceKindProvider => 'Layanan bayar nanti';

  @override
  String get sourceKindCard => 'Kartu kredit';

  @override
  String get fieldStatementDay => 'Tanggal cetak tagihan';

  @override
  String get statementDayHelp => 'Tanggal setiap bulan saat tagihanmu dicetak.';

  @override
  String get fieldDueDay => 'Jatuh tempo';

  @override
  String get dueDayHelp => 'Tanggal setiap bulan saat tagihan harus dibayar.';

  @override
  String get fieldShiftWeekend =>
      'Geser ke hari kerja berikutnya jika jatuh di akhir pekan';

  @override
  String get cardDaysChangeNote =>
      'Mengubah tanggal ini akan menghitung ulang tanggal pembayaran yang belum lunas dan belum diubah di kartu ini.';

  @override
  String get sourceInUse =>
      'Ada rencana yang memakai sumber ini. Hapus rencana itu dulu.';

  @override
  String get sourceDeleted => 'Sumber dihapus.';

  @override
  String get sourceSaved => 'Tersimpan.';

  @override
  String cardSummary(int statement, int due) {
    return 'Cetak tagihan tgl $statement, jatuh tempo tgl $due';
  }

  @override
  String get recurringNewTitle => 'Tambah pembayaran rutin';

  @override
  String get recurringEditTitle => 'Ubah pembayaran rutin';

  @override
  String get fieldRecurringNameHint => 'mis. Sewa';

  @override
  String get fieldAmount => 'Jumlah';

  @override
  String get fieldRecurrence => 'Berulang';

  @override
  String get recurrenceWeekly => 'Setiap minggu';

  @override
  String get recurrenceBiweekly => 'Setiap dua minggu';

  @override
  String get recurrenceMonthly => 'Setiap bulan';

  @override
  String get recurrenceYearly => 'Setiap tahun';

  @override
  String get fieldEndDate => 'Tanggal akhir';

  @override
  String get noEndDate => 'Tanpa tanggal akhir';

  @override
  String get clearEndDate => 'Hapus tanggal akhir';

  @override
  String get recurringDeleteConfirm => 'Pembayaran rutin ini akan dihapus.';

  @override
  String get recurringDeleted => 'Pembayaran rutin dihapus.';

  @override
  String get recurringSaved => 'Tersimpan.';

  @override
  String recurringNext(String date) {
    return 'Berikutnya $date';
  }

  @override
  String get recurringEnded => 'Selesai';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get languageSystem => 'Bahasa sistem';

  @override
  String get settingsCurrency => 'Mata uang';

  @override
  String get settingsCurrencyNote =>
      'Jumlah tidak dikonversi; hanya label mata uang yang berubah.';

  @override
  String currencyName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'TRY': 'Lira Turki',
      'USD': 'Dolar AS',
      'EUR': 'Euro',
      'GBP': 'Pound sterling',
      'BRL': 'Real Brasil',
      'MXN': 'Peso Meksiko',
      'COP': 'Peso Kolombia',
      'CLP': 'Peso Chili',
      'RUB': 'Rubel Rusia',
      'KZT': 'Tenge Kazakhstan',
      'CNY': 'Yuan Tiongkok',
      'SGD': 'Dolar Singapura',
      'MYR': 'Ringgit Malaysia',
      'IDR': 'Rupiah Indonesia',
      'CAD': 'Dolar Kanada',
      'AUD': 'Dolar Australia',
      'CHF': 'Franc Swiss',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get currencySearch => 'Cari mata uang';

  @override
  String get currencyNoMatch => 'Tidak ada mata uang yang cocok.';

  @override
  String get currencyChangeTitle => 'Ganti mata uang';

  @override
  String currencyChangePreview(String before, String after) {
    return 'Contoh: $before → $after';
  }

  @override
  String get currencyChangeRounding =>
      'Mata uang ini memakai jumlah desimal yang berbeda, jadi jumlahnya dibulatkan.';

  @override
  String get currencyChangeConfirm => 'Ganti';

  @override
  String get settingsPay => 'Gaji';

  @override
  String paySummaryMonthly(int day) {
    return 'Bulanan, tanggal $day';
  }

  @override
  String paySummaryBiweekly(String date) {
    return 'Setiap dua minggu, gajian terakhir $date';
  }

  @override
  String paySummaryWeekly(String weekday) {
    return 'Mingguan, $weekday';
  }

  @override
  String get settingsNetIncome => 'Gaji bersih';

  @override
  String get notSet => 'Belum diisi';

  @override
  String get settingsTight => 'Batas periode ketat';

  @override
  String get settingsTightHelp =>
      'Periode dianggap ketat jika sisamu di bawah jumlah ini. Kosongkan untuk mematikan.';

  @override
  String get off => 'Mati';

  @override
  String get settingsSources => 'Sumber dan kartu';

  @override
  String get settingsRoadmap => 'Peta jalan';

  @override
  String get settingsPrivacy =>
      'Datamu tetap di ponsel ini. Tanpa akun, tanpa koneksi bank, tanpa iklan.';

  @override
  String get settingsDebugPro => 'Pro (hanya build debug)';

  @override
  String get settingsSaved => 'Tersimpan.';

  @override
  String get roadmapEmpty => 'Belum ada yang bisa dibagikan di sini.';

  @override
  String get roadmapError => 'Peta jalan tidak bisa dibaca.';

  @override
  String get roadmapPlanned => 'Direncanakan';

  @override
  String get roadmapInProgress => 'Sedang dikerjakan';

  @override
  String get roadmapShipped => 'Dirilis';

  @override
  String roadmapTarget(String version) {
    return 'Versi target $version';
  }
}
