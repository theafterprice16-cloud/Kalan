/// Route paths. Top-level routes open above the tab shell.
abstract final class Routes {
  static const onboarding = '/onboarding';
  static const home = '/';
  static const plans = '/plans';
  static const settings = '/settings';
  static const addPlan = '/add-plan';
  static String plan(int id) => '/plan/$id';
  static String planEdit(int id) => '/plan/$id/edit';
  static String planAdjust(int id) => '/plan/$id/adjust';
  static const sources = '/sources';

  /// The sources screen scrolled to card [cardId]'s statements (16; a
  /// notification opens it in 17).
  static String cardStatements(int cardId) => '$sources?card=$cardId';

  /// One statement of card [cardId], by its statement date as an epoch
  /// day.
  static String cardStatement(int cardId, int statementDay) =>
      '/source/$cardId/statement/$statementDay';
  static String newSource({bool card = false}) =>
      card ? '/source/new?kind=card' : '/source/new';
  static String source(int id) => '/source/$id';
  static const newRecurring = '/recurring/new';
  static String recurring(int id) => '/recurring/$id';
  static const pay = '/pay';
  static const roadmap = '/roadmap';
  static const remindersHelp = '/reminders-help';

  /// The coming pay periods, with period [selected] (0: the current one).
  static const comingPeriodsPath = '/periods';
  static String comingPeriods({int selected = 0}) => selected == 0
      ? comingPeriodsPath
      : '$comingPeriodsPath?selected=$selected';

  /// Kalan Pro. [returnOnUnlock]: back to the screen that opened it once
  /// Pro is on (the half-filled fifth plan).
  static String pro({bool returnOnUnlock = false}) =>
      returnOnUnlock ? '/pro?then=back' : '/pro';
}
