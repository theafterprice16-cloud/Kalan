/// A plan's own name (the one rule for screens, notifications and the
/// exported spreadsheet): its title when it has one, else its source's
/// name. Null for an untitled "Pay later" plan, which shows a label in
/// the app language instead ("Pay later · Dec 14").
String? planOwnName({
  required String? title,
  required bool isPayLater,
  required String? sourceName,
}) {
  final trimmed = title?.trim();
  if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  if (isPayLater) return null;
  return sourceName ?? '';
}
