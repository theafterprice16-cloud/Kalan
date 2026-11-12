// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Kalan';

  @override
  String get languageNativeName => '简体中文';

  @override
  String get actionSave => '保存';

  @override
  String get actionCancel => '取消';

  @override
  String get actionDelete => '删除';

  @override
  String get actionEdit => '编辑';

  @override
  String get actionAddPlan => '添加计划';

  @override
  String get actionMoreDetails => '更多信息';

  @override
  String get navHome => '本周期';

  @override
  String get navPlans => '计划';

  @override
  String get navSettings => '设置';

  @override
  String get frequencyMonthly => '每月';

  @override
  String get frequencyBiweekly => '每两周';

  @override
  String get frequencyWeekly => '每周';

  @override
  String get onboardingTitle => '一分钟完成设置。';

  @override
  String get onboardingIntro => '告诉 Kalan 你什么时候发工资。你的数据只保存在这部手机上。';

  @override
  String get fieldCurrency => '货币';

  @override
  String get fieldPayFrequency => '你多久发一次工资？';

  @override
  String get fieldPayDay => '发薪日';

  @override
  String get payDayHelp => '较短的月份按最后一天计算。';

  @override
  String get fieldLastPayday => '上次发薪日';

  @override
  String get fieldPayWeekday => '发薪日';

  @override
  String get fieldNetIncome => '每次到手工资';

  @override
  String get netIncomeHelp => '可选。不填的话只显示已承诺的金额。';

  @override
  String get onboardingStart => '开始';

  @override
  String get errorRequired => '此项为必填。';

  @override
  String errorAmountInvalid(String example) {
    return '请用数字输入金额，例如 $example。';
  }

  @override
  String get errorCountInvalid => '请输入 1 到 120 之间的数字。';

  @override
  String get errorRemainingTooHigh => '不能大于总数。';

  @override
  String get errorTotalTooSmall => '该金额无法分成这么多笔付款。';

  @override
  String get errorDayInvalid => '请输入 1 到 31 之间的日期。';

  @override
  String get errorNameRequired => '请输入名称。';

  @override
  String get errorEndBeforeStart => '结束日期不能早于开始日期。';

  @override
  String get errorDeferInvalid => '请输入 0 到 12 之间的数字。';

  @override
  String get errorStepInvalid => '请输入 1 到 365 之间的数字。';

  @override
  String get errorCardRequired => '请选择一张卡。';

  @override
  String get homeLeftLabel => '剩余';

  @override
  String get homeSpokenForLabel => '已承诺';

  @override
  String get homeIncomeLabel => '收入';

  @override
  String periodRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String homeSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '本周期有 $count 笔付款，共 $total。',
      zero: '本周期没有付款。',
    );
    return '$_temp0';
  }

  @override
  String homeTight(String threshold) {
    return '紧张周期。剩余金额低于你设定的 $threshold。';
  }

  @override
  String homeNegative(String amount) {
    return '本周期缺少 $amount。';
  }

  @override
  String get homeNoIncomeHint => '在设置中填写到手工资，即可查看剩余金额。';

  @override
  String get homeOverdueTitle => '尚未支付';

  @override
  String get homeOverdueHelp => '日期已过，但尚未标记为已支付。';

  @override
  String get homePaymentsTitle => '本周期付款';

  @override
  String homeBarLabel(String spokenFor, String income) {
    return '$income 中已承诺 $spokenFor。';
  }

  @override
  String progressLabel(int seq, int count) {
    return '$seq/$count';
  }

  @override
  String progressSemantics(int seq, int count) {
    return '第 $seq 笔，共 $count 笔';
  }

  @override
  String get paidLabel => '已支付';

  @override
  String get markAsPaid => '标记为已支付';

  @override
  String get markAsUnpaid => '标记为未支付';

  @override
  String get markedPaid => '已标记为已支付。';

  @override
  String get markedUnpaid => '已标记为未支付。';

  @override
  String get recurringTag => '固定';

  @override
  String get dueToday => '今天';

  @override
  String get dueTomorrow => '明天';

  @override
  String get plansTabOpen => '进行中';

  @override
  String get plansTabRecurring => '固定';

  @override
  String get plansTabFinished => '已完成';

  @override
  String get plansEmptyOpen => '没有进行中的计划。';

  @override
  String get plansEmptyFinished => '还没有已完成的计划。所有付款都支付后，计划会移到这里。';

  @override
  String get recurringEmpty => '没有固定付款。你可以添加房租、账单或订阅。';

  @override
  String planPaidOf(int paid, int count) {
    return '已付 $paid/$count';
  }

  @override
  String planToPay(String amount) {
    return '待付 $amount';
  }

  @override
  String planNext(String date) {
    return '下次付款 $date';
  }

  @override
  String planTotal(String amount) {
    return '总计 $amount';
  }

  @override
  String planPurchaseDate(String date) {
    return '购买于 $date';
  }

  @override
  String planStartedMidway(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '添加此计划前已付款 $count 笔。',
    );
    return '$_temp0';
  }

  @override
  String freeLimitReached(int limit) {
    return '免费版最多可有 $limit 个进行中的计划。完成一个后即可添加新的计划。';
  }

  @override
  String get addRecurring => '添加固定付款';

  @override
  String get kindPayIn4 => '分 4 期付款';

  @override
  String get kindMonthly => '按月分期';

  @override
  String get kindCard => '信用卡分期';

  @override
  String get kindManual => '自定义';

  @override
  String get kindMidway => '已开始';

  @override
  String get kindCashAdvance => '分期取现';

  @override
  String get planPaymentsTitle => '付款';

  @override
  String get planDelete => '删除计划';

  @override
  String get planDeleteConfirm => '此计划及其所有付款将被删除。';

  @override
  String get planDeleted => '计划已删除。';

  @override
  String get planNotFound => '此计划已不存在。';

  @override
  String get editPaymentTitle => '修改付款';

  @override
  String get editPaymentHelp => '差额会分摊到之后的付款中，计划总额不变。';

  @override
  String get editRejectedPaid => '已支付的付款无法修改。请先标记为未支付。';

  @override
  String get editRejectedNoAbsorbers => '没有之后的付款来承担差额。你仍然可以修改日期。';

  @override
  String get editRejectedAbsorber => '此修改会使之后的某笔付款变为零。请尝试小一些的修改。';

  @override
  String get editedTag => '已修改';

  @override
  String get paymentUpdated => '付款已更新。';

  @override
  String paymentRowSemantics(String name, String amount, String date) {
    return '$name, $amount, $date';
  }

  @override
  String get addPlanTitle => '添加计划';

  @override
  String get addPlanTypeLabel => '计划类型';

  @override
  String get fieldSource => '来源';

  @override
  String get fieldSourceHint => '例如 Klarna 或你的银行';

  @override
  String get fieldCard => '卡';

  @override
  String get fieldTotal => '总金额';

  @override
  String get fieldCount => '付款次数';

  @override
  String get fieldFirstDate => '首次付款日期';

  @override
  String get fieldPurchaseDate => '购买日期';

  @override
  String get fieldIntervalStep => '间隔';

  @override
  String get fieldIntervalUnit => '单位';

  @override
  String get unitDays => '天';

  @override
  String get unitWeeks => '周';

  @override
  String get unitMonths => '个月';

  @override
  String get fieldTotalCount => '付款总次数';

  @override
  String get fieldUnpaidCount => '未付款次数';

  @override
  String get fieldInstallment => '每笔金额';

  @override
  String get fieldNextDate => '下次付款日期';

  @override
  String get fieldTitle => '计划名称';

  @override
  String get fieldTitleHint => '例如 手机';

  @override
  String get fieldDefer => '首期延后（月）';

  @override
  String get fieldCashAdvance => '分期取现';

  @override
  String get noCards => '还没有卡。';

  @override
  String get addCard => '添加卡';

  @override
  String get previewTitle => '付款';

  @override
  String previewSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 笔付款，共 $total。',
    );
    return '$_temp0';
  }

  @override
  String get previewEmpty => '填写各项后即可在此查看付款。';

  @override
  String get planSaved => '计划已添加。';

  @override
  String get fieldPaymentDate => '付款日期';

  @override
  String get sourcesTitle => '来源和卡';

  @override
  String get sourcesEmpty => '还没有来源。添加计划时输入的来源会显示在这里。';

  @override
  String get addSource => '添加来源';

  @override
  String get editSource => '编辑来源';

  @override
  String get fieldName => '名称';

  @override
  String get fieldSourceKind => '类型';

  @override
  String get sourceKindProvider => '先买后付服务';

  @override
  String get sourceKindCard => '信用卡';

  @override
  String get fieldStatementDay => '账单日';

  @override
  String get statementDayHelp => '每月出账单的日期。';

  @override
  String get fieldDueDay => '还款日';

  @override
  String get dueDayHelp => '每月必须还清账单的日期。';

  @override
  String get fieldShiftWeekend => '如遇周末，顺延至下一个工作日';

  @override
  String get cardDaysChangeNote => '修改这些日期后，此卡上未支付且未修改的付款日期会重新计算。';

  @override
  String get sourceInUse => '有计划正在使用此来源。请先删除这些计划。';

  @override
  String get sourceDeleted => '来源已删除。';

  @override
  String get sourceSaved => '已保存。';

  @override
  String cardSummary(int statement, int due) {
    return '账单日 $statement 日，还款日 $due 日';
  }

  @override
  String get recurringNewTitle => '添加固定付款';

  @override
  String get recurringEditTitle => '编辑固定付款';

  @override
  String get fieldRecurringNameHint => '例如 房租';

  @override
  String get fieldAmount => '金额';

  @override
  String get fieldRecurrence => '重复';

  @override
  String get recurrenceWeekly => '每周';

  @override
  String get recurrenceBiweekly => '每两周';

  @override
  String get recurrenceMonthly => '每月';

  @override
  String get recurrenceYearly => '每年';

  @override
  String get fieldEndDate => '结束日期';

  @override
  String get noEndDate => '无结束日期';

  @override
  String get clearEndDate => '移除结束日期';

  @override
  String get recurringDeleteConfirm => '此固定付款将被删除。';

  @override
  String get recurringDeleted => '固定付款已删除。';

  @override
  String get recurringSaved => '已保存。';

  @override
  String recurringNext(String date) {
    return '下次 $date';
  }

  @override
  String get recurringEnded => '已结束';

  @override
  String get settingsLanguage => '语言';

  @override
  String get languageSystem => '系统语言';

  @override
  String get settingsCurrency => '货币';

  @override
  String get settingsCurrencyNote => '金额不会换算，只会更改货币标签。';

  @override
  String currencyName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'TRY': '土耳其里拉',
      'USD': '美元',
      'EUR': '欧元',
      'GBP': '英镑',
      'BRL': '巴西雷亚尔',
      'MXN': '墨西哥比索',
      'COP': '哥伦比亚比索',
      'CLP': '智利比索',
      'RUB': '俄罗斯卢布',
      'KZT': '哈萨克斯坦坚戈',
      'CNY': '人民币',
      'SGD': '新加坡元',
      'MYR': '马来西亚林吉特',
      'IDR': '印度尼西亚盾',
      'CAD': '加拿大元',
      'AUD': '澳大利亚元',
      'CHF': '瑞士法郎',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get currencySearch => '搜索货币';

  @override
  String get currencyNoMatch => '没有匹配的货币。';

  @override
  String get currencyChangeTitle => '更改货币';

  @override
  String currencyChangePreview(String before, String after) {
    return '示例：$before → $after';
  }

  @override
  String get currencyChangeRounding => '该货币的小数位数不同，金额将四舍五入。';

  @override
  String get currencyChangeConfirm => '更改';

  @override
  String get settingsPay => '工资';

  @override
  String paySummaryMonthly(int day) {
    return '每月 $day 日';
  }

  @override
  String paySummaryBiweekly(String date) {
    return '每两周，上次发薪 $date';
  }

  @override
  String paySummaryWeekly(String weekday) {
    return '每周$weekday';
  }

  @override
  String get settingsNetIncome => '到手工资';

  @override
  String get notSet => '未设置';

  @override
  String get settingsTight => '紧张周期阈值';

  @override
  String get settingsTightHelp => '剩余金额低于此数时，该周期视为紧张。留空即关闭。';

  @override
  String get off => '关闭';

  @override
  String get settingsSources => '来源和卡';

  @override
  String get settingsRoadmap => '路线图';

  @override
  String get settingsPrivacy => '你的数据只保存在这部手机上。无需账户，不连接银行，没有广告。';

  @override
  String get settingsDebugPro => 'Pro（仅调试版本）';

  @override
  String get settingsSaved => '已保存。';

  @override
  String get roadmapEmpty => '这里暂时没有内容。';

  @override
  String get roadmapError => '无法读取路线图。';

  @override
  String get roadmapPlanned => '已计划';

  @override
  String get roadmapInProgress => '进行中';

  @override
  String get roadmapShipped => '已发布';

  @override
  String roadmapTarget(String version) {
    return '目标版本 $version';
  }
}
