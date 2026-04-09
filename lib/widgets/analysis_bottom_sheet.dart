import 'package:flutter/material.dart';
import 'package:date_and_doing/models/analysis_result.dart';

Future<void> showAnalysisBottomSheet(
  BuildContext context, {
  required AnalysisResult result,
}) async {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final textTheme = theme.textTheme;

  final partnerName = result.partnerName.trim().isNotEmpty
      ? result.partnerName.trim()
      : "esta persona";

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.62,
        maxChildSize: 0.96,
        builder: (ctx, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: cs.outline.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: true,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                      children: [
                        _HeaderCard(
                          partnerName: partnerName,
                          cs: cs,
                          textTheme: textTheme,
                        ),

                        const SizedBox(height: 18),

                        _GeneralSummaryCard(
                          title: result.overallTitle,
                          toneLabel: result.toneLabel,
                          summary: result.overallSummary,
                        ),

                        if (result.scores.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Icon(
                                Icons.psychology_alt_rounded,
                                color: cs.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Lectura de la conversación",
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...result.scores.entries.map(
                            (e) => _scoreCard(
                              label: e.key,
                              value: e.value,
                              cs: cs,
                              textTheme: textTheme,
                            ),
                          ),
                        ],

                        if (result.positives.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Icon(
                                Icons.favorite_rounded,
                                color: Colors.pink.shade400,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Lo mejor de esta conexión",
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...result.positives.map(
                            (p) => _PositiveCard(
                              text: p,
                              textTheme: textTheme,
                              cs: cs,
                            ),
                          ),
                        ],

                        const SizedBox(height: 22),

                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: cs.primary.withOpacity(0.12),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: cs.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "Nota: ",
                                        style: textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      TextSpan(
                                        text: result.note,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: cs.onSurface.withOpacity(0.78),
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text("Entendido"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _HeaderCard extends StatelessWidget {
  final String partnerName;
  final ColorScheme cs;
  final TextTheme textTheme;

  const _HeaderCard({
    required this.partnerName,
    required this.cs,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withOpacity(0.14),
            cs.secondary.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.primary.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withOpacity(0.14),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: cs.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tu análisis con $partnerName",
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Una lectura inteligente de tu conversación para ayudarte a entender mejor la conexión, el tono y las señales más importantes.",
                  style: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.72),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    "Conversación analizada con $partnerName",
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneralSummaryCard extends StatelessWidget {
  final String title;
  final String toneLabel;
  final String summary;

  const _GeneralSummaryCard({
    required this.title,
    required this.toneLabel,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.green.shade500,
            Colors.teal.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.insights_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                "Evaluación general",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            toneLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          if (title.trim().isNotEmpty)
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (title.trim().isNotEmpty) const SizedBox(height: 10),
          Text(
            summary,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _scoreCard({
  required String label,
  required double value,
  required ColorScheme cs,
  required TextTheme textTheme,
}) {
  final percentText = "${value.toStringAsFixed(0)}%";
  final progressValue = (value / 100.0).clamp(0.0, 1.0);

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: cs.surfaceContainerHighest.withOpacity(0.45),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: cs.outline.withOpacity(0.08)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                percentText,
                style: textTheme.bodySmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progressValue,
            minHeight: 8,
            backgroundColor: cs.surfaceVariant.withOpacity(0.65),
            valueColor: AlwaysStoppedAnimation<Color>(
              cs.primary.withOpacity(0.95),
            ),
          ),
        ),
      ],
    ),
  );
}

class _PositiveCard extends StatelessWidget {
  final String text;
  final TextTheme textTheme;
  final ColorScheme cs;

  const _PositiveCard({
    required this.text,
    required this.textTheme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: Colors.green.shade500,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(
                color: cs.onSurface,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}