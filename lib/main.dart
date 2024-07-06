import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather App',
      theme: ThemeData(
        primaryColor: const Color(0xFF03045E),
        scaffoldBackgroundColor: const Color(0xFFF0F8FF),
        textTheme: const TextTheme(
          headline5: TextStyle(color: Color(0xFF03045E), fontSize: 24),
          bodyText2: TextStyle(color: Color(0xFF023E8A)),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          labelStyle: TextStyle(color: Color(0xFF03045E)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: const Color(0xFF0077B6),
            onPrimary: Colors.white,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF03045E),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
          iconTheme: IconThemeData(color: Colors.white), // Ensures the back and refresh buttons are white
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  String _cityName = '';
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _searchWeather(String cityName) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final apiKey = 'd93cc2d2b65d4a8a919142734240407'; // Replace with your actual API key
    final apiUrl =
        'http://api.weatherapi.com/v1/current.json?key=$apiKey&q=$cityName';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _saveCity(cityName); // Save last searched city
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WeatherDetailsScreen(data: data),
          ),
        );
        setState(() {
          _cityName = cityName;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'City not found. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch weather data. Please try again.';
      });
    }
  }

  Future<void> _saveCity(String cityName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastCity', cityName);
  }

  Future<String?> _getLastCity() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastCity');
  }

  @override
  void initState() {
    super.initState();
    _getLastCity().then((value) {
      if (value != null && value.isNotEmpty) {
        _searchWeather(value); // Fetch weather for last searched city on app start
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Enter city name',
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchWeather(_controller.text.trim());
              },
              child: _isLoading
                  ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
                  : const Text('Search'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class WeatherDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const WeatherDetailsScreen({Key? key, required this.data}) : super(key: key);

  @override
  _WeatherDetailsScreenState createState() => _WeatherDetailsScreenState();
}

class _WeatherDetailsScreenState extends State<WeatherDetailsScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  late Map<String, dynamic> _data;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
  }

  Future<void> _refreshWeather(String cityName) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final apiKey = 'd93cc2d2b65d4a8a919142734240407'; // Replace with your actual API key
    final apiUrl =
        'http://api.weatherapi.com/v1/current.json?key=$apiKey&q=$cityName';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _data = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'City not found. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch weather data. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Weather Details'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final weather = _data['current']['condition'];
    final main = _data['current'];
    final wind = _data['current']['wind_kph'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _refreshWeather(_data['location']['name']);
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const CircularProgressIndicator()
                : Container(
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'City: ${_data['location']['name']}',
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  const SizedBox(height: 8),
                  Text('Temperature: ${main['temp_c']}°C',
                      style: const TextStyle(fontSize: 18)),
                  Text('Condition: ${weather['text']}',
                      style: const TextStyle(fontSize: 18)),
                  Center(
                    child: Image.network(
                      'https:${weather['icon']}',
                      scale: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Humidity: ${main['humidity']}%',
                      style: const TextStyle(fontSize: 18)),
                  Text('Wind Speed: $wind km/h',
                      style: const TextStyle(fontSize: 18)),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
