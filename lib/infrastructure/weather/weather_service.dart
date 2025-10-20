// lib/infrastructure/weather/weather_service.dart
// Comentario (ES): Servicio sencillo contra OpenWeather para obtener clima actual.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/env.dart';

class WeatherNow {
  final double temperatureC;
  final double feelsLikeC;
  final int conditionCode;
  final bool isDay;
  final DateTime timestamp;
  final String description;

  const WeatherNow({
    required this.temperatureC,
    required this.feelsLikeC,
    required this.conditionCode,
    required this.isDay,
    required this.timestamp,
    required this.description,
  });

  double get displayTemperatureC => feelsLikeC;

  String get label => _labelFromCode(conditionCode);

  static String _labelFromCode(int code) {
    // Comentario (ES): Grupos de codigos de OpenWeather simplificados.
    if (code >= 200 && code < 300) return 'Thunderstorm';
    if (code >= 300 && code < 400) return 'Drizzle';
    if (code >= 500 && code < 600) return 'Rain';
    if (code >= 600 && code < 700) return 'Snow';
    if (code >= 700 && code < 800) return 'Fog';
    if (code == 800) return 'Sunny';
    if (code == 801) return 'Partly cloudy';
    if (code == 802) return 'Cloudy';
    if (code == 803) return 'Mostly cloudy';
    if (code == 804) return 'Overcast';
    return 'Weather';
  }
}

class WeatherService {
  final http.Client _client;

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  Future<WeatherNow> fetchNow({
    double? lat,
    double? lon,
  }) async {
    final latitude = lat ?? Env.weatherLatitude;
    final longitude = lon ?? Env.weatherLongitude;
    final apiKey = Env.openWeatherApiKey;

    if (apiKey.isEmpty) {
      throw StateError('Falta Env.openWeatherApiKey (OpenWeather API key).');
    }

    final uri = Uri.https(
      'api.openweathermap.org',
      '/data/2.5/weather',
      <String, String>{
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'appid': apiKey,
        'units': 'metric',
        'lang': 'en',
      },
    );

    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Weather HTTP ${res.statusCode}: ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final main = (json['main'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final List<dynamic> weatherArr = (json['weather'] as List<dynamic>?) ?? const [];
    final weather = weatherArr.isNotEmpty ? weatherArr.first as Map<String, dynamic> : <String, dynamic>{};
    final icon = weather['icon'] as String? ?? '';
    final description = (weather['description'] as String? ?? '').trim();
    final code = (weather['id'] as num?)?.toInt() ?? 0;
    final isDay = icon.contains('d');
    final dt = (json['dt'] as num?)?.toInt();
    final timestamp = dt != null
        ? DateTime.fromMillisecondsSinceEpoch(dt * 1000, isUtc: true).toLocal()
        : DateTime.now();

    return WeatherNow(
      temperatureC: (main['temp'] as num?)?.toDouble() ?? 0,
      feelsLikeC: (main['feels_like'] as num?)?.toDouble() ?? (main['temp'] as num?)?.toDouble() ?? 0,
      conditionCode: code,
      isDay: isDay,
      timestamp: timestamp,
      description: description,
    );
  }
}
