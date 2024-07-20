import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/////////////////////////////////////////////////////////////// Model Classes
class Surah {
  final int number;
  final String name;
  final List<Ayah> ayahs;

  Surah({required this.number, required this.name, required this.ayahs});

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'],
      name: json['englishName'],
      ayahs: (json['ayahs'] as List).map((ayah) => Ayah.fromJson(ayah)).toList(),
    );
  }
}

class Ayah {
  final int number;
  final String text;

  Ayah({required this.number, required this.text});

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      number: json['numberInSurah'],
      text: json['text'],
    );
  }
}

///////////////////////////////////////////////////////State Management Provider
class QuranProvider with ChangeNotifier {
  List<Surah> _surahs = [];
  List<Ayah> _ayahs = [];
  int _selectedSurah = 1;
  int _currentPage = 0;
  int _ayahsPerPage = 8;

  List<Surah> get surahs => _surahs;
  List<Ayah> get ayahs => _ayahs;
  int get selectedSurah => _selectedSurah;
  int get currentPage => _currentPage;
  int get ayahsPerPage => _ayahsPerPage;

  QuranProvider() {
    fetchSurahs();
  }

  Future<void> fetchSurahs() async {
    final response = await http.get(Uri.parse('https://api.alquran.cloud/v1/quran/ur.jhaladhry'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> surahList = data['data']['surahs'];
      _surahs = surahList.map((json) => Surah.fromJson(json)).toList();
      _ayahs = _surahs[_selectedSurah - 1].ayahs;
      notifyListeners();
    } else {
      throw Exception('Failed to load Surahs');
    }
  }

  void selectSurah(int surahNumber) {
    _selectedSurah = surahNumber;
    _currentPage = 0;
    _ayahs = _surahs[_selectedSurah - 1].ayahs;
    notifyListeners();
  }

  void nextAyahs() {
    if ((_currentPage + 1) * _ayahsPerPage < _ayahs.length) {
      _currentPage++;
    } else if (_selectedSurah < _surahs.length) {
      _selectedSurah++;
      _currentPage = 0;
      if (_selectedSurah <= _surahs.length) {
        _ayahs = _surahs[_selectedSurah - 1].ayahs;
      }
    }
    notifyListeners();
  }
}

/////////////////////////////////////////////////////////////////////// Main App
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QuranProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Reader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SurahPage(),
    );
  }
}

class SurahPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quran Reader'),
      ),
      body: Consumer<QuranProvider>(
        builder: (context, quranProvider, child) {
          final start = quranProvider.currentPage * quranProvider.ayahsPerPage;
          final end = (start + quranProvider.ayahsPerPage > quranProvider.ayahs.length)
              ? quranProvider.ayahs.length
              : start + quranProvider.ayahsPerPage;
          final ayahsToShow = (quranProvider.ayahs.length > 0)
              ? quranProvider.ayahs.sublist(start, end)
              : [];

          return Column(
            children: [
              DropdownButton<int>(
                value: quranProvider.selectedSurah,
                items: quranProvider.surahs.map((Surah surah) {
                  return DropdownMenuItem<int>(
                    value: surah.number,
                    child: Text(surah.name),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  quranProvider.selectSurah(newValue!);
                },
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: ayahsToShow.length,
                  itemBuilder: (context, index) {
                    final ayah = ayahsToShow[index];
                    return ListTile(
                      title: Text('${ayah.number}: ${ayah.text}'),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: quranProvider.nextAyahs,
                    child: Text('Next'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
