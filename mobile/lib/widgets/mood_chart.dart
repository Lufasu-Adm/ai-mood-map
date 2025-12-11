import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart'; 

class MoodChart extends StatelessWidget {
  final List<JournalEntry> entries;

  const MoodChart({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    // 1. Ambil maksimal 7 data terakhir biar grafik enak dilihat
    final data = entries.length > 7 ? entries.sublist(0, 7) : entries;
    
    // 2. Balik urutan: Database kasih (Baru -> Lama), Grafik butuh (Lama -> Baru)
    // Supaya data kemarin ada di kiri, data hari ini di kanan.
    final reversedData = data.reversed.toList();

    return AspectRatio(
      aspectRatio: 1.70, // Rasio lebar:tinggi grafik
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.shade800,
              Colors.deepPurple.shade500,
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(right: 18, left: 12, top: 24, bottom: 12),
          child: LineChart(
            mainData(reversedData),
          ),
        ),
      ),
    );
  }

  LineChartData mainData(List<JournalEntry> data) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20, // Garis bantu setiap kelipatan 20
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.white.withOpacity(0.1),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        
        // Label Bawah (Tanggal)
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < data.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('dd/MM').format(data[index].createdAt),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        
        // Label Kiri (Skor Mood)
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
            getTitlesWidget: (value, meta) {
              if (value == 0 || value == 100) return const SizedBox(); // Sembunyikan 0 dan 100 biar rapi
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              );
            },
            reservedSize: 28,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (data.length - 1).toDouble(),
      minY: 0,
      maxY: 100,
      
      // Data Garisnya
      lineBarsData: [
        LineChartBarData(
          spots: data.asMap().entries.map((e) {
            return FlSpot(e.key.toDouble(), e.value.moodScore.toDouble());
          }).toList(),
          isCurved: true, // Garis melengkung halus
          color: Colors.white,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true), // Titik pada setiap data
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}