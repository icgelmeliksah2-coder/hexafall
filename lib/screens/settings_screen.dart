import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool sesAcikMi = true;
  bool titresimAcikMi = true;
  double zorlukSeviyesi = 1.0;

  @override
  void initState() {
    super.initState();
    _ayarlariYukle();
  }

  void _ayarlariYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      sesAcikMi = prefs.getBool('sesAcikMi') ?? true;
      titresimAcikMi = prefs.getBool('titresimAcikMi') ?? true;
      zorlukSeviyesi = prefs.getDouble('zorlukSeviyesi') ?? 1.0;
    });
  }

  void _ayarlariKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sesAcikMi', sesAcikMi);
    await prefs.setBool('titresimAcikMi', titresimAcikMi);
    await prefs.setDouble('zorlukSeviyesi', zorlukSeviyesi);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("AYARLAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Ses Ayarı
            _buildAyarKarti(
              "Ses Efektleri",
              "Oyun seslerini aç/kapat",
              Icons.volume_up,
              Switch(
                value: sesAcikMi,
                onChanged: (value) {
                  setState(() {
                    sesAcikMi = value;
                  });
                  _ayarlariKaydet();
                },
                activeThumbColor: const Color(0xFF00FF41),
                activeTrackColor: const Color(0xFF00FF41),
              ),
            ),
            const SizedBox(height: 15),
            
            // Titreşim Ayarı
            _buildAyarKarti(
              "Titreşim",
              "Haptik geri bildirim",
              Icons.vibration,
              Switch(
                value: titresimAcikMi,
                onChanged: (value) {
                  setState(() {
                    titresimAcikMi = value;
                  });
                  _ayarlariKaydet();
                },
                activeThumbColor: const Color(0xFF00FF41),
                activeTrackColor: const Color(0xFF00FF41),
              ),
            ),
            const SizedBox(height: 15),
            
            // Zorluk Seviyesi
            _buildAyarKarti(
              "Zorluk Seviyesi",
              "Oyun hızı ${(zorlukSeviyesi * 100).toInt()}%",
              Icons.speed,
              Slider(
                value: zorlukSeviyesi,
                min: 0.5,
                max: 2.0,
                divisions: 3,
                onChanged: (value) {
                  setState(() {
                    zorlukSeviyesi = value;
                  });
                  _ayarlariKaydet();
                },
                activeColor: const Color(0xFF00FF41),
                inactiveColor: Colors.white24,
              ),
            ),
            const SizedBox(height: 30),
            
            // Veri Temizleme Butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3131),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _verileriTemizle,
                icon: const Icon(Icons.delete_forever),
                label: const Text("TÜM VERİYİ TEMİZLE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAyarKarti(String baslik, String aciklama, IconData icon, Widget widget) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withAlpha(25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF38BDF8), size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(aciklama, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          widget,
        ],
      ),
    );
  }

  void _verileriTemizle() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("Emin misin?", style: TextStyle(color: Colors.white)),
        content: const Text("Tüm skorlar ve ayarlar silinecek. Bu işlem geri alınamaz.", 
          style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İPTAL", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(this.context);
              final messenger = ScaffoldMessenger.of(this.context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              navigator.pop();
              navigator.pop();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text("Tüm veriler temizlendi!"),
                  backgroundColor: Color(0xFF00FF41),
                ),
              );
            },
            child: const Text("TEMİZLE", style: TextStyle(color: Color(0xFFFF3131))),
          ),
        ],
      ),
    );
  }
}
