import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:axiomos_workforce/constants/textstyles.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartData {
  final String category;
  final double value;

  ChartData(this.category, this.value);
}

enum ChartType {
  column,
  line,
  bar,
  pie,
  area,
  scatter,
  doughnut,
  groupedColumn,
}

class DynamicChart extends StatelessWidget {
  final String title;
  final List<ChartData>? data;
  final List<List<ChartData>>? groupedData; // For grouped column chart
  final String? legendName;
  final List<String>? legendNames; // For grouped column chart
  final bool showLegend;
  final ChartType chartType;
  final Color textColor;
  final Color? titleColor;

  DynamicChart({
    Key? key,
    required this.title,
    this.data,
    this.groupedData,
    this.legendName,
    this.legendNames,
    required this.showLegend,
    required this.chartType,
    required this.textColor,
    this.titleColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (chartType) {
      case ChartType.column:
        return _buildColumnChart(context);
      case ChartType.line:
        return _buildLineChart();
      case ChartType.bar:
        return _buildBarChart(context);
      case ChartType.pie:
        return _buildPieChart();
      case ChartType.area:
        return _buildAreaChart();
      case ChartType.scatter:
        return _buildScatterChart();
      case ChartType.doughnut:
        return _buildDoughnutChart();
      case ChartType.groupedColumn:
        return _buildGroupedColumnChart();
      default:
        throw ArgumentError('Invalid chart type');
    }
  }

  Widget _buildColumnChart(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleFontSize = screenWidth < 400 ? 12.0 : 16.0;
    final labelFontSize = screenWidth < 400 ? 10.0 : 12.0;

    final int itemCount = data?.length ?? 0;
    int rotationAngle = 0;

    if (itemCount > 5) {
      rotationAngle = -45;
    }

    return SfCartesianChart(
      margin: const EdgeInsets.all(10),
      title: ChartTitle(
        text: title,
        textStyle: GoogleFonts.roboto(
          textStyle: TextStyles.chartTitle,
        ).copyWith(color: titleColor),
      ),
      plotAreaBorderWidth: showLegend ? 1 : 0, // 👈 removes the graph border
      primaryXAxis: CategoryAxis(
        labelStyle: TextStyle(color: textColor, fontSize: labelFontSize),
        majorGridLines: MajorGridLines(width: 0),
        labelRotation: rotationAngle,
      ),
      primaryYAxis: NumericAxis(
        labelStyle: TextStyle(color: textColor, fontSize: 8),
        axisLine: const AxisLine(width: 0),
        majorGridLines: MajorGridLines(width: 0.5, color: textColor),
      ),
      legend: Legend(isVisible: showLegend),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<dynamic, dynamic>>[
        ColumnSeries<dynamic, dynamic>(
          width: 0.4,
          dataSource: data,
          xValueMapper: (dynamic sales, _) => sales.category,
          yValueMapper: (dynamic sales, _) => sales.value,
          name: legendName,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(color: textColor, fontSize: 8),
          ),
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.greenAccent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    return SfCartesianChart(
      plotAreaBorderWidth: showLegend ? 1 : 0,
      primaryXAxis: CategoryAxis(
        labelStyle: TextStyle(color: textColor, fontSize: 8),
        majorGridLines: MajorGridLines(
          width: showLegend ? 0 : 0, // No grid lines on X-axis anyway
        ),
      ),
      primaryYAxis: NumericAxis(
        labelStyle: TextStyle(color: textColor, fontSize: 8),
        axisLine: const AxisLine(width: 0),
        majorGridLines: MajorGridLines(width: 0.5, color: textColor),
      ),
      title: ChartTitle(
        text: title,
        textStyle: GoogleFonts.roboto(
          textStyle: TextStyles.chartTitle,
        ).copyWith(color: titleColor),
      ),
      legend: Legend(isVisible: showLegend),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<dynamic, dynamic>>[
        LineSeries<dynamic, dynamic>(
          dataSource: data,
          xValueMapper: (dynamic sales, _) => sales.category,
          yValueMapper: (dynamic sales, _) => sales.value,
          name: legendName,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(color: textColor, fontSize: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleFontSize = screenWidth < 400 ? 12.0 : 16.0;
    final labelFontSize = screenWidth < 400 ? 10.0 : 12.0;
    final chartHeight = screenWidth < 400 ? 250.0 : 300.0;
    final List<Color> barColors = [
      Colors.deepOrangeAccent,
      Colors.pinkAccent,
      Colors.redAccent,
      Colors.blueAccent,
      Colors.lightBlueAccent,
      Colors.cyanAccent,
    ];

    return SfCartesianChart(
      plotAreaBorderWidth: showLegend ? 1 : 0,
      title: ChartTitle(
        text: title,
        textStyle: GoogleFonts.roboto(
          textStyle: TextStyles.chartTitle,
        ).copyWith(color: titleColor),
      ),
      primaryXAxis: CategoryAxis(
        majorGridLines: MajorGridLines(
          width: showLegend ? 0 : 0, // No grid lines on X-axis anyway
        ),
        labelStyle: TextStyle(color: textColor, fontSize: 8),
      ),
      primaryYAxis: NumericAxis(
        labelStyle: TextStyle(color: textColor, fontSize: 8),
        axisLine: const AxisLine(width: 0),
        majorGridLines: MajorGridLines(
          dashArray: [10, 8],
          width: 0.5,
          color: textColor,
        ),
      ),
      legend: Legend(isVisible: showLegend),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<dynamic, dynamic>>[
        BarSeries<dynamic, dynamic>(
          color: textColor,
          dataSource: data,
          xValueMapper: (dynamic sales, _) => sales.category,
          yValueMapper: (dynamic sales, _) => sales.value,
          name: legendName,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(color: textColor, fontSize: 8),
          ),
          pointColorMapper: (dynamic sales, int index) =>
              barColors[index % barColors.length], // Assigns different colors
        ),
      ],
    );
  }

  Widget _buildPieChart() {
    return SfCircularChart(
      title: ChartTitle(
        text: title,
        textStyle: GoogleFonts.roboto(
          textStyle: TextStyles.chartTitle,
        ).copyWith(color: titleColor),
      ),
      legend: Legend(isVisible: showLegend),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CircularSeries>[
        PieSeries<ChartData, String>(
          dataSource: data,
          xValueMapper: (ChartData data, _) => data.category,
          yValueMapper: (ChartData data, _) => data.value,
          name: legendName,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(color: textColor, fontSize: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildAreaChart() {
    return SfCartesianChart(
      plotAreaBorderWidth: showLegend ? 1 : 0,
      primaryXAxis: CategoryAxis(
        majorGridLines: MajorGridLines(
          width: showLegend ? 0 : 0, // No grid lines on X-axis anyway
        ),
        labelStyle: TextStyle(color: textColor, fontSize: 8),
      ),
      primaryYAxis: NumericAxis(
        labelStyle: TextStyle(color: textColor, fontSize: 8),
        axisLine: const AxisLine(width: 0),
        majorGridLines: MajorGridLines(width: 0.5, color: textColor),
      ),
      title: ChartTitle(
        text: title,
        textStyle: GoogleFonts.roboto(
          textStyle: TextStyles.chartTitle,
        ).copyWith(color: titleColor),
      ),
      legend: Legend(isVisible: showLegend),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<dynamic, dynamic>>[
        AreaSeries<dynamic, dynamic>(
          dataSource: data,
          xValueMapper: (dynamic sales, _) => sales.category,
          yValueMapper: (dynamic sales, _) => sales.value,
          name: legendName,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(color: textColor, fontSize: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildScatterChart() {
    return SfCartesianChart(
      plotAreaBorderWidth: showLegend ? 1 : 0,
      primaryXAxis: CategoryAxis(
        majorGridLines: MajorGridLines(
          width: showLegend ? 0 : 0, // No grid lines on X-axis anyway
        ),
        labelStyle: TextStyle(color: textColor, fontSize: 8),
      ),
      primaryYAxis: NumericAxis(
        labelStyle: TextStyle(color: textColor, fontSize: 8),
        axisLine: const AxisLine(width: 0),
        majorGridLines: MajorGridLines(width: 0.5, color: textColor),
      ),
      title: ChartTitle(
        text: title,
        textStyle: GoogleFonts.roboto(
          textStyle: TextStyles.chartTitle,
        ).copyWith(color: titleColor),
      ),
      legend: Legend(isVisible: showLegend),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<dynamic, dynamic>>[
        ScatterSeries<dynamic, dynamic>(
          dataSource: data,
          xValueMapper: (dynamic sales, _) => sales.category,
          yValueMapper: (dynamic sales, _) => sales.value,
          name: legendName,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(color: textColor, fontSize: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildDoughnutChart() {
    return SfCircularChart(
      title: ChartTitle(
        text: title,
        textStyle: GoogleFonts.roboto(
          textStyle: TextStyles.chartTitle,
        ).copyWith(color: titleColor),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      legend: Legend(
        isVisible: showLegend,
        position: LegendPosition.bottom, // Places legend below the chart
        orientation: LegendItemOrientation.vertical, // Stack items in a column
        overflowMode:
            LegendItemOverflowMode.wrap, // Wrap to next line if space ends
        alignment: ChartAlignment.near, // Center the legend horizontally
      ),
      series: <CircularSeries>[
        DoughnutSeries<ChartData, String>(
          dataSource: data,
          xValueMapper: (ChartData data, _) => data.category,
          yValueMapper: (ChartData data, _) => data.value,
          name: legendName,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(color: textColor, fontSize: 8),
          ),
          innerRadius: '50%',
        ),
      ],
    );
  }

  Widget _buildGroupedColumnChart() {
    if (groupedData == null || legendNames == null) {
      throw ArgumentError(
        'groupedData and legendNames are required for grouped column chart',
      );
    }

    return SfCartesianChart(
      plotAreaBorderWidth: showLegend ? 1 : 0,
      primaryXAxis: CategoryAxis(
        majorGridLines: MajorGridLines(
          width: showLegend ? 0 : 0, // No grid lines on X-axis anyway
        ),
        labelStyle: TextStyle(color: textColor, fontSize: 8),
      ),
      primaryYAxis: NumericAxis(
        labelStyle: TextStyle(color: textColor, fontSize: 8),
        axisLine: const AxisLine(width: 0),
        majorGridLines: MajorGridLines(width: 0.5, color: textColor),
      ),
      title: ChartTitle(
        text: title,
        textStyle: GoogleFonts.roboto(
          textStyle: TextStyles.chartTitle,
        ).copyWith(color: titleColor),
      ),
      legend: Legend(
        isVisible: showLegend,
        position: LegendPosition.bottom, // Places legend below the chart
        orientation: LegendItemOrientation.vertical, // Stack items in a column
        overflowMode:
            LegendItemOverflowMode.wrap, // Wrap to next line if space ends
        alignment: ChartAlignment.near, // Center the legend horizontally
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: List.generate(groupedData!.length, (index) {
        return ColumnSeries<ChartData, String>(
          dataSource: groupedData![index],
          xValueMapper: (ChartData data, _) => data.category,
          yValueMapper: (ChartData data, _) => data.value,
          name: legendNames![index],
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(color: textColor, fontSize: 8),
          ),
        );
      }),
    );
  }
}
