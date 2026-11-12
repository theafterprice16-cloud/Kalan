/// Route paths. Top-level routes open above the tab shell.
abstract final class Routes {
  static const onboarding = '/onboarding';
  static const home = '/';
  static const plans = '/plans';
  static const settings = '/settings';
  static const addPlan = '/add-plan';
  static String plan(int id) => '/plan/$id';
  static const sources = '/sources';
  static String newSource({bool card = false}) =>
      card ? '/source/new?kind=card' : '/source/new';
  static String source(int id) => '/source/$id';
  static const newRecurring = '/recurring/new';
  static String recurring(int id) => '/recurring/$id';
  static const pay = '/pay';
  static const roadmap = '/roadmap';
  static const remindersHelp = '/reminders-help';
  static String day(String isoDate) => '/day/$isoDate';
}
