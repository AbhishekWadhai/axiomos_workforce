import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ProfileDiscoveryChart extends StatelessWidget {
  final List<ChartData> dataThisMonth = [
    ChartData('Apr 2', 1800),
    ChartData('Apr 3', 3700),
    ChartData('Apr 4', 3900),
    ChartData('Apr 5', 4300),
    ChartData('Apr 6', 2800),
    ChartData('Apr 7', 3400),
    ChartData('Apr 8', 2600),
  ];

  final List<ChartData> dataLastMonth = [
    ChartData('Apr 2', 2500),
    ChartData('Apr 3', 3000),
    ChartData('Apr 4', 2900),
    ChartData('Apr 5', 3100),
    ChartData('Apr 6', 5100),
    ChartData('Apr 7', 2100),
    ChartData('Apr 8', 2000),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.transparent, // Background like the image
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Safety Data',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Icon(Icons.arrow_upward, color: Colors.greenAccent),
                Text(
                  ' 26.84% (From last month)',
                  style: TextStyle(color: Colors.greenAccent),
                ),
              ],
            ),
            SizedBox(height: 12),
            Expanded(
              child: SfCartesianChart(
                plotAreaBorderWidth: 0,
                backgroundColor: Colors.transparent,
                primaryXAxis: CategoryAxis(
                  labelStyle: TextStyle(color: Colors.white),
                  majorGridLines: const MajorGridLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  labelStyle: TextStyle(color: Colors.white),
                  axisLine: const AxisLine(width: 0),
                  majorGridLines: MajorGridLines(
                    width: 0.5,
                    color: Colors.white24,
                  ),
                ),
                legend: Legend(isVisible: false),
                series: [
                  ColumnSeries<ChartData, String>(
                    dataSource: dataThisMonth,
                    xValueMapper: (ChartData data, _) => data.day,
                    yValueMapper: (ChartData data, _) => data.value,
                    color: Colors.greenAccent,
                    width: 0.4,
                  ),
                  ColumnSeries<ChartData, String>(
                    dataSource: dataLastMonth,
                    xValueMapper: (ChartData data, _) => data.day,
                    yValueMapper: (ChartData data, _) => data.value,
                    color: Colors.amberAccent,
                    width: 0.4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  final String day;
  final double value;
  ChartData(this.day, this.value);
}
