import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'dart:async';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // --- OYUN DEĞİŞKENLERİ ---
  double rotationAngle = 0.0;
  int _rotasyonIndeksi = 0;
  int skor = 0;
  int enYuksekSkor = 0;
  int kombo = 0;
  int seviye = 1;
  int kenarSayisi = 3; 
  double cubukPozisyonu = -1.1; 
  double temelHiz = 0.016;
  
  // Can sistemi
  int can = 3;
  int maksCan = 3;
  bool canKorumaAktif = false;
  int canKorumaSuresi = 0;
  
  // Güç sistemleri
  bool yavaslatmaAktif = false;
  int yavaslatmaSuresi = 0;
  bool cokluPuanAktif = false;
  int cokluPuanSuresi = 0;
  
  // Mobil optimize
  bool mobilCihazMi = false; 
 
  // Layout / fizik ölçüleri (pixel) - mobil optimize
  double _oyunAlanGenislik = 0;
  double _oyunAlanYukseklik = 0;
  double _ringSize = 0; // Dinamik ayarlanacak
  double _ringBottom = 0; // Dinamik ayarlanacak
  double _barHeightPx = 0; // Dinamik ayarlanacak
  double _barWidthPx = 0; // Dinamik ayarlanacak
  bool _carpismaIslendi = false;

  int _pulseTick = 0;
  int _burstTick = 0;
  bool _yanlisVurusFlash = false;
  
  Timer? _oyunDongusu;
  Color cubukRengi = const Color(0xFF00FF41); 
  bool oyunBittiMi = false;
  bool vurusEfektiAktif = false;
  bool oyunDurdurulduMu = false;
  bool mukemmelVurusEfekti = false;
  
  // Level sistemi
  int seviyeSkoru = 0;
  double hizCarpani = 1.0;
  
  // Efektler için
  List<Widget> komboEfektleri = [];
  
  // Renk sistemi
  int _sonCubukIndeksi = -1;
  List<Color> aktifRenkler = [];
  final math.Random _random = math.Random();

  final List<Color> anaRenkler = [
    const Color(0xFF00FF41), // Neon Yeşil
    const Color(0xFFFF006E), // Neon Pembe
    const Color(0xFF8338EC), // Neon Mor
    const Color(0xFFFFBE0B), // Neon Sarı
    const Color(0xFF00F5FF), // Neon Turkuaz
    const Color(0xFFFF3131), // Neon Kırmızı
    const Color(0xFF39FF14), // Neon Lime
    const Color(0xFFFF6600), // Neon Turuncu
  ];

  @override
  void initState() {
    super.initState();
    
    // Mobil cihaz tespiti
    mobilCihazMi = _mobilCihazMi();
    
    // Başlangıç renk sistemini ayarla
    aktifRenkler = anaRenkler.take(3).toList();
    _sonCubukIndeksi = -1;
    
    _yeniCubukOlustur();
    WidgetsBinding.instance.addPostFrameCallback((_) => _motoruBaslat());
  }
  
  void _boyutlariAyarla(double width, double height) {
    // Mobil cihazlara göre boyutları dinamik ayarla
    if (mobilCihazMi) {
      _ringSize = width * 0.35; // Ekran genişliğinin %35'i
      _ringBottom = height * 0.15; // Ekran yüksekliğinin %15'i
      _barHeightPx = height * 0.12; // Ekran yüksekliğinin %12'i
      _barWidthPx = width * 0.04; // Ekran genişliğinin %4'i
    } else {
      _ringSize = math.min(width, height) * 0.4;
      _ringBottom = height * 0.18;
      _barHeightPx = height * 0.1;
      _barWidthPx = width * 0.03;
    }
    
    _oyunAlanGenislik = width;
    _oyunAlanYukseklik = height;
  }
  
  bool _mobilCihazMi() {
    return defaultTargetPlatform == TargetPlatform.iOS ||
           defaultTargetPlatform == TargetPlatform.android;
  }

  List<Widget> _patlamaParcaciklari({
    required double centerX,
    required double centerY,
    required Color renk,
  }) {
    if (!vurusEfektiAktif) return const [];

    return List.generate(12, (i) {
      final rnd = math.Random((_burstTick * 9973) + i);
      final angle = rnd.nextDouble() * math.pi * 2;
      final dist = 18 + rnd.nextDouble() * 44;
      final size = 3 + rnd.nextDouble() * 5;
      final dur = Duration(milliseconds: 260 + rnd.nextInt(120));

      return TweenAnimationBuilder<double>(
        key: ValueKey('burst_${_burstTick}_$i'),
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: dur,
        curve: Curves.easeOut,
        builder: (context, value, child) {
          final dx = math.cos(angle) * dist * value;
          final dy = math.sin(angle) * dist * value;
          return Positioned(
            left: centerX + dx - (size / 2),
            top: centerY + dy - (size / 2),
            child: Opacity(
              opacity: (1 - value).clamp(0.0, 1.0),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: renk,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: renk.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  void _motoruBaslat() {
    _oyunDongusu?.cancel();
    _oyunDongusu = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted || oyunBittiMi || oyunDurdurulduMu) {
        timer.cancel();
        return;
      }

      setState(() {
        // Güç sistemlerini güncelle
        _gucSistemleriniGuncelle();
        
        // Hız ayarı (yavaşlatma aktifse)
        double hizCarpani = yavaslatmaAktif ? 0.5 : 1.0;
        double anlikHiz = temelHiz * hizCarpani + (skor * 0.0004);
        
        // Mobil cihazlarda daha yavaş başla
        if (mobilCihazMi && skor < 50) {
          anlikHiz *= 0.8;
        }
        
        cubukPozisyonu += anlikHiz;
        
        // Çarpışma Bölgesi (Tam merkezdeki şeklin üstü)
        if (cubukPozisyonu >= 0.73 && cubukPozisyonu <= 0.77) {
          _carpismayiKontrolEt();
        }

        // Kaçırma Durumu
        if (cubukPozisyonu > 1.05) {
          _oyunuBitir();
        }
      });
    });
  }

  void _yeniCubukOlustur() {
    setState(() {
      if (aktifRenkler.isEmpty) {
        cubukRengi = const Color(0xFF00FF41);
      } else {
        int yeniIndeks;
        if (aktifRenkler.length == 1) {
          yeniIndeks = 0;
        } else {
          do {
            yeniIndeks = _random.nextInt(aktifRenkler.length);
          } while (yeniIndeks == _sonCubukIndeksi);
        }
        cubukRengi = aktifRenkler[yeniIndeks];
        _sonCubukIndeksi = yeniIndeks;
      }

      cubukPozisyonu = -1.1; 
      _carpismaIslendi = false;
    });
  }

  void _fizikselCarpismaKontrolEt() {
    if (_oyunAlanYukseklik <= 0 || _oyunAlanGenislik <= 0) return;
    if (_carpismaIslendi) return;

    // Align matematiği: child'ın top'u (0..h-barH)
    final double t = (cubukPozisyonu + 1) / 2;
    final double barTop = t * (_oyunAlanYukseklik - _barHeightPx);
    final double barBottom = barTop + _barHeightPx;

    // Daire: Positioned(bottom: _ringBottom) ve size: _ringSize
    final double ringCenterY = _oyunAlanYukseklik - _ringBottom - (_ringSize / 2);
    final double temasY = ringCenterY - (_ringSize / 2); // üst çeper noktası

    if (barBottom >= temasY) {
      // Fiziksel engel: içeri geçme, çeperde dur
      final double barTopClamped = temasY - _barHeightPx;
      final double denom = (_oyunAlanYukseklik - _barHeightPx).clamp(1.0, double.infinity);
      final double tClamped = (barTopClamped / denom).clamp(0.0, 1.0);
      cubukPozisyonu = (tClamped * 2) - 1;
      
      // Görsel geri bildirim: kısa bir titreme efekti
      if (!_carpismaIslendi) {
        _carpismaIslendi = true;
        HapticFeedback.mediumImpact();
      }

      _carpismayiKontrolEt();
    }
  }

  int _ustSegmentIndeksi() {
    final double step = 2 * math.pi / kenarSayisi;
    double aci = (-rotationAngle) % (2 * math.pi);
    if (aci < 0) aci += 2 * math.pi;
    return ((aci + (step / 2)) / step).floor() % kenarSayisi;
  }

  void _dondur(bool sagaMi) {
    if (oyunBittiMi || oyunDurdurulduMu) return;
    HapticFeedback.lightImpact(); 
    setState(() {
      // Tek yön modu (A): her input = sıradaki rengi üste getir
      final int delta = 1;
      _rotasyonIndeksi = (_rotasyonIndeksi + delta) % kenarSayisi;
      if (_rotasyonIndeksi < 0) _rotasyonIndeksi += kenarSayisi;

      // Segment'e snap: üstteki renk her basışta tam hizaya oturur
      final double step = 2 * math.pi / kenarSayisi;
      rotationAngle = -_rotasyonIndeksi * step;
    });
  }

  void _carpismayiKontrolEt() {
    // Şeklin o anki dönüş açısını normalize et
    double aci = (-rotationAngle) % (2 * math.pi);
    if (aci < 0) aci += 2 * math.pi;
    
    // En tepedeki segmentin indeksini bul
    // Üstte çizgiye değil, segmentin ORTASINA göre hesapla
    final double step = 2 * math.pi / kenarSayisi;
    final double aciMerkezOffset = (aci + (step / 2)) % (2 * math.pi);
    int segmentIndeksi = (aciMerkezOffset / step).floor() % kenarSayisi;
    
    // Renk nesne karşılaştırması
    if (cubukRengi == aktifRenkler[segmentIndeksi]) {
      _basariliVurus();
    } else {
      // Yanlış renk = oyun biti
      if (!_yanlisVurusFlash) {
        setState(() => _yanlisVurusFlash = true);
        Future.delayed(const Duration(milliseconds: 180), () {
          if (mounted) setState(() => _yanlisVurusFlash = false);
        });
      }
      _oyunuBitir();
    }
  }

  void _basariliVurus() {
    setState(() {
      _pulseTick++;
      _burstTick++;
      kombo++;
      seviyeSkoru++;
      
      // Güç sistemlerini güncelle
      _gucSistemleriniGuncelle();
      
      // Kombo bonusları
      int komboBonusu = 0;
      if (kombo >= 20) {
        komboBonusu = 5;
      } else if (kombo >= 15) {
        komboBonusu = 4;
      } else if (kombo >= 10) {
        komboBonusu = 3;
      } else if (kombo >= 5) {
        komboBonusu = 2;
      } else if (kombo >= 3) {
        komboBonusu = 1;
      }
      
      // Çoklu puan aktifse 2x
      int puanCarpani = cokluPuanAktif ? 2 : 1;
      skor += (10 + komboBonusu * 5) * puanCarpani;
      vurusEfektiAktif = true;
      
      // Kombo efektleri ekle
      _komboEfektiEkle(kombo);
      
      // Mükemmel vuruş kontrolü
      if (cubukPozisyonu >= 0.73 && cubukPozisyonu <= 0.77) {
        mukemmelVurusEfekti = true;
        skor += 5 * puanCarpani; // Mükemmel vuruş bonusu
        
        // Her 5 mükemmel vuruşta rastgele güç
        if (kombo % 5 == 0) {
          _rastgeleGucVer();
        }
      }
      
      if (skor > enYuksekSkor) {
        enYuksekSkor = skor;
        _enYuksekSkoruKaydet();
      }
    });
    
    _yeniCubukOlustur();
    
    // Level atlama sistemi
    if (seviyeSkoru >= 10 && kenarSayisi < anaRenkler.length) {
      seviye++;
      seviyeSkoru = 0;
      kenarSayisi = math.min(3 + (seviye - 1), anaRenkler.length);
      _rotasyonIndeksi = 0;
      rotationAngle = 0;

      aktifRenkler = anaRenkler.take(kenarSayisi).toList();
      _sonCubukIndeksi = -1;

      _seviyeGecisEfekti();
    }
    
    // Efektleri sıfırla
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => vurusEfektiAktif = false);
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => mukemmelVurusEfekti = false);
    });
  }

  void _oyunuBitir() {
    if (oyunBittiMi) return;
    
    // Can koruma aktifse can azma
    if (canKorumaAktif) {
      canKorumaAktif = false;
      canKorumaSuresi = 0;
      _yeniCubukOlustur();
      return;
    }
    
    setState(() {
      can--;
      if (can <= 0) {
        oyunBittiMi = true;
        _oyunDongusu?.cancel();
        _skoruKaydet();
      } else {
        // Can koruma aktif et
        canKorumaAktif = true;
        canKorumaSuresi = 3; // 3 saniye koruma
        _yeniCubukOlustur();
      }
    });
  }

  void _oyunuSifirlaVeBaslat() {
    setState(() {
      skor = 0;
      kombo = 0;
      seviye = 1;
      seviyeSkoru = 0;
      kenarSayisi = 3;
      _rotasyonIndeksi = 0;
      rotationAngle = 0;
      oyunBittiMi = false;
      oyunDurdurulduMu = false;
      komboEfektleri.clear();
      
      // Can sistemini sıfırla
      can = maksCan;
      canKorumaAktif = false;
      canKorumaSuresi = 0;
      
      // Güç sistemlerini sıfırla
      yavaslatmaAktif = false;
      yavaslatmaSuresi = 0;
      cokluPuanAktif = false;
      cokluPuanSuresi = 0;
      
      // Renk sistemini sıfırla
      aktifRenkler = anaRenkler.take(3).toList();
      _sonCubukIndeksi = -1;
    });
    _yeniCubukOlustur();
    _motoruBaslat();
  }

  void _enYuksekSkoruKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('enYuksekSkor', enYuksekSkor);
  }

  void _skoruKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> skorlar = prefs.getStringList('skorlar') ?? [];
    skorlar.add(skor.toString());
    await prefs.setStringList('skorlar', skorlar);
  }

  void _komboEfektiEkle(int komboSayisi) {
    final efekt = Positioned(
      top: 150 + (komboEfektleri.length * 30),
      left: 0,
      right: 0,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 1.0 + value * 0.5,
              child: Opacity(
                opacity: 1.0 - value,
                child: Text(
                  "+${10 + (komboSayisi >= 5 ? 5 : 0)}",
                  style: TextStyle(
                    color: komboSayisi >= 10 ? Colors.amber : 
                           komboSayisi >= 5 ? Colors.orange : Colors.green,
                    fontSize: 20 + value * 10,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: komboSayisi >= 10 ? Colors.amber : 
                               komboSayisi >= 5 ? Colors.orange : Colors.green,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    
    setState(() {
      komboEfektleri.add(efekt);
    });
    
    // Efekti 1 saniye sonra kaldır
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && komboEfektleri.isNotEmpty) {
        setState(() {
          komboEfektleri.removeAt(0);
        });
      }
    });
  }
  
  void _seviyeGecisEfekti() {
    // Seviye geçiş animasyonu
    HapticFeedback.heavyImpact();
  }
  
  void _gucSistemleriniGuncelle() {
    // Can koruma süresini azalt
    if (canKorumaAktif && canKorumaSuresi > 0) {
      canKorumaSuresi--;
      if (canKorumaSuresi == 0) {
        canKorumaAktif = false;
      }
    }
    
    // Yavaşlatma süresini azalt
    if (yavaslatmaAktif && yavaslatmaSuresi > 0) {
      yavaslatmaSuresi--;
      if (yavaslatmaSuresi == 0) {
        yavaslatmaAktif = false;
      }
    }
    
    // Çoklu puan süresini azalt
    if (cokluPuanAktif && cokluPuanSuresi > 0) {
      cokluPuanSuresi--;
      if (cokluPuanSuresi == 0) {
        cokluPuanAktif = false;
      }
    }
  }
  
  void _rastgeleGucVer() {
    final random = math.Random();
    final gucTuru = random.nextInt(3);
    
    setState(() {
      switch (gucTuru) {
        case 0: // Can koruma
          canKorumaAktif = true;
          canKorumaSuresi = 5;
          break;
        case 1: // Yavaşlatma
          yavaslatmaAktif = true;
          yavaslatmaSuresi = 8;
          break;
        case 2: // Çoklu puan
          cokluPuanAktif = true;
          cokluPuanSuresi = 10;
          break;
      }
    });
    
    HapticFeedback.lightImpact();
  }

  void _oyunuDuraklat() {
    setState(() {
      oyunDurdurulduMu = !oyunDurdurulduMu;
    });
    if (!oyunDurdurulduMu) {
      _motoruBaslat();
    }
  }

  @override
  void dispose() {
    _oyunDongusu?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            // Tek yön: herhangi bir ok/space = ilerlet
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.space) {
              _dondur(true);
            }
          }
        }
      },
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final oyunGenislik = constraints.maxWidth;
            final oyunYukseklik = constraints.maxHeight;
            final aspectRatio = oyunGenislik / oyunYukseklik;
            
            // Boyutları ayarla
            _boyutlariAyarla(oyunGenislik, oyunYukseklik);
            
            // Mobil cihazlar için daha iyi aspect ratio
            final targetAspectRatio = mobilCihazMi 
              ? (aspectRatio > 0.6 ? 9 / 16 : 2 / 3)
              : (aspectRatio > 0.75 ? 9 / 16 : 3 / 4);

            // PC'de (geniş ekranda) taşmayı engelle: yüksekliği clamp'le
            final double desiredHeight = oyunGenislik / targetAspectRatio;
            final double height = math.min(desiredHeight, oyunYukseklik);
            final double width = height * targetAspectRatio;
            
            return SizedBox(
              width: width,
              height: height,
              child: GestureDetector(
                onTap: () => _dondur(true), // Mobil için dokunma kontrolü
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    border: Border.all(color: Colors.white10, width: 1),
                    borderRadius: BorderRadius.circular(mobilCihazMi ? 15 : 25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: mobilCihazMi ? 15 : 25,
                        spreadRadius: mobilCihazMi ? 5 : 10,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      _oyunAlaniniInsaEt(),
                      ...komboEfektleri,
                      _panelInsaEt(),
                      if (oyunDurdurulduMu) _pauseEkraniInsaEt(),
                      if (oyunBittiMi) _oyunBittiEkraniInsaEt(),
                      _pauseButonu(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _oyunAlaniniInsaEt() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Boyutları zaten build metodunda ayarladık, burada sadece kullanıyoruz
        final double ringCenterY = _oyunAlanYukseklik - _ringBottom - (_ringSize / 2);
        final double temasY = ringCenterY - (_ringSize / 2);
        final Color hedefRenk = aktifRenkler[_ustSegmentIndeksi()];
        final double centerX = _oyunAlanGenislik / 2;

        return GestureDetector(
          onTapDown: (detay) {
            // Tek yön modu: ekranın neresine basarsan bas sıradaki renk üste gelsin
            _dondur(true);
          },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // Yanlış vuruş flash efekti
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _yanlisVurusFlash ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 120),
                    child: Container(color: const Color(0xFFFF3131).withValues(alpha: 0.25)),
                  ),
                ),
              ),

              // Arka plan glow efekti
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: mukemmelVurusEfekti ? 420 : (vurusEfektiAktif ? 340 : 280),
                  height: mukemmelVurusEfekti ? 420 : (vurusEfektiAktif ? 340 : 280),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: mukemmelVurusEfekti 
                      ? RadialGradient(
                          colors: [
                            Colors.amber.withValues(alpha: 0.6), 
                            Colors.amber.withValues(alpha: 0.3),
                            Colors.amber.withValues(alpha: 0.1),
                            Colors.amber.withValues(alpha: 0.05)
                          ],
                        )
                      : RadialGradient(
                          colors: [
                            cubukRengi.withValues(alpha: 0.4), 
                            cubukRengi.withValues(alpha: 0.2),
                            cubukRengi.withValues(alpha: 0.1),
                            cubukRengi.withValues(alpha: 0.05)
                          ],
                        ),
                    boxShadow: [
                      BoxShadow(
                        color: mukemmelVurusEfekti ? Colors.amber.withValues(alpha: 0.7) : cubukRengi.withValues(alpha: 0.4),
                        blurRadius: mukemmelVurusEfekti ? 140 : 120, 
                        spreadRadius: mukemmelVurusEfekti ? 120 : (vurusEfektiAktif ? 100 : 50)
                      ),
                      // Kombo glow efektleri
                      if (kombo >= 10) 
                        BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 80, spreadRadius: 60),
                      if (kombo >= 20) 
                        BoxShadow(color: const Color(0xFFFF006E).withValues(alpha: 0.5), blurRadius: 90, spreadRadius: 70),
                      // Seviye glow efektleri
                      if (seviye >= 3)
                        BoxShadow(color: const Color(0xFF38BDF8).withValues(alpha: 0.4), blurRadius: 70, spreadRadius: 50),
                      if (seviye >= 5)
                        BoxShadow(color: const Color(0xFF00F5FF).withValues(alpha: 0.4), blurRadius: 75, spreadRadius: 55),
                      if (seviye >= 7)
                        BoxShadow(color: const Color(0xFF00FF41).withValues(alpha: 0.4), blurRadius: 80, spreadRadius: 60),
                      if (seviye >= 8)
                        BoxShadow(color: const Color(0xFFFFBE0B).withValues(alpha: 0.4), blurRadius: 85, spreadRadius: 65),
                    ],
                  ),
                ),
              ),
              
              // Yıldız parçacık efektleri
              if (vurusEfektiAktif || mukemmelVurusEfekti)
                ...List.generate(20, (index) => Positioned(
                  top: 150 + (index * 25),
                  left: 0,
                  right: 0,
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 1200 + (index * 25)),
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: value * math.pi * 2,
                          child: Transform.scale(
                            scale: 1.0 + value * 1.0,
                            child: Opacity(
                              opacity: (1.0 - value) * 0.9,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: mukemmelVurusEfekti ? Colors.amber : cubukRengi,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: mukemmelVurusEfekti ? Colors.amber : cubukRengi,
                                      blurRadius: 20,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )),

              // Hedef nokta işaretçisi
              Positioned(
                top: (temasY - 10).clamp(0.0, _oyunAlanYukseklik),
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: (_ringSize * 0.28).clamp(40.0, 90.0),
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        colors: [
                          hedefRenk.withValues(alpha: 0.0),
                          hedefRenk.withValues(alpha: 0.8),
                          hedefRenk.withValues(alpha: 0.0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: hedefRenk.withValues(alpha: 0.6),
                          blurRadius: 16,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                  ),
                ),
              ),

              // Doğru vuruş patlama parçacıkları
              ..._patlamaParcaciklari(centerX: centerX, centerY: temasY, renk: hedefRenk),
              
              // Mükemmel vuruş göstergesi
              if (mukemmelVurusEfekti)
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 1.0 + value * 0.8,
                          child: Text(
                            "👑 ULTRA MÜKEMMEL! 👑",
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 40 + value * 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                              shadows: [
                                Shadow(color: Colors.amber, blurRadius: 60),
                                Shadow(color: Colors.amber.withValues(alpha: 0.7), blurRadius: 100),
                                Shadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 120),
                                Shadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 140),
                                Shadow(color: Colors.amber.withValues(alpha: 0.1), blurRadius: 160),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              
              // Düşen çubuk
              Align(
                alignment: Alignment(0, cubukPozisyonu),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: mukemmelVurusEfekti ? (_barWidthPx * 1.25) : _barWidthPx,
                  height: mukemmelVurusEfekti ? (_barHeightPx * 1.1) : _barHeightPx,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        mukemmelVurusEfekti ? Colors.amber : cubukRengi,
                        mukemmelVurusEfekti ? Colors.amber.withValues(alpha: 0.8) : cubukRengi.withValues(alpha: 0.9),
                        mukemmelVurusEfekti ? Colors.amber.withValues(alpha: 0.5) : cubukRengi.withValues(alpha: 0.6),
                        mukemmelVurusEfekti ? Colors.amber.withValues(alpha: 0.3) : cubukRengi.withValues(alpha: 0.4),
                        mukemmelVurusEfekti ? Colors.amber.withValues(alpha: 0.1) : cubukRengi.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(mukemmelVurusEfekti ? 35 : 25),
                    boxShadow: [
                      BoxShadow(
                        color: mukemmelVurusEfekti ? Colors.amber.withValues(alpha: 1.0) : cubukRengi.withValues(alpha: 0.9),
                        blurRadius: mukemmelVurusEfekti ? 60 : 40,
                        spreadRadius: 25,
                      ),
                      // Kombo glow efektleri
                      if (kombo >= 5) BoxShadow(color: _komboRengi().withValues(alpha: 0.8), blurRadius: 30),
                      if (kombo >= 10) BoxShadow(color: Colors.amber.withValues(alpha: 0.8), blurRadius: 35),
                      if (kombo >= 15) BoxShadow(color: const Color(0xFF8338EC).withValues(alpha: 0.8), blurRadius: 40),
                      if (kombo >= 20) BoxShadow(color: const Color(0xFFFF006E).withValues(alpha: 0.8), blurRadius: 45),
                      // Seviye glow efektleri
                      if (seviye >= 2) BoxShadow(color: const Color(0xFF38BDF8).withValues(alpha: 0.5), blurRadius: 25),
                      if (seviye >= 4) BoxShadow(color: const Color(0xFF00F5FF).withValues(alpha: 0.5), blurRadius: 28),
                      if (seviye >= 6) BoxShadow(color: const Color(0xFF00FF41).withValues(alpha: 0.5), blurRadius: 30),
                      if (seviye >= 8) BoxShadow(color: const Color(0xFFFFBE0B).withValues(alpha: 0.5), blurRadius: 33),
                    ],
                  ),
                ),
              ),
              
              // Dönen şekil
              Positioned(
                bottom: _ringBottom, 
                left: 0, 
                right: 0,
                child: Center(
                  child: AnimatedRotation(
                    turns: rotationAngle / (2 * math.pi),
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOutCubic,
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(_pulseTick),
                      tween: Tween<double>(begin: 1.06, end: 1.0),
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: Column(
                        children: [
                          // Ana şekil
                          CustomPaint(
                            size: Size(_ringSize, _ringSize),
                            painter: OyunCizici(kenarSayisi: kenarSayisi, renkler: aktifRenkler),
                          ),
                          // İç dekorasyon katmanları
                          if (seviye >= 3)
                            Transform.scale(
                              scale: 0.8,
                              child: CustomPaint(
                                size: Size(_ringSize, _ringSize),
                                painter: OyunCizici(kenarSayisi: kenarSayisi, renkler: aktifRenkler, icDekorasyon: true),
                              ),
                            ),
                          if (seviye >= 5)
                            Transform.scale(
                              scale: 0.55,
                              child: CustomPaint(
                                size: Size(_ringSize, _ringSize),
                                painter: OyunCizici(kenarSayisi: kenarSayisi, renkler: aktifRenkler, icDekorasyon: true),
                              ),
                            ),
                          if (seviye >= 7)
                            Transform.scale(
                              scale: 0.3,
                              child: CustomPaint(
                                size: Size(_ringSize, _ringSize),
                                painter: OyunCizici(kenarSayisi: kenarSayisi, renkler: aktifRenkler, icDekorasyon: true),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Arka plan desenleri
              if (seviye >= 1)
                Positioned.fill(
                  child: CustomPaint(
                    painter: ArkaPlanDeseni(seviye: seviye),
                  ),
                ),
              
              // Yıldız desenleri
              if (seviye >= 4)
                Positioned.fill(
                  child: CustomPaint(
                    painter: YildizDeseni(seviye: seviye),
                  ),
                ),
            ],
          ),
        ),
      );
  }

  Widget _panelInsaEt() {
    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.all(mobilCihazMi ? 16 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Üst panel - skor ve güçler
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Skor ve seviye
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skor.toString(),
                      style: TextStyle(
                        fontSize: mobilCihazMi ? 36 : 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                        shadows: [
                          Shadow(color: cubukRengi.withValues(alpha: 0.6), blurRadius: 10),
                        ],
                      ),
                    ),
                    Text(
                      'Seviye $seviye',
                      style: TextStyle(
                        fontSize: mobilCihazMi ? 14 : 16,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                // Canlar
                Row(
                  children: List.generate(maksCan, (index) {
                    final bool canVar = index < can;
                    final bool korumaAktif = canKorumaAktif && index == can - 1;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: mobilCihazMi ? 24 : 28,
                        height: mobilCihazMi ? 24 : 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: canVar 
                            ? (korumaAktif ? Colors.amber : cubukRengi)
                            : Colors.white.withValues(alpha: 0.2),
                          border: korumaAktif 
                            ? Border.all(color: Colors.amber, width: 2)
                            : null,
                          boxShadow: canVar ? [
                            BoxShadow(
                              color: (korumaAktif ? Colors.amber : cubukRengi).withValues(alpha: 0.5),
                              blurRadius: 8,
                            )
                          ] : null,
                        ),
                        child: canVar 
                          ? Icon(
                              korumaAktif ? Icons.shield : Icons.favorite,
                              color: Colors.white,
                              size: mobilCihazMi ? 14 : 16,
                            )
                          : null,
                      ),
                    );
                  }),
                ),
              ],
            ),
            
            // Alt panel - güçler ve kombo
            Column(
              children: [
                // Aktif güçler
                if (yavaslatmaAktif || cokluPuanAktif || canKorumaAktif)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: mobilCihazMi ? 12 : 16,
                      vertical: mobilCihazMi ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (yavaslatmaAktif) ...[
                          Icon(Icons.hourglass_bottom, color: Colors.cyan, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$yavaslatmaSuresi',
                            style: TextStyle(color: Colors.cyan, fontSize: 12),
                          ),
                        ],
                        if (cokluPuanAktif) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '2x ($cokluPuanSuresi)',
                            style: TextStyle(color: Colors.amber, fontSize: 12),
                          ),
                        ],
                        if (canKorumaAktif) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.shield, color: Colors.purple, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Koruma ($canKorumaSuresi)',
                            style: TextStyle(color: Colors.purple, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                
                const SizedBox(height: 8),
                
                // Kombo
                if (kombo > 1)
                  Text(
                    'KOMBO x$kombo',
                    style: TextStyle(
                      fontSize: mobilCihazMi ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: _komboRengi(),
                      shadows: [
                        Shadow(color: _komboRengi().withValues(alpha: 0.6), blurRadius: 8),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Color _komboRengi() {
    if (kombo >= 20) return const Color(0xFFFF006E);
    if (kombo >= 15) return const Color(0xFF8338EC);
    if (kombo >= 10) return const Color(0xFFFFBE0B);
    if (kombo >= 5) return const Color(0xFF00F5FF);
    return const Color(0xFF00FF41);
  }

  Widget _pauseButonu() {
    return Positioned(
      top: 50,
      right: 25,
      child: GestureDetector(
        onTap: _oyunuDuraklat,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Icon(
            oyunDurdurulduMu ? Icons.play_arrow : Icons.pause,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _pauseEkraniInsaEt() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pause_circle_filled, color: Color(0xFF38BDF8), size: 80),
          const SizedBox(height: 20),
          const Text("OYUN DURAKLATILDI", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Devam etmek için tıkla", style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPauseButton("DEVAM ET", const Color(0xFF00FF41), _oyunuDuraklat),
              _buildPauseButton("ANA MENÜ", const Color(0xFFFF006E), () => Navigator.pop(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPauseButton(String text, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 15)],
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14),
        ),
      ),
    );
  }

  Widget _oyunBittiEkraniInsaEt() {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("OYUN BİTTİ", style: TextStyle(color: Color(0xFFFF006E), fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 5)),
          const SizedBox(height: 15),
          Text("SKORUN: $skor", style: const TextStyle(color: Colors.white, fontSize: 24)),
          Text("REKORUN: $enYuksekSkor", style: const TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 50),
          GestureDetector(
            onTap: _oyunuSifirlaVeBaslat,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF41),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [BoxShadow(color: const Color(0xFF00FF41).withValues(alpha: 0.3), blurRadius: 20)],
              ),
              child: const Text("TEKRAR DENE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class OyunCizici extends CustomPainter {
  final int kenarSayisi;
  final List<Color> renkler;
  final bool icDekorasyon;
  
  // Cache için boyaları önceden oluştur
  late final List<Paint> _cachedPaints;
  late Rect _cachedRect;
  
  OyunCizici({required this.kenarSayisi, required this.renkler, this.icDekorasyon = false}) {
    _cachedPaints = List.generate(8, (i) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = icDekorasyon ? 10 : 20
      ..strokeCap = StrokeCap.butt);
    _cachedRect = Rect.zero;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final merkez = Offset(size.width / 2, size.height / 2);
    final aci = 2 * math.pi / kenarSayisi;

    // Segmentlerin "düz" görünmesi için daha küçük gap
    final double gap = icDekorasyon ? 0.06 : 0.08;

    final double strokeW = _cachedPaints[0].strokeWidth;
    final double radius = (math.min(size.width, size.height) / 2) - (strokeW / 2);
    _cachedRect = Rect.fromCircle(center: merkez, radius: radius);

    for (int i = 0; i < kenarSayisi; i++) {
      _cachedPaints[i].color = renkler[i];
      
      canvas.drawArc(
        _cachedRect,
        (i * aci - (math.pi / 2)) - (aci / 2) + gap,
        aci - (2 * gap),
        false,
        _cachedPaints[i],
      );
    }
  }

  @override
  bool shouldRepaint(OyunCizici oldDelegate) => 
      oldDelegate.kenarSayisi != kenarSayisi || 
      oldDelegate.icDekorasyon != icDekorasyon ||
      !listEquals(oldDelegate.renkler, renkler);
}

class ArkaPlanDeseni extends CustomPainter {
  final int seviye;
  
  ArkaPlanDeseni({required this.seviye});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    final merkez = Offset(size.width / 2, size.height / 2);
    
    // Seviye bazlı desenler
    for (int i = 0; i < seviye; i++) {
      final radius = 70.0 + (i * 40);
      canvas.drawCircle(merkez, radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(ArkaPlanDeseni oldDelegate) => oldDelegate.seviye != seviye;
}

class YildizDeseni extends CustomPainter {
  final int seviye;
  
  YildizDeseni({required this.seviye});
  
  @override
  void paint(Canvas canvas, Size size) {
    final merkez = Offset(size.width / 2, size.height / 2);
    
    // Ultra Yıldız desenleri
    for (int i = 0; i < seviye - 3; i++) {
      final yildizSayisi = 8 + (i * 4);
      final radius = 120.0 + (i * 50);
      
      for (int j = 0; j < yildizSayisi; j++) {
        final aci = (j * 2 * math.pi / yildizSayisi) - (math.pi / 2);
        final x = merkez.dx + radius * math.cos(aci);
        final y = merkez.dy + radius * math.sin(aci);
        
        // Ultra Yıldız çiz
        final yildizPaint = Paint()
          ..color = const Color(0xFF38BDF8).withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        
        canvas.drawCircle(Offset(x, y), 10, yildizPaint);
        
        // Ultra Işık huzmesi
        final isikPaint = Paint()
          ..color = const Color(0xFF38BDF8).withValues(alpha: 0.1)
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(Offset(x, y), 6, isikPaint);
        
        // Parıldayan efekt
        final parlakPaint = Paint()
          ..color = const Color(0xFF38BDF8).withValues(alpha: 0.06)
          ..style = PaintingStyle.fill;
        
        canvas.drawCircle(Offset(x, y), 15, parlakPaint);
      }
    }
  }
  
  @override
  bool shouldRepaint(YildizDeseni oldDelegate) => oldDelegate.seviye != seviye;
}
