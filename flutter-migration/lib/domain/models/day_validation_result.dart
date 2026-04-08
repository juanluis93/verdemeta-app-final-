class DayValidationResult {
  final bool isValid;
  final List<String> errors;

  const DayValidationResult({
    required this.isValid,
    required this.errors,
  });
}
