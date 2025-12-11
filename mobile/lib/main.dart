import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'database/app_database.dart';
import 'widgets/mood_chart.dart'; 

late AppDatabase database;

void main() {
  database = AppDatabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Map AI',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const JournalPage(),
    );
  }
}

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final TextEditingController _controller = TextEditingController();
  final Dio _dio = Dio();
  
  // GANTI IP INI SESUAI SETUP (Emulator: 10.0.2.2, HP Fisik: IP Laptop)
  // final String _backendUrl = "http://10.0.2.2:8000/analyze"; 
  final String _backendUrl = "http://192.168.18.17:8000/analyze";
  
  double _moodValue = 50;
  bool _isAnalyzing = false; 

  // Fungsi Pintar: Simpan Lokal -> Kirim ke AI -> Update Lokal
  void _saveAndAnalyze() async {
    if (_controller.text.isEmpty) return;
    
    final text = _controller.text;
    final mood = _moodValue.toInt();
    
    // 1. Simpan ke Database Lokal 
    final newId = await database.insertEntry(text, mood);
    
    _controller.clear();
    setState(() => _isAnalyzing = true); 
    
    try {
      // 2. Kirim ke Backend FastAPI
      final response = await _dio.post(_backendUrl, data: {
        "text": text,
        "mood_score": mood
      });

      // 3. Ambil hasil dari Backend
      final data = response.data['ai_analysis'];
      final summary = data['summary'];
      
      // --- LOGIKA KRISIS ---
      // Ambil tips sebagai List 
      final rawTips = List<String>.from(data['tips']);
      
      // Cek apakah ada tag "CRISIS"
      if (rawTips.contains("CRISIS")) {
        if (mounted) {
           _showCrisisAlert(); 
        }
      }

      // Gabung jadi string untuk disimpan di DB
      final tipsString = rawTips.join(", "); 

      // 4. Update Database Lokal dengan hasil AI
      await database.updateAiAnalysis(newId, summary, tipsString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✨ Analisis AI Selesai!")),
        );
      }

    } catch (e) {
      // Kalau internet mati/server error, data tetap aman di lokal
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal analisa AI (Disimpan Offline): $e")),
        );
      }
    } finally {
      setState(() => _isAnalyzing = false); 
    }
  }

  // --- WIDGET POPUP DARURAT ---
  void _showCrisisAlert() {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
            SizedBox(width: 10),
            Text("Kamu Tidak Sendiri", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Sepertinya kamu sedang dalam kondisi yang sangat berat. \n\nTolong, jangan simpan ini sendirian. Hubungi seseorang yang kamu percaya atau bantuan profesional sekarang juga.",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              // Di sini bisa pasang url_launcher ke 119
              Navigator.pop(context);
            },
            child: const Text("HUBUNGI BANTUAN (119)"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Saya Mengerti", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Mental Map")),
      body: Column(
        children: [
          // --- INPUT AREA ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Ceritakan harimu...",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text("Mood: ${_moodValue.round()}"),
                    Expanded(
                      child: Slider(
                        value: _moodValue,
                        min: 0, max: 100, divisions: 10,
                        onChanged: (val) => setState(() => _moodValue = val),
                      ),
                    ),
                    // Tombol Kirim berubah jadi Loading kalau sedang proses
                    _isAnalyzing 
                      ? const CircularProgressIndicator()
                      : IconButton(
                          icon: const Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 32),
                          onPressed: _saveAndAnalyze,
                        )
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          
          // --- VISUALISASI & LIST HISTORY ---
          Expanded(
            child: StreamBuilder<List<JournalEntry>>(
              stream: database.getAllEntries().asStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final entries = snapshot.data!;
                
                // Gunakan Column agar Grafik ada di atas List
                return Column(
                  children: [
                    // 1. TAMPILKAN GRAFIK (Hanya jika ada data)
                    if (entries.isNotEmpty) 
                      MoodChart(entries: entries),

                    // 2. LIST HISTORY 
                    Expanded(
                      child: ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final item = entries[index];
                          final hasAi = item.aiSummary != null;
                          
                          // Cek apakah ini entri krisis untuk styling khusus
                          final isCrisis = item.aiTags?.contains("CRISIS") ?? false;

                          return Card(
                            color: isCrisis ? Colors.red.shade50 : null, 
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: item.moodScore > 50 ? Colors.green[100] : Colors.orange[100],
                                child: Text(item.moodScore > 50 ? "😊" : "😐"),
                              ),
                              title: Text(item.content, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  if (hasAi) ...[
                                    Text("🤖 AI: ${item.aiSummary}", style: TextStyle(color: Colors.purple[700], fontStyle: FontStyle.italic)),
                                    const SizedBox(height: 2),
                                    Text(
                                      "💡 Tips: ${item.aiTags}", 
                                      style: TextStyle(
                                        color: isCrisis ? Colors.red[900] : Colors.green[700], 
                                        fontWeight: isCrisis ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 12
                                      )
                                    ),
                                  ] else 
                                    const Text("Menunggu analisa...", style: TextStyle(color: Colors.grey)),
                                  
                                  Text(item.createdAt.toString().substring(0, 16), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}