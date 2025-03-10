import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:weather/additional_item.dart';
import 'package:weather/hourly_forecast_item.dart';
import 'package:http/http.dart' as http;
import 'we_key.dart';
import 'package:weather/additional_info_screen.dart';
import 'package:provider/provider.dart';
import 'package:weather/weather_provider.dart';
import 'package:weather/theme_provider.dart';
import 'package:weather/seven_day_forecast.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  int _selectedIndex = 0;
  String _cityName = "Bhubaneswar";

  static final List<Widget> _pages = <Widget>[
    WeatherHomePage(),
    AdditionalInfoScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _searchCity(String cityName) {
    setState(() {
      _cityName = cityName;
    });
    Provider.of<WeatherProvider>(context, listen: false).fetchWeather(cityName);
  }

  @override
  void initState() {
    super.initState();
    Provider.of<WeatherProvider>(context, listen: false)
        .fetchWeather(_cityName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          '$_cityName',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Provider.of<WeatherProvider>(context, listen: false)
                  .fetchWeather(_cityName);
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
            icon: const Icon(Icons.brightness_6),
          ),
          IconButton(
            onPressed: () async {
              final cityName = await showDialog<String>(
                context: context,
                builder: (context) => _CitySearchDialog(),
              );
              if (cityName != null) {
                _searchCity(cityName);
              }
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'Additional Info',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _CitySearchDialog extends StatefulWidget {
  @override
  _CitySearchDialogState createState() => _CitySearchDialogState();
}

class _CitySearchDialogState extends State<_CitySearchDialog> {
  final TextEditingController _controller = TextEditingController();
  List<String> _suggestions = [];

  Future<void> _fetchCitySuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    final response = await http.get(Uri.parse(
        'http://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=$openweatherApiKey'));

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      setState(() {
        _suggestions =
            data.map<String>((city) => city['name'] as String).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search City'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            onChanged: _fetchCitySuggestions,
            decoration: const InputDecoration(hintText: 'Enter city name'),
          ),
          SizedBox(height: 8),
          ..._suggestions.map((city) => ListTile(
                title: Text(city),
                onTap: () => Navigator.of(context).pop(city),
              ))
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Search'),
        ),
      ],
    );
  }
}

class WeatherHomePage extends StatelessWidget {
  String formatHour(String dateTime) {
    final DateTime parsedDate = DateTime.parse(dateTime);
    return "${parsedDate.hour % 12 == 0 ? 12 : parsedDate.hour % 12} ${parsedDate.hour >= 12 ? 'PM' : 'AM'}";
  }

  String formatDay(String dateTime) {
    final DateTime parsedDate = DateTime.parse(dateTime);
    const List<String> days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[parsedDate.weekday - 1];
  }

  String formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        if (weatherProvider.isLoading) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (weatherProvider.errorMessage.isNotEmpty) {
          return Text(weatherProvider.errorMessage);
        }

        final data = weatherProvider.weatherData!;
        final currentData = data['list'][0];
        final currentTempCelsius =
            (currentData['main']['temp'] - 273.15).toStringAsFixed(1);
        final currentSky = currentData['weather'][0]['main'];
        final todayDate = formatDate(DateTime.now());

        return Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // main card
              SizedBox(
                width: double.infinity,
                child: Card(
                  elevation: 15,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            "$currentTempCelsius °C",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          Text(
                            todayDate,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          Icon(
                            currentSky == "Clouds" || currentSky == "Rain"
                                ? Icons.cloud
                                : Icons.sunny,
                            size: 60,
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          Text(
                            currentSky,
                            style: const TextStyle(fontSize: 20),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // weather cards daily/hourly
              const SizedBox(height: 20),
              const Text(
                "Hourly Forecast",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    if (index + 1 >= data['list'].length) return Container();
                    final hourlyForecast = data['list'][index + 1];
                    final hourlyIcon = hourlyForecast['weather'][0]['main'];
                    final hourlyTime = formatHour(hourlyForecast['dt_txt']);
                    return HourlyForecast(
                      time: hourlyTime,
                      temp: (hourlyForecast['main']['temp'] - 273.15)
                          .toStringAsFixed(1),
                      icon: hourlyIcon == "Clouds" || hourlyIcon == "Rain"
                          ? Icons.cloud
                          : Icons.sunny,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const SevenDayForecast(),
            ],
          ),
        );
      },
    );
  }
}
