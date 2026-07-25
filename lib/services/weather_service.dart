import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class PlantWeatherInfo {
  final double temperature;
  final int humidity;
  final double uvIndex;
  final String condition;
  final String description;
  final bool isFrostWarning;
  final String outdoorAdvice;

  PlantWeatherInfo({
    required this.temperature,
    required this.humidity,
    required this.uvIndex,
    required this.condition,
    required this.description,
    required this.isFrostWarning,
    required this.outdoorAdvice,
  });

  factory PlantWeatherInfo.mock() {
    final now = DateTime.now();
    final isNight = now.hour < 6 || now.hour > 18;
    return PlantWeatherInfo(
      temperature: 24.5,
      humidity: 62,
      uvIndex: isNight ? 0.0 : 5.8,
      condition: isNight ? 'Clear Night' : 'Sunny',
      description: isNight ? 'Cool evening air' : 'Clear skies, perfect for growth',
      isFrostWarning: false,
      outdoorAdvice: 'Weather is optimal. Ensure outdoor plants are watered in the morning.',
    );
  }
}

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  static const String _openWeatherApiKey = String.fromEnvironment('OPEN_WEATHER_API_KEY', defaultValue: '');

  /// Fetches real-time weather. Tries OpenWeather API first, falls back to Open-Meteo.
  Future<PlantWeatherInfo> getWeather() async {
    final client = HttpClient();
    try {
      // Default coordinates: Lahore, Pakistan (Lat: 31.52, Lon: 74.36)
      final uri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=31.52&lon=74.36&appid=$_openWeatherApiKey&units=metric'
      );
      
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 4));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = json.decode(responseBody);
        
        if (data.containsKey('main') && data.containsKey('weather')) {
          final main = data['main'];
          final double temp = (main['temp'] as num).toDouble();
          final int humidity = (main['humidity'] as num).toInt();
          
          final weatherList = data['weather'] as List;
          final weather = weatherList.isNotEmpty 
              ? weatherList[0] as Map<String, dynamic>
              : {'main': 'Sunny', 'description': 'clear sky', 'icon': '01d'};
              
          final String openWeatherCond = weather['main'] ?? 'Sunny';
          final String desc = weather['description'] ?? 'Clear sky';
          final String icon = weather['icon'] ?? '01d';
          final bool isDay = icon.contains('d');
          
          final String condition = _mapOpenWeatherCondition(openWeatherCond, isDay);
          
          // Determine UV Index roughly based on time of day and weather condition
          double uv = 0.0;
          if (isDay) {
            final hour = DateTime.now().hour;
            final double baseUv = (12 - (hour - 13).abs()).clamp(1.0, 9.0).toDouble();
            if (condition.toLowerCase().contains('cloudy') || condition.toLowerCase().contains('rain') || condition.toLowerCase().contains('thunderstorm')) {
              uv = baseUv * 0.4;
            } else {
              uv = baseUv;
            }
          }
          
          final bool isFrost = temp <= 5.0;
          String advice = 'Weather is optimal for outdoor plants.';
          if (isFrost) {
            advice = '⚠️ Frost Warning! Bring outdoor plants inside immediately.';
          } else if (temp >= 35.0) {
            advice = '⚠️ Extreme Heat! Water container plants twice daily and shade them.';
          } else if (condition.toLowerCase().contains('rain')) {
            advice = '🌧️ Raining. Skip watering today to avoid root rot.';
          } else if (humidity < 35 && temp > 25) {
            advice = '🍂 Low humidity & warmth. Mist tropical houseplants.';
          } else if (uv > 7.0) {
            advice = '☀️ High UV Index. Protect sun-sensitive plants with shade.';
          }
          
          return PlantWeatherInfo(
            temperature: temp,
            humidity: humidity,
            uvIndex: double.parse(uv.toStringAsFixed(1)),
            condition: condition,
            description: desc,
            isFrostWarning: isFrost,
            outdoorAdvice: advice,
          );
        }
      }
      debugPrint("⚠️ OpenWeather returned status ${response.statusCode}. Falling back to Open-Meteo.");
    } catch (e) {
      debugPrint("⚠️ OpenWeather fetch failed: $e. Falling back to Open-Meteo.");
    } finally {
      client.close();
    }
    
    // Fallback to Open-Meteo
    return _fetchFallbackWeather();
  }

  String _mapOpenWeatherCondition(String openWeatherCond, bool isDay) {
    switch (openWeatherCond) {
      case 'Clear':
        return isDay ? 'Sunny' : 'Clear Night';
      case 'Clouds':
        return 'Cloudy';
      case 'Rain':
      case 'Drizzle':
        return 'Rainy';
      case 'Snow':
        return 'Snowy';
      case 'Thunderstorm':
        return 'Thunderstorm';
      case 'Mist':
      case 'Smoke':
      case 'Haze':
      case 'Dust':
      case 'Fog':
      case 'Sand':
      case 'Ash':
      case 'Squall':
        return 'Foggy';
      default:
        return openWeatherCond;
    }
  }

  /// Fallback: Fetches weather from Open-Meteo (no API key needed)
  Future<PlantWeatherInfo> _fetchFallbackWeather() async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=31.52&longitude=74.36&current=temperature_2m,relative_humidity_2m,weather_code,is_day&timezone=auto'
      );
      
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 5));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = json.decode(responseBody);
        
        if (data.containsKey('current')) {
          final current = data['current'];
          final double temp = (current['temperature_2m'] as num).toDouble();
          final int humidity = (current['relative_humidity_2m'] as num).toInt();
          final int code = (current['weather_code'] as num).toInt();
          final int isDay = (current['is_day'] as num).toInt();
          
          final conditionMap = _mapWeatherCode(code, isDay == 1);
          final String condition = conditionMap['condition']!;
          final String desc = conditionMap['description']!;
          
          double uv = 0.0;
          if (isDay == 1) {
            final hour = DateTime.now().hour;
            final double baseUv = (12 - (hour - 13).abs()).clamp(1.0, 9.0).toDouble();
            if (condition.toLowerCase().contains('cloudy') || condition.toLowerCase().contains('rain')) {
              uv = baseUv * 0.4;
            } else {
              uv = baseUv;
            }
          }
          
          final bool isFrost = temp <= 5.0;
          String advice = 'Weather is optimal for outdoor plants.';
          if (isFrost) {
            advice = '⚠️ Frost Warning! Bring outdoor plants inside immediately.';
          } else if (temp >= 35.0) {
            advice = '⚠️ Extreme Heat! Water container plants twice daily and shade them.';
          } else if (condition.toLowerCase().contains('rain')) {
            advice = '🌧️ Raining. Skip watering today to avoid root rot.';
          } else if (humidity < 35 && temp > 25) {
            advice = '🍂 Low humidity & warmth. Mist tropical houseplants.';
          } else if (uv > 7.0) {
            advice = '☀️ High UV Index. Protect sun-sensitive plants with shade.';
          }
          
          return PlantWeatherInfo(
            temperature: temp,
            humidity: humidity,
            uvIndex: double.parse(uv.toStringAsFixed(1)),
            condition: condition,
            description: desc,
            isFrostWarning: isFrost,
            outdoorAdvice: advice,
          );
        }
      }
      return PlantWeatherInfo.mock();
    } catch (e) {
      debugPrint("⚠️ Open-Meteo fallback fetch failed: $e. Returning mock weather.");
      return PlantWeatherInfo.mock();
    } finally {
      client.close();
    }
  }

  Map<String, String> _mapWeatherCode(int code, bool isDay) {
    if (code == 0) {
      return {
        'condition': isDay ? 'Sunny' : 'Clear Night',
        'description': isDay ? 'Clear sky' : 'Clear night sky',
      };
    } else if (code >= 1 && code <= 3) {
      return {
        'condition': 'Partly Cloudy',
        'description': 'Mainly clear, partly cloudy',
      };
    } else if (code >= 45 && code <= 48) {
      return {
        'condition': 'Foggy',
        'description': 'Fog and depositing rime fog',
      };
    } else if (code >= 51 && code <= 55) {
      return {
        'condition': 'Drizzle',
        'description': 'Light, moderate, and dense intensity drizzle',
      };
    } else if (code >= 61 && code <= 65) {
      return {
        'condition': 'Rainy',
        'description': 'Slight, moderate and heavy intensity rain',
      };
    } else if (code >= 71 && code <= 77) {
      return {
        'condition': 'Snowy',
        'description': 'Slight, moderate, and heavy snow fall',
      };
    } else if (code >= 80 && code <= 82) {
      return {
        'condition': 'Rain Showers',
        'description': 'Slight, moderate, and violent rain showers',
      };
    } else if (code >= 95 && code <= 99) {
      return {
        'condition': 'Thunderstorm',
        'description': 'Thunderstorm with slight and heavy hail',
      };
    }
    return {
      'condition': 'Unknown',
      'description': 'Weather conditions uncertain',
    };
  }
}
