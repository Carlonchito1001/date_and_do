class AnalysisResult {
  final String partnerName;
  final String overallTitle;
  final String toneLabel;
  final String overallSummary;
  final Map<String, double> scores;
  final List<String> positives;
  final String note;

  AnalysisResult({
    required this.partnerName,
    required this.overallTitle,
    required this.toneLabel,
    required this.overallSummary,
    required this.scores,
    required this.positives,
    required this.note,
  });
}
