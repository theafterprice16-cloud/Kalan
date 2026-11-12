// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Kalan';

  @override
  String get languageNativeName => 'Português (Brasil)';

  @override
  String get actionSave => 'Salvar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionDelete => 'Excluir';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionAddPlan => 'Adicionar plano';

  @override
  String get actionMoreDetails => 'Mais detalhes';

  @override
  String get navHome => 'Este período';

  @override
  String get navPlans => 'Planos';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get frequencyMonthly => 'Mensal';

  @override
  String get frequencyBiweekly => 'A cada duas semanas';

  @override
  String get frequencyWeekly => 'Semanal';

  @override
  String get onboardingTitle => 'Vamos configurar em um minuto.';

  @override
  String get onboardingIntro =>
      'Diga ao Kalan quando você recebe. Seus dados ficam neste celular.';

  @override
  String get fieldCurrency => 'Moeda';

  @override
  String get fieldPayFrequency => 'Com que frequência você recebe?';

  @override
  String get fieldPayDay => 'Dia do pagamento';

  @override
  String get payDayHelp => 'Nos meses mais curtos, vale o último dia.';

  @override
  String get fieldLastPayday => 'Último pagamento';

  @override
  String get fieldPayWeekday => 'Dia do pagamento';

  @override
  String get fieldNetIncome => 'Salário líquido por pagamento';

  @override
  String get netIncomeHelp =>
      'Opcional. Sem ele, mostro só o que está comprometido.';

  @override
  String get onboardingStart => 'Começar';

  @override
  String get errorRequired => 'Este campo é obrigatório.';

  @override
  String errorAmountInvalid(String example) {
    return 'Digite o valor em números, por exemplo $example.';
  }

  @override
  String get errorCountInvalid => 'Digite um número de 1 a 120.';

  @override
  String get errorRemainingTooHigh => 'Não pode ser maior que o total.';

  @override
  String get errorTotalTooSmall =>
      'Este valor não pode ser dividido em tantos pagamentos.';

  @override
  String get errorDayInvalid => 'Digite um dia de 1 a 31.';

  @override
  String get errorNameRequired => 'Digite um nome.';

  @override
  String get errorEndBeforeStart =>
      'A data final não pode ser anterior à primeira.';

  @override
  String get errorDeferInvalid => 'Digite um número de 0 a 12.';

  @override
  String get errorStepInvalid => 'Digite um número de 1 a 365.';

  @override
  String get errorCardRequired => 'Escolha um cartão.';

  @override
  String get homeLeftLabel => 'Sobra';

  @override
  String get homeSpokenForLabel => 'Comprometido';

  @override
  String get homeIncomeLabel => 'Renda';

  @override
  String periodRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String homeSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pagamentos neste período. Total $total.',
      one: '1 pagamento neste período. Total $total.',
      zero: 'Nenhum pagamento neste período.',
    );
    return '$_temp0';
  }

  @override
  String homeTight(String threshold) {
    return 'Período apertado. O que sobra está abaixo do seu limite de $threshold.';
  }

  @override
  String homeNegative(String amount) {
    return 'Neste período faltam $amount.';
  }

  @override
  String get homeNoIncomeHint =>
      'Adicione seu salário líquido em Ajustes para ver o que sobra.';

  @override
  String get homeOverdueTitle => 'Não pago';

  @override
  String get homeOverdueHelp =>
      'A data já passou e não estão marcados como pagos.';

  @override
  String get homePaymentsTitle => 'Pagamentos deste período';

  @override
  String homeBarLabel(String spokenFor, String income) {
    return '$spokenFor de $income já está comprometido.';
  }

  @override
  String progressLabel(int seq, int count) {
    return '$seq/$count';
  }

  @override
  String progressSemantics(int seq, int count) {
    return 'Pagamento $seq de $count';
  }

  @override
  String get paidLabel => 'Pago';

  @override
  String get markAsPaid => 'Marcar como pago';

  @override
  String get markAsUnpaid => 'Marcar como não pago';

  @override
  String get markedPaid => 'Marcado como pago.';

  @override
  String get markedUnpaid => 'Marcado como não pago.';

  @override
  String get recurringTag => 'Fixo';

  @override
  String get dueToday => 'Hoje';

  @override
  String get dueTomorrow => 'Amanhã';

  @override
  String get plansTabOpen => 'Abertos';

  @override
  String get plansTabRecurring => 'Fixos';

  @override
  String get plansTabFinished => 'Concluídos';

  @override
  String get plansEmptyOpen => 'Nenhum plano aberto.';

  @override
  String get plansEmptyFinished =>
      'Ainda não há planos concluídos. Um plano vem para cá quando todos os pagamentos estão pagos.';

  @override
  String get recurringEmpty =>
      'Nenhum pagamento fixo. Você pode adicionar aluguel, contas ou assinaturas.';

  @override
  String planPaidOf(int paid, int count) {
    return '$paid/$count pagos';
  }

  @override
  String planToPay(String amount) {
    return 'A pagar $amount';
  }

  @override
  String planNext(String date) {
    return 'Próximo pagamento $date';
  }

  @override
  String planTotal(String amount) {
    return 'Total $amount';
  }

  @override
  String planPurchaseDate(String date) {
    return 'Compra em $date';
  }

  @override
  String planStartedMidway(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count pagamentos foram feitos antes de você adicionar este plano.',
      one: '1 pagamento foi feito antes de você adicionar este plano.',
    );
    return '$_temp0';
  }

  @override
  String freeLimitReached(int limit) {
    return 'A versão gratuita permite até $limit planos abertos. Você pode adicionar outro quando um terminar.';
  }

  @override
  String get addRecurring => 'Adicionar pagamento fixo';

  @override
  String get kindPayIn4 => 'Pagamento em 4';

  @override
  String get kindMonthly => 'Parcelas mensais';

  @override
  String get kindCard => 'Parcelas no cartão';

  @override
  String get kindManual => 'Personalizado';

  @override
  String get kindMidway => 'Já iniciado';

  @override
  String get kindCashAdvance => 'Saque parcelado';

  @override
  String get planPaymentsTitle => 'Pagamentos';

  @override
  String get planDelete => 'Excluir plano';

  @override
  String get planDeleteConfirm =>
      'Este plano e todos os pagamentos serão excluídos.';

  @override
  String get planDeleted => 'Plano excluído.';

  @override
  String get planNotFound => 'Este plano não existe mais.';

  @override
  String get editPaymentTitle => 'Corrigir pagamento';

  @override
  String get editPaymentHelp =>
      'A diferença é distribuída entre os próximos pagamentos. O total do plano não muda.';

  @override
  String get editRejectedPaid =>
      'Um pagamento pago não pode ser corrigido. Marque-o primeiro como não pago.';

  @override
  String get editRejectedNoAbsorbers =>
      'Não há pagamento seguinte para receber a diferença. Você ainda pode mudar a data.';

  @override
  String get editRejectedAbsorber =>
      'Essa mudança zeraria um pagamento seguinte. Tente uma mudança menor.';

  @override
  String get editedTag => 'Corrigido';

  @override
  String get paymentUpdated => 'Pagamento atualizado.';

  @override
  String paymentRowSemantics(String name, String amount, String date) {
    return '$name, $amount, $date';
  }

  @override
  String get addPlanTitle => 'Adicionar plano';

  @override
  String get addPlanTypeLabel => 'Tipo de plano';

  @override
  String get fieldSource => 'Origem';

  @override
  String get fieldSourceHint => 'ex.: Klarna ou seu banco';

  @override
  String get fieldCard => 'Cartão';

  @override
  String get fieldTotal => 'Valor total';

  @override
  String get fieldCount => 'Número de pagamentos';

  @override
  String get fieldFirstDate => 'Data do primeiro pagamento';

  @override
  String get fieldPurchaseDate => 'Data da compra';

  @override
  String get fieldIntervalStep => 'A cada';

  @override
  String get fieldIntervalUnit => 'Unidade';

  @override
  String get unitDays => 'dias';

  @override
  String get unitWeeks => 'semanas';

  @override
  String get unitMonths => 'meses';

  @override
  String get fieldTotalCount => 'Total de pagamentos';

  @override
  String get fieldUnpaidCount => 'Pagamentos pendentes';

  @override
  String get fieldInstallment => 'Valor do pagamento';

  @override
  String get fieldNextDate => 'Data do próximo pagamento';

  @override
  String get fieldTitle => 'Nome do plano';

  @override
  String get fieldTitleHint => 'ex.: Celular';

  @override
  String get fieldDefer => 'Adiar o primeiro pagamento (meses)';

  @override
  String get fieldCashAdvance => 'Saque parcelado';

  @override
  String get noCards => 'Nenhum cartão ainda.';

  @override
  String get addCard => 'Adicionar cartão';

  @override
  String get previewTitle => 'Pagamentos';

  @override
  String previewSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pagamentos, $total no total.',
      one: '1 pagamento, $total no total.',
    );
    return '$_temp0';
  }

  @override
  String get previewEmpty => 'Preencha os campos para ver os pagamentos aqui.';

  @override
  String get planSaved => 'Plano adicionado.';

  @override
  String get fieldPaymentDate => 'Data do pagamento';

  @override
  String get sourcesTitle => 'Origens e cartões';

  @override
  String get sourcesEmpty =>
      'Nenhuma origem ainda. As que você digitar ao adicionar um plano aparecem aqui.';

  @override
  String get addSource => 'Adicionar origem';

  @override
  String get editSource => 'Editar origem';

  @override
  String get fieldName => 'Nome';

  @override
  String get fieldSourceKind => 'Tipo';

  @override
  String get sourceKindProvider => 'Serviço de compre agora, pague depois';

  @override
  String get sourceKindCard => 'Cartão de crédito';

  @override
  String get fieldStatementDay => 'Data de fechamento';

  @override
  String get statementDayHelp => 'O dia do mês em que sua fatura fecha.';

  @override
  String get fieldDueDay => 'Data de vencimento';

  @override
  String get dueDayHelp => 'O dia do mês em que a fatura deve ser paga.';

  @override
  String get fieldShiftWeekend =>
      'Passar para o próximo dia útil se cair no fim de semana';

  @override
  String get cardDaysChangeNote =>
      'Mudar esses dias recalcula as datas dos pagamentos pendentes e não corrigidos deste cartão.';

  @override
  String get sourceInUse =>
      'Há planos usando esta origem. Exclua esses planos primeiro.';

  @override
  String get sourceDeleted => 'Origem excluída.';

  @override
  String get sourceSaved => 'Salvo.';

  @override
  String cardSummary(int statement, int due) {
    return 'Fechamento dia $statement, vencimento dia $due';
  }

  @override
  String get recurringNewTitle => 'Adicionar pagamento fixo';

  @override
  String get recurringEditTitle => 'Editar pagamento fixo';

  @override
  String get fieldRecurringNameHint => 'ex.: Aluguel';

  @override
  String get fieldAmount => 'Valor';

  @override
  String get fieldRecurrence => 'Repetição';

  @override
  String get recurrenceWeekly => 'Toda semana';

  @override
  String get recurrenceBiweekly => 'A cada duas semanas';

  @override
  String get recurrenceMonthly => 'Todo mês';

  @override
  String get recurrenceYearly => 'Todo ano';

  @override
  String get fieldEndDate => 'Data final';

  @override
  String get noEndDate => 'Sem data final';

  @override
  String get clearEndDate => 'Remover data final';

  @override
  String get recurringDeleteConfirm => 'Este pagamento fixo será excluído.';

  @override
  String get recurringDeleted => 'Pagamento fixo excluído.';

  @override
  String get recurringSaved => 'Salvo.';

  @override
  String recurringNext(String date) {
    return 'Próximo em $date';
  }

  @override
  String get recurringEnded => 'Encerrado';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get languageSystem => 'Idioma do sistema';

  @override
  String get settingsCurrency => 'Moeda';

  @override
  String get settingsCurrencyNote =>
      'Os valores não são convertidos; só o rótulo da moeda muda.';

  @override
  String currencyName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'TRY': 'Lira turca',
      'USD': 'Dólar americano',
      'EUR': 'Euro',
      'GBP': 'Libra esterlina',
      'BRL': 'Real brasileiro',
      'MXN': 'Peso mexicano',
      'COP': 'Peso colombiano',
      'CLP': 'Peso chileno',
      'RUB': 'Rublo russo',
      'KZT': 'Tenge cazaque',
      'CNY': 'Yuan chinês',
      'SGD': 'Dólar de Singapura',
      'MYR': 'Ringgit malaio',
      'IDR': 'Rupia indonésia',
      'CAD': 'Dólar canadense',
      'AUD': 'Dólar australiano',
      'CHF': 'Franco suíço',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get currencySearch => 'Buscar moeda';

  @override
  String get currencyNoMatch => 'Nenhuma moeda encontrada.';

  @override
  String get currencyChangeTitle => 'Mudar moeda';

  @override
  String currencyChangePreview(String before, String after) {
    return 'Exemplo: $before → $after';
  }

  @override
  String get currencyChangeRounding =>
      'Esta moeda usa outro número de casas decimais, então os valores são arredondados.';

  @override
  String get currencyChangeConfirm => 'Mudar';

  @override
  String get settingsPay => 'Salário';

  @override
  String paySummaryMonthly(int day) {
    return 'Mensal, dia $day';
  }

  @override
  String paySummaryBiweekly(String date) {
    return 'A cada duas semanas, último pagamento $date';
  }

  @override
  String paySummaryWeekly(String weekday) {
    return 'Semanal, $weekday';
  }

  @override
  String get settingsNetIncome => 'Salário líquido';

  @override
  String get notSet => 'Não definido';

  @override
  String get settingsTight => 'Limite de período apertado';

  @override
  String get settingsTightHelp =>
      'Um período é apertado quando o que sobra fica abaixo deste valor. Deixe vazio para desativar.';

  @override
  String get off => 'Desativado';

  @override
  String get settingsSources => 'Origens e cartões';

  @override
  String get settingsRoadmap => 'Roteiro';

  @override
  String get settingsPrivacy =>
      'Seus dados ficam neste celular. Sem conta, sem conexão bancária, sem anúncios.';

  @override
  String get settingsDebugPro => 'Pro (só em builds de debug)';

  @override
  String get settingsSaved => 'Salvo.';

  @override
  String get roadmapEmpty => 'Ainda não há nada para compartilhar aqui.';

  @override
  String get roadmapError => 'Não foi possível ler o roteiro.';

  @override
  String get roadmapPlanned => 'Planejado';

  @override
  String get roadmapInProgress => 'Em andamento';

  @override
  String get roadmapShipped => 'Lançado';

  @override
  String roadmapTarget(String version) {
    return 'Versão prevista $version';
  }
}
