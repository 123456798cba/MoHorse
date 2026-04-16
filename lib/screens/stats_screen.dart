import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_data_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// 统计页面 - 支持月度/年度统计
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 月度数据
  late DateTime _currentMonth;
  Map<String, double> _categorySummary = {};
  Map<int, double> _dailyExpense = {};
  double _totalExpense = 0;
  double _totalIncome = 0;
  
  // 年度数据
  late int _currentYear;
  Map<String, double> _yearCategorySummary = {};
  Map<int, double> _yearMonthlyExpense = {};
  double _yearTotalExpense = 0;
  double _yearTotalIncome = 0;
  List<MapEntry<String, double>> _topCategories = [];
  
  bool _isLoading = true;

  // 分类颜色
  static const Map<String, Color> _categoryColors = {
    '餐饮': Color(0xFFFF6B6B),
    '交通': Color(0xFF4ECDC4),
    '购物': Color(0xFF45B7D1),
    '娱乐': Color(0xFF96CEB4),
    '住房': Color(0xFFFFEAA7),
    '医疗': Color(0xFFDDA0DD),
    '教育': Color(0xFF98D8C8),
    '工资': Color(0xFF87CEEB),
    '其他': Color(0xFFB8B8B8),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _currentYear = DateTime.now().year;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final provider = context.read<AppDataProvider>();
    
    // 加载月度数据
    _categorySummary = await provider.getMonthCategorySummary(_currentMonth.year, _currentMonth.month);
    _dailyExpense = await provider.getMonthDailyExpense(_currentMonth.year, _currentMonth.month);
    final monthBills = await provider.getMonthBills(_currentMonth.year, _currentMonth.month);
    _totalExpense = monthBills.where((b) => b.amount < 0).fold(0.0, (s, b) => s + b.amount);
    _totalIncome = monthBills.where((b) => b.amount > 0).fold(0.0, (s, b) => s + b.amount);
    
    // 加载年度数据
    _yearCategorySummary = await provider.getYearCategorySummary(_currentYear);
    _yearMonthlyExpense = await provider.getYearMonthlyExpense(_currentYear);
    _yearTotalExpense = await provider.getYearExpense(_currentYear);
    _yearTotalIncome = await provider.getYearIncome(_currentYear);
    _topCategories = await provider.getYearTopCategories(_currentYear);

    setState(() => _isLoading = false);
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
    });
    _loadMonthData();
  }

  void _changeYear(int delta) {
    setState(() {
      _currentYear += delta;
    });
    _loadYearData();
  }

  Future<void> _loadMonthData() async {
    setState(() => _isLoading = true);
    final provider = context.read<AppDataProvider>();
    
    _categorySummary = await provider.getMonthCategorySummary(_currentMonth.year, _currentMonth.month);
    _dailyExpense = await provider.getMonthDailyExpense(_currentMonth.year, _currentMonth.month);
    final monthBills = await provider.getMonthBills(_currentMonth.year, _currentMonth.month);
    _totalExpense = monthBills.where((b) => b.amount < 0).fold(0.0, (s, b) => s + b.amount);
    _totalIncome = monthBills.where((b) => b.amount > 0).fold(0.0, (s, b) => s + b.amount);
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadYearData() async {
    setState(() => _isLoading = true);
    final provider = context.read<AppDataProvider>();
    
    _yearCategorySummary = await provider.getYearCategorySummary(_currentYear);
    _yearMonthlyExpense = await provider.getYearMonthlyExpense(_currentYear);
    _yearTotalExpense = await provider.getYearExpense(_currentYear);
    _yearTotalIncome = await provider.getYearIncome(_currentYear);
    _topCategories = await provider.getYearTopCategories(_currentYear);
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('收支统计', style: TextStyle(color: theme.colorScheme.onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            if (index == 0) _loadMonthData();
            else _loadYearData();
          },
          tabs: const [
            Tab(text: '月度统计'),
            Tab(text: '年度统计'),
          ],
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          indicatorColor: theme.colorScheme.primary,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMonthView(theme),
                _buildYearView(theme),
              ],
            ),
    );
  }

  // ==================== 月度视图 ====================
  Widget _buildMonthView(ThemeData theme) {
    final monthStr = DateFormat('yyyy年M月').format(_currentMonth);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthSelector(theme, monthStr),
          const SizedBox(height: 16),
          _buildMonthOverview(theme),
          const SizedBox(height: 24),
          if (_categorySummary.isNotEmpty) ...[
            Text('分类支出', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 16),
            _buildPieChart(theme),
            const SizedBox(height: 24),
          ],
          if (_dailyExpense.isNotEmpty) ...[
            Text('每日支出趋势', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 16),
            _buildLineChart(theme),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(ThemeData theme, String monthStr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _changeMonth(-1),
          color: theme.colorScheme.onSurface,
        ),
        Text(monthStr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => _changeMonth(1),
          color: theme.colorScheme.onSurface,
        ),
      ],
    );
  }

  Widget _buildMonthOverview(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('支出', style: TextStyle(fontSize: 13, color: theme.colorScheme.error.withValues(alpha: 0.7))),
                const SizedBox(height: 4),
                Text('¥${_totalExpense.abs().toStringAsFixed(0)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.error)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('收入', style: TextStyle(fontSize: 13, color: Colors.green.withValues(alpha: 0.7))),
                const SizedBox(height: 4),
                Text('¥${_totalIncome.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== 年度视图 ====================
  Widget _buildYearView(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildYearSelector(theme),
          const SizedBox(height: 16),
          _buildYearOverview(theme),
          const SizedBox(height: 24),
          Text('月度支出对比', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 16),
          _buildYearBarChart(theme),
          const SizedBox(height: 24),
          if (_topCategories.isNotEmpty) ...[
            Text('支出排行榜 Top 5', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 16),
            _buildTopCategories(theme),
            const SizedBox(height: 24),
          ],
          if (_yearCategorySummary.isNotEmpty) ...[
            Text('年度分类统计', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 16),
            _buildYearPieChart(theme),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildYearSelector(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _changeYear(-1),
          color: theme.colorScheme.onSurface,
        ),
        Text('${_currentYear}年', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => _changeYear(1),
          color: theme.colorScheme.onSurface,
        ),
      ],
    );
  }

  Widget _buildYearOverview(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.error, theme.colorScheme.error.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.arrow_downward, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text('年度支出', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('¥${_yearTotalExpense.abs().toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text('年度收入', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('¥${_yearTotalIncome.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildYearStatItem(theme, '月均支出', '¥${(_yearTotalExpense.abs() / 12).toStringAsFixed(0)}'),
              Container(width: 1, height: 30, color: theme.colorScheme.outline.withValues(alpha: 0.2)),
              _buildYearStatItem(theme, '月均收入', '¥${(_yearTotalIncome / 12).toStringAsFixed(0)}'),
              Container(width: 1, height: 30, color: theme.colorScheme.outline.withValues(alpha: 0.2)),
              _buildYearStatItem(theme, '月均结余', '¥${((_yearTotalIncome + _yearTotalExpense) / 12).toStringAsFixed(0)}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYearStatItem(ThemeData theme, String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
      ],
    );
  }

  Widget _buildYearBarChart(ThemeData theme) {
    final maxExpense = _yearMonthlyExpense.values.fold(0.0, (max, v) => v.abs() > max ? v.abs() : max);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxExpense * 1.2,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt() + 1}月', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)));
                },
                reservedSize: 22,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: List.generate(12, (index) {
            final value = _yearMonthlyExpense[index + 1]?.abs() ?? 0;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: value,
                  color: theme.colorScheme.primary,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTopCategories(ThemeData theme) {
    return Column(
      children: _topCategories.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value;
        final color = _categoryColors[category.key] ?? const Color(0xFFB8B8B8);
        final maxValue = _topCategories.first.value.abs();
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: index == 0 ? Colors.amber : (index == 1 ? Colors.grey : (index == 2 ? Colors.brown.shade300 : color)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.key, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: category.value.abs() / maxValue,
                        backgroundColor: color.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text('¥${category.value.abs().toStringAsFixed(0)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildYearPieChart(ThemeData theme) {
    final total = _yearCategorySummary.values.fold(0.0, (s, v) => s + v.abs());

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: PieChart(
              PieChartData(
                sections: _yearCategorySummary.entries.map((e) {
                  final color = _categoryColors[e.key] ?? const Color(0xFFB8B8B8);
                  return PieChartSectionData(
                    value: e.value.abs(),
                    title: '',
                    color: color,
                    radius: 30,
                    borderSide: BorderSide(color: theme.colorScheme.surface, width: 2),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _yearCategorySummary.entries.map((e) {
                final color = _categoryColors[e.key] ?? const Color(0xFFB8B8B8);
                final percent = (e.value.abs() / total * 100).toStringAsFixed(1);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 6),
                      Expanded(child: Text(e.key, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface))),
                      Text('$percent%', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 通用图表 ====================
  Widget _buildPieChart(ThemeData theme) {
    final total = _categorySummary.values.fold(0.0, (s, v) => s + v.abs());

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: PieChart(
              PieChartData(
                sections: _categorySummary.entries.map((e) {
                  final color = _categoryColors[e.key] ?? const Color(0xFFB8B8B8);
                  return PieChartSectionData(
                    value: e.value.abs(),
                    title: '',
                    color: color,
                    radius: 30,
                    borderSide: BorderSide(color: theme.colorScheme.surface, width: 2),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _categorySummary.entries.map((e) {
                final color = _categoryColors[e.key] ?? const Color(0xFFB8B8B8);
                final percent = (e.value.abs() / total * 100).toStringAsFixed(1);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 6),
                      Expanded(child: Text(e.key, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface))),
                      Text('$percent%', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(ThemeData theme) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final maxExpense = _dailyExpense.values.fold(0.0, (max, v) => v.abs() > max ? v.abs() : max);

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() % 5 == 0 && value.toInt() <= daysInMonth) {
                    return Text('${value.toInt()}', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _dailyExpense.entries.map((e) => FlSpot(e.key.toDouble(), e.value.abs())).toList()..sort((a, b) => a.x.compareTo(b.x)),
              isCurved: true,
              color: theme.colorScheme.error,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 3, color: theme.colorScheme.error, strokeWidth: 0),
              ),
              belowBarData: BarAreaData(show: true, color: theme.colorScheme.error.withValues(alpha: 0.1)),
            ),
          ],
          minY: 0,
          maxY: maxExpense * 1.2,
        ),
      ),
    );
  }
}
