// lib/features/analytics/presentation/screens/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:daypilot/core/constants/app_constants.dart';
import 'package:daypilot/core/providers/providers.dart';
import 'package:daypilot/core/utils/date_utils.dart';
import 'package:daypilot/core/theme/app_theme.dart';
import 'package:daypilot/features/analytics/data/models/daily_stats_model.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = ref.watch(analyticsMonthProvider(
        (year: _selectedYear, month: _selectedMonth)));
    final analyticsRepo = ref.read(analyticsRepositoryProvider);

    final totalStudyMins = stats.fold(0, (s, d) => s + d.studyMinutes);
    final totalRevisionMins = stats.fold(0, (s, d) => s + d.revisionMinutes);
    final totalSleepMins = stats.fold(0, (s, d) => s + d.sleepMinutes);
    final totalWastedMins = stats.fold(0, (s, d) => s + d.wastedMinutes);
    final avgStudyHours = stats.isEmpty ? 0.0 : totalStudyMins / stats.length / 60.0;
    final consistency = analyticsRepo.getConsistencyScore(_selectedYear, _selectedMonth);
    final streak = analyticsRepo.getStudyStreak();
    final bestDay = analyticsRepo.getBestDay(_selectedYear, _selectedMonth);
    final worstDay = analyticsRepo.getWorstDay(_selectedYear, _selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          _MonthYearPicker(
            year: _selectedYear,
            month: _selectedMonth,
            onChanged: (y, m) => setState(() {
              _selectedYear = y;
              _selectedMonth = m;
            }),
          ),
        ],
      ),
      body: stats.isEmpty
          ? _EmptyAnalytics()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary cards row
                _SummaryCards(
                  totalStudyMins: totalStudyMins,
                  avgStudyHours: avgStudyHours,
                  consistency: consistency,
                  streak: streak,
                ),
                const SizedBox(height: 16),

                // Best / Worst day
                _BestWorstRow(bestDay: bestDay, worstDay: worstDay),
                const SizedBox(height: 16),

                // Study hours wave chart
                _ChartCard(
                  title: 'Study Hours',
                  subtitle: 'Daily study time this month',
                  icon: Icons.book_outlined,
                  color: BlockCategory.study.defaultColor,
                  child: _StudyLineChart(stats: stats),
                ),
                const SizedBox(height: 16),

                // Sleep chart
                _ChartCard(
                  title: 'Sleep Hours',
                  subtitle: 'Daily sleep this month',
                  icon: Icons.bedtime_outlined,
                  color: BlockCategory.sleep.defaultColor,
                  child: _SleepBarChart(stats: stats),
                ),
                const SizedBox(height: 16),

                // Wasted time chart
                _ChartCard(
                  title: 'Wasted Time',
                  subtitle: 'Time lost this month',
                  icon: Icons.warning_amber_outlined,
                  color: BlockCategory.wastedTime.defaultColor,
                  child: _WastedBarChart(stats: stats),
                ),
                const SizedBox(height: 16),

                // Revision chart
                _ChartCard(
                  title: 'Revision Hours',
                  subtitle: 'Daily revision this month',
                  icon: Icons.refresh_rounded,
                  color: BlockCategory.revision.defaultColor,
                  child: _RevisionLineChart(stats: stats),
                ),
                const SizedBox(height: 16),

                // Category pie chart
                _ChartCard(
                  title: 'Category Distribution',
                  subtitle: 'How time was spent this month',
                  icon: Icons.pie_chart_outline_rounded,
                  color: AppTheme.primaryBlue,
                  child: _CategoryPieChart(
                    studyMins: totalStudyMins,
                    revisionMins: totalRevisionMins,
                    sleepMins: totalSleepMins,
                    wastedMins: totalWastedMins,
                    exerciseMins: stats.fold(0, (s, d) => s + d.exerciseMinutes),
                    otherMins: stats.fold(0, (s, d) => s + d.otherMinutes +
                        d.mealMinutes + d.breakMinutes + d.personalWorkMinutes),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
    );
  }
}

// ─── Month/Year Picker ────────────────────────────────────────────────────────

class _MonthYearPicker extends StatelessWidget {
  final int year;
  final int month;
  final void Function(int year, int month) onChanged;

  const _MonthYearPicker({required this.year, required this.month, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _showPicker(context),
      icon: const Icon(Icons.calendar_month_outlined, size: 18),
      label: Text('${AppDateUtils.getShortMonthName(month)} $year'),
    );
  }

  void _showPicker(BuildContext context) {
    int tempYear = year;
    int tempMonth = month;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Select Month'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: tempYear,
                decoration: const InputDecoration(labelText: 'Year'),
                items: List.generate(AppConstants.maxYear - AppConstants.minYear + 1,
                    (i) => DropdownMenuItem(
                          value: AppConstants.minYear + i,
                          child: Text('${AppConstants.minYear + i}'),
                        )),
                onChanged: (v) => setState(() => tempYear = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: tempMonth,
                decoration: const InputDecoration(labelText: 'Month'),
                items: List.generate(12,
                    (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(AppDateUtils.getMonthName(i + 1)),
                        )),
                onChanged: (v) => setState(() => tempMonth = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                onChanged(tempYear, tempMonth);
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Summary Cards ────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final int totalStudyMins;
  final double avgStudyHours;
  final double consistency;
  final int streak;

  const _SummaryCards({
    required this.totalStudyMins,
    required this.avgStudyHours,
    required this.consistency,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          title: 'Total Study',
          value: AppDateUtils.formatMinutes(totalStudyMins),
          icon: Icons.book_outlined,
          color: BlockCategory.study.defaultColor,
        ),
        _StatCard(
          title: 'Daily Average',
          value: '${avgStudyHours.toStringAsFixed(1)}h',
          icon: Icons.trending_up_rounded,
          color: AppTheme.accentPurple,
        ),
        _StatCard(
          title: 'Consistency',
          value: '${consistency.toStringAsFixed(0)}%',
          icon: Icons.bar_chart_rounded,
          color: AppTheme.accentTeal,
        ),
        _StatCard(
          title: 'Study Streak',
          value: '$streak days',
          icon: Icons.local_fire_department_outlined,
          color: const Color(0xFFF6AD55),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: color, fontWeight: FontWeight.w700,
                  )),
              Text(title, style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Best / Worst Row ─────────────────────────────────────────────────────────

class _BestWorstRow extends StatelessWidget {
  final DailyStatsModel? bestDay;
  final DailyStatsModel? worstDay;

  const _BestWorstRow({this.bestDay, this.worstDay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(child: _DayHighlight(
          label: '🏆 Best Day',
          dateKey: bestDay?.dateKey,
          detail: bestDay != null
              ? AppDateUtils.formatMinutes(bestDay!.totalProductiveMinutes)
              : '—',
          color: const Color(0xFF68D391),
          isDark: isDark,
        )),
        const SizedBox(width: 12),
        Expanded(child: _DayHighlight(
          label: '⚠️ Worst Day',
          dateKey: worstDay?.dateKey,
          detail: worstDay != null
              ? '${AppDateUtils.formatMinutes(worstDay!.wastedMinutes)} wasted'
              : '—',
          color: const Color(0xFFFC8181),
          isDark: isDark,
        )),
      ],
    );
  }
}

class _DayHighlight extends StatelessWidget {
  final String label;
  final String? dateKey;
  final String detail;
  final Color color;
  final bool isDark;

  const _DayHighlight({
    required this.label,
    this.dateKey,
    required this.detail,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            dateKey != null
                ? AppDateUtils.formatDateShort(AppDateUtils.fromDateKey(dateKey!))
                : 'No data',
            style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
          Text(detail, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ─── Chart Card Wrapper ───────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(height: 160, child: child),
        ],
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyAnalytics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_outlined, size: 64, color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'No data for this month',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Start planning your day to see analytics',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Study Line Chart ─────────────────────────────────────────────────────────

class _StudyLineChart extends StatelessWidget {
  final List<DailyStatsModel> stats;
  const _StudyLineChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spots = stats.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.studyHours);
    }).toList();

    final maxY = stats.isEmpty ? 8.0
        : (stats.map((s) => s.studyHours).reduce((a, b) => a > b ? a : b) * 1.2).clamp(1.0, 24.0);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (v) => FlLine(
            color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: stats.length > 15 ? 7 : 3,
              getTitlesWidget: (v, m) {
                final idx = v.toInt();
                if (idx < 0 || idx >= stats.length) return const SizedBox.shrink();
                final d = AppDateUtils.fromDateKey(stats[idx].dateKey);
                return Text('${d.day}',
                    style: TextStyle(fontSize: 10,
                        color: (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, m) => Text('${v.toStringAsFixed(0)}h',
                  style: TextStyle(fontSize: 10,
                      color: (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary))),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (stats.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: BlockCategory.study.defaultColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                radius: 3,
                color: BlockCategory.study.defaultColor,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  BlockCategory.study.defaultColor.withOpacity(0.25),
                  BlockCategory.study.defaultColor.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sleep Bar Chart ──────────────────────────────────────────────────────────

class _SleepBarChart extends StatelessWidget {
  final List<DailyStatsModel> stats;
  const _SleepBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = BlockCategory.sleep.defaultColor;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 3,
          getDrawingHorizontalLine: (v) => FlLine(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: stats.length > 15 ? 7 : 3,
              getTitlesWidget: (v, m) {
                final idx = v.toInt();
                if (idx < 0 || idx >= stats.length) return const SizedBox.shrink();
                final d = AppDateUtils.fromDateKey(stats[idx].dateKey);
                return Text('${d.day}',
                    style: TextStyle(fontSize: 10,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, m) => Text('${v.toStringAsFixed(0)}h',
                  style: TextStyle(fontSize: 10,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        maxY: 12,
        barGroups: stats.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.sleepHours,
                color: color,
                width: stats.length > 20 ? 6 : 10,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Wasted Time Bar Chart ────────────────────────────────────────────────────

class _WastedBarChart extends StatelessWidget {
  final List<DailyStatsModel> stats;
  const _WastedBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = BlockCategory.wastedTime.defaultColor;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: stats.length > 15 ? 7 : 3,
              getTitlesWidget: (v, m) {
                final idx = v.toInt();
                if (idx < 0 || idx >= stats.length) return const SizedBox.shrink();
                final d = AppDateUtils.fromDateKey(stats[idx].dateKey);
                return Text('${d.day}',
                    style: TextStyle(fontSize: 10,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, m) => Text(AppDateUtils.formatMinutes(v.toInt() * 60),
                  style: TextStyle(fontSize: 9,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: stats.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.wastedHours,
                color: color,
                width: stats.length > 20 ? 6 : 10,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Revision Line Chart ──────────────────────────────────────────────────────

class _RevisionLineChart extends StatelessWidget {
  final List<DailyStatsModel> stats;
  const _RevisionLineChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = BlockCategory.revision.defaultColor;
    final spots = stats.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.revisionHours);
    }).toList();

    final maxY = stats.isEmpty ? 4.0
        : (stats.map((s) => s.revisionHours).reduce((a, b) => a > b ? a : b) * 1.2).clamp(1.0, 24.0);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (v) => FlLine(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: stats.length > 15 ? 7 : 3,
              getTitlesWidget: (v, m) {
                final idx = v.toInt();
                if (idx < 0 || idx >= stats.length) return const SizedBox.shrink();
                final d = AppDateUtils.fromDateKey(stats[idx].dateKey);
                return Text('${d.day}',
                    style: TextStyle(fontSize: 10,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, m) => Text('${v.toStringAsFixed(0)}h',
                  style: TextStyle(fontSize: 10,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (stats.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: color,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                radius: 3,
                color: color,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Pie Chart ───────────────────────────────────────────────────────

class _CategoryPieChart extends StatefulWidget {
  final int studyMins;
  final int revisionMins;
  final int sleepMins;
  final int wastedMins;
  final int exerciseMins;
  final int otherMins;

  const _CategoryPieChart({
    required this.studyMins,
    required this.revisionMins,
    required this.sleepMins,
    required this.wastedMins,
    required this.exerciseMins,
    required this.otherMins,
  });

  @override
  State<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<_CategoryPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = [
      ('Study', widget.studyMins, BlockCategory.study.defaultColor),
      ('Revision', widget.revisionMins, BlockCategory.revision.defaultColor),
      ('Sleep', widget.sleepMins, BlockCategory.sleep.defaultColor),
      ('Wasted', widget.wastedMins, BlockCategory.wastedTime.defaultColor),
      ('Exercise', widget.exerciseMins, BlockCategory.exercise.defaultColor),
      ('Other', widget.otherMins, BlockCategory.other.defaultColor),
    ].where((e) => e.$2 > 0).toList();

    final total = data.fold(0, (s, e) => s + e.$2);

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null || response.touchedSection == null) {
                      _touchedIndex = -1;
                    } else {
                      _touchedIndex = response.touchedSection!.touchedSectionIndex;
                    }
                  });
                },
              ),
              sections: data.asMap().entries.map((e) {
                final isTouch = e.key == _touchedIndex;
                return PieChartSectionData(
                  color: e.value.$3,
                  value: e.value.$2.toDouble(),
                  title: isTouch
                      ? '${(e.value.$2 / total * 100).toStringAsFixed(1)}%'
                      : '',
                  radius: isTouch ? 60 : 50,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Legend
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: data.map((e) {
            final pct = total > 0 ? (e.$2 / total * 100).toStringAsFixed(1) : '0';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: e.$3,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${e.$1} $pct%',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
