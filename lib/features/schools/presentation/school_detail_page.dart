import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/theme.dart';
import '../../../config/l10n/app_localizations.dart';
import '../../../core/models/ripple_models.dart';
import '../../../core/widgets/ripple_widgets.dart';
import '../../../core/repositories/repository_providers.dart';

class SchoolDetailPage extends ConsumerWidget {
  final String schoolId;
  const SchoolDetailPage({super.key, required this.schoolId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = Theme.of(context).primaryColor;

    final schoolsRepo = ref.watch(schoolRepositoryProvider);

    return Container(
      decoration: RippleTheme.backgroundDecoration(isDark),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(l10n.translate('school_profile')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: FutureBuilder<School?>(
        future: schoolsRepo.getSchoolById(schoolId),
        builder: (context, snapshot) {
          final school = snapshot.data;
          if (school == null) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(child: Text('School profile not found.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. School Profile Card
                RippleCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: primaryColor.withOpacity(0.15),
                            radius: 26,
                            child: Icon(Icons.school, color: primaryColor, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  school.name,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                                ),
                                Text(
                                  '${school.area}, ${school.city}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      // Seeker / Interest Counts
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ripple Families Looking Here:', style: TextStyle(fontWeight: FontWeight.w600)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: RippleTheme.accentCoral.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${school.interestedCount} Families',
                              style: TextStyle(fontWeight: FontWeight.bold, color: RippleTheme.accentCoral, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. School grades list
                Text(
                  'Grades Offered',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: school.gradesOffered.map((grade) {
                    return Chip(
                      label: Text(grade, style: const TextStyle(fontSize: 11)),
                      backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // 3. Transfer history graph (Past 4 Quarters)
                Text(
                  'Transfer Seat Activity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                RippleCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Moves Approved Per Term (Past Year)',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 150,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (val, meta) {
                                    switch (val.toInt()) {
                                      case 1: return const Text('Q1', style: TextStyle(fontSize: 10));
                                      case 2: return const Text('Q2', style: TextStyle(fontSize: 10));
                                      case 3: return const Text('Q3', style: TextStyle(fontSize: 10));
                                      case 4: return const Text('Q4', style: TextStyle(fontSize: 10));
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  FlSpot(1, school.transferRatePerTerm * 0.5),
                                  FlSpot(2, school.transferRatePerTerm * 0.8),
                                  FlSpot(3, school.transferRatePerTerm * 0.6),
                                  FlSpot(4, school.transferRatePerTerm * 1.0),
                                ],
                                isCurved: true,
                                color: RippleTheme.secondaryEmerald,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Catchment Area Distance Stats
                Text(
                  'Admissions Distance Catchment',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                RippleCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Percentage of approvals by distance from home:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      _buildCatchmentBar('Within 2 km', 0.65, '65%', primaryColor),
                      const SizedBox(height: 12),
                      _buildCatchmentBar('2 to 5 km', 0.25, '25%', RippleTheme.secondaryEmerald),
                      const SizedBox(height: 12),
                      _buildCatchmentBar('Above 5 km', 0.10, '10%', Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Admissions tips specific to school
                Text(
                  l10n.translate('admission_tips'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                RippleCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTipRow('Application Window', 'Submit paperwork in early August for Autumn term transfers.'),
                      const Divider(height: 20),
                      _buildTipRow('Documentation', 'A verification certificate from the current headmaster is highly recommended by board authorities.'),
                      const Divider(height: 20),
                      _buildTipRow('Seat Openings', 'Vacancies usually open up during term transitions when families relocate within boroughs.'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildCatchmentBar(String label, double val, String percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(percentage, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: val,
          backgroundColor: Colors.grey.withOpacity(0.15),
          valueColor: AlwaysStoppedAnimation(color),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildTipRow(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueAccent)),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
