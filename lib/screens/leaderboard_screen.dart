import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<int> skorlar = [];

  @override
  void initState() {
    super.initState();
    _skorlariYukle();
  }

  void _skorlariYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      skorlar = prefs.getStringList('skorlar')?.map((e) => int.parse(e)).toList() ?? [];
      skorlar.sort((a, b) => b.compareTo(a));
      skorlar = skorlar.take(10).toList(); // Sadece ilk 10 skor
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("LİDERLİK TABLOSU", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // İlk 3 Skor
            if (skorlar.isNotEmpty) ...[
              _buildPodium(),
              const SizedBox(height: 30),
            ],
            
            // Diğer Skorlar
            Expanded(
              child: skorlar.isEmpty
                ? const Center(
                    child: Text(
                      "Henüz skor yok!\nOyunu oynayarak ilk skoru ekle.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: skorlar.length,
                    itemBuilder: (context, index) {
                      return _buildSkorKarti(index + 1, skorlar[index]);
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium() {
    if (skorlar.isEmpty) return const SizedBox.shrink();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 2. Lider
        if (skorlar.length > 1)
          _buildPodiumItem(2, skorlar[1], const Color(0xFF8B8B8B)),
        
        // 1. Lider
        _buildPodiumItem(1, skorlar[0], const Color(0xFFFFD700)),
        
        // 3. Lider
        if (skorlar.length > 2)
          _buildPodiumItem(3, skorlar[2], const Color(0xFFCD7F32)),
      ],
    );
  }

  Widget _buildPodiumItem(int sira, int skor, Color renk) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: renk,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: renk.withValues(alpha: 0.3), blurRadius: 10)],
          ),
          child: Center(
            child: Text(
              "$sira",
              style: const TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "$skor",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSkorKarti(int sira, int skor) {
    Color renk = sira <= 3 
      ? (sira == 1 ? const Color(0xFFFFD700) : sira == 2 ? const Color(0xFF8B8B8B) : const Color(0xFFCD7F32))
      : Colors.white;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                "$sira",
                style: TextStyle(
                  color: renk,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              "$skor Puan",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (sira == 1)
            const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 24),
        ],
      ),
    );
  }
}
