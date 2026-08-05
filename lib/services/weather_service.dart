import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlantWeatherInfo {
  final double temperature;
  final int humidity;
  final double uvIndex;
  final String condition;
  final String description;
  final bool isFrostWarning;
  final String outdoorAdvice;
  final String locationName;

  PlantWeatherInfo({
    required this.temperature,
    required this.humidity,
    required this.uvIndex,
    required this.condition,
    required this.description,
    required this.isFrostWarning,
    required this.outdoorAdvice,
    this.locationName = 'Sangota, Swat, PK',
  });

  Map<String, dynamic> toJson() => {
        'temperature': temperature,
        'humidity': humidity,
        'uvIndex': uvIndex,
        'condition': condition,
        'description': description,
        'isFrostWarning': isFrostWarning,
        'outdoorAdvice': outdoorAdvice,
        'locationName': locationName,
      };

  factory PlantWeatherInfo.fromJson(Map<String, dynamic> json) => PlantWeatherInfo(
        temperature: (json['temperature'] as num).toDouble(),
        humidity: (json['humidity'] as num).toInt(),
        uvIndex: (json['uvIndex'] as num).toDouble(),
        condition: json['condition'] ?? 'Sunny',
        description: json['description'] ?? 'Optimal growing conditions',
        isFrostWarning: json['isFrostWarning'] ?? false,
        outdoorAdvice: json['outdoorAdvice'] ?? 'Weather is optimal for outdoor plants.',
        locationName: json['locationName'] ?? 'Sangota, Swat, PK',
      );

  factory PlantWeatherInfo.mock({String location = 'Sangota, Swat, PK'}) {
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
      locationName: location,
    );
  }
}

class UserLocationData {
  final double latitude;
  final double longitude;
  final String locationName;

  UserLocationData({
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });
}

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  static const String _openWeatherApiKey = String.fromEnvironment('OPEN_WEATHER_API_KEY', defaultValue: '0b5d11d8aa2fb213fdf6959519484e99');

  /// Fetches real-time weather based dynamically on the user's selected or detected physical location.
  Future<PlantWeatherInfo> getWeather() async {
    // 1. Resolve user location
    final location = await _fetchUserLocation();
    
    PlantWeatherInfo? weather;

    // 2. If OpenWeather API key is provided, attempt OpenWeather with user coordinates
    if (_openWeatherApiKey.isNotEmpty) {
      weather = await _fetchOpenWeather(location);
    }

    // 3. Primary/Fallback: Fetch from Open-Meteo with user exact coordinates (Free, Instant, Global)
    weather ??= await _fetchOpenMeteoWeather(location);

    // 4. Save clean weather data to local cache for offline availability
    if (weather != null) {
      await _cacheWeatherInfo(weather);
      return weather;
    }

    // 5. If network is unreachable, return last cached weather or mock
    final cached = await _loadCachedWeather();
    return cached ?? PlantWeatherInfo.mock(location: location.locationName);
  }

  /// Saves a manually selected custom location (e.g., Sangota, Swat)
  Future<void> setManualLocation(UserLocationData location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_manual_lat', location.latitude);
    await prefs.setDouble('user_manual_lon', location.longitude);
    await prefs.setString('user_manual_location_name', location.locationName);
    debugPrint("📌 Manual location saved: ${location.locationName} (${location.latitude}, ${location.longitude})");
  }

  /// Clears manual location preference and switches back to automatic IP location
  Future<void> clearManualLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_manual_lat');
    await prefs.remove('user_manual_lon');
    await prefs.remove('user_manual_location_name');
    debugPrint("🔄 Switched back to automatic location detection.");
  }

  /// Queries Open-Meteo Geocoding API for instant city/town search (e.g. Sangota, Swat, Peshawar, London)
  Future<List<UserLocationData>> searchLocations(String query) async {
    if (query.trim().isEmpty) return [];
    final client = HttpClient();
    try {
      final uri = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(query.trim())}&count=8&language=en&format=json',
      );
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 4));
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = json.decode(body);
        final List<dynamic> results = data['results'] ?? [];

        return results.map((r) {
          final String name = r['name'] ?? '';
          final String admin = r['admin1'] ?? '';
          final String countryCode = r['country_code'] ?? '';
          final double lat = (r['latitude'] as num).toDouble();
          final double lon = (r['longitude'] as num).toDouble();

          String locName = name;
          if (admin.isNotEmpty) locName += ', $admin';
          if (countryCode.isNotEmpty) locName += ', ${countryCode.toUpperCase()}';

          return UserLocationData(latitude: lat, longitude: lon, locationName: locName);
        }).toList();
      }
    } catch (e) {
      debugPrint("⚠️ Geocoding location search failed: $e");
    } finally {
      client.close();
    }
    return [];
  }

  /// Resolves the active location: checks user manual preference first, then IP geolocation, then default.
  Future<UserLocationData> _fetchUserLocation() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Check if user manually picked a location (e.g., Sangota, Swat)
    final manualLat = prefs.getDouble('user_manual_lat');
    final manualLon = prefs.getDouble('user_manual_lon');
    final manualName = prefs.getString('user_manual_location_name');
    if (manualLat != null && manualLon != null && manualName != null) {
      debugPrint("📌 Using User Manual Location: $manualName ($manualLat, $manualLon)");
      return UserLocationData(latitude: manualLat, longitude: manualLon, locationName: manualName);
    }

    // 2. Check cached location fallback
    final cachedLat = prefs.getDouble('cached_user_lat');
    final cachedLon = prefs.getDouble('cached_user_lon');
    final cachedCity = prefs.getString('cached_user_city');

    final client = HttpClient();
    try {
      // Primary IP Geolocation Provider: ip-api.com
      final uri = Uri.parse('http://ip-api.com/json/');
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 3));
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = json.decode(body);

        if (data['status'] == 'success') {
          final double lat = (data['lat'] as num).toDouble();
          final double lon = (data['lon'] as num).toDouble();
          final String city = data['city'] as String? ?? 'Your Area';
          final String countryCode = data['countryCode'] as String? ?? '';
          final String locName = countryCode.isNotEmpty ? '$city, $countryCode' : city;

          await prefs.setDouble('cached_user_lat', lat);
          await prefs.setDouble('cached_user_lon', lon);
          await prefs.setString('cached_user_city', locName);

          debugPrint("📍 User Location Detected: $locName ($lat, $lon)");
          return UserLocationData(latitude: lat, longitude: lon, locationName: locName);
        }
      }
    } catch (e) {
      debugPrint("⚠️ Primary IP Geolocation lookup failed: $e. Trying secondary provider...");
    } finally {
      client.close();
    }

    // Secondary IP Geolocation Provider: ipapi.co
    final client2 = HttpClient();
    try {
      final uri2 = Uri.parse('https://ipapi.co/json/');
      final request2 = await client2.getUrl(uri2).timeout(const Duration(seconds: 3));
      final response2 = await request2.close();

      if (response2.statusCode == 200) {
        final body2 = await response2.transform(utf8.decoder).join();
        final Map<String, dynamic> data2 = json.decode(body2);

        if (data2.containsKey('latitude') && data2.containsKey('longitude')) {
          final double lat = (data2['latitude'] as num).toDouble();
          final double lon = (data2['longitude'] as num).toDouble();
          final String city = data2['city'] as String? ?? 'Your Area';
          final String countryCode = data2['country_code'] as String? ?? '';
          final String locName = countryCode.isNotEmpty ? '$city, $countryCode' : city;

          await prefs.setDouble('cached_user_lat', lat);
          await prefs.setDouble('cached_user_lon', lon);
          await prefs.setString('cached_user_city', locName);

          debugPrint("📍 Secondary User Location Detected: $locName ($lat, $lon)");
          return UserLocationData(latitude: lat, longitude: lon, locationName: locName);
        }
      }
    } catch (e) {
      debugPrint("⚠️ Secondary IP Geolocation lookup failed: $e.");
    } finally {
      client2.close();
    }

    // Fallback to cached location or default to Sangota, Swat, PK
    if (cachedLat != null && cachedLon != null && cachedCity != null) {
      return UserLocationData(latitude: cachedLat, longitude: cachedLon, locationName: cachedCity);
    }

    // Default coordinates: Sangota, Swat, KPK, Pakistan (Lat: 34.7963, Lon: 72.4162)
    return UserLocationData(latitude: 34.7963, longitude: 72.4162, locationName: 'Sangota, Swat, PK');
  }

  /// Fetches weather from OpenWeather API using user coordinates
  Future<PlantWeatherInfo?> _fetchOpenWeather(UserLocationData location) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=${location.latitude}&lon=${location.longitude}&appid=$_openWeatherApiKey&units=metric',
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

          double uv = 0.0;
          if (isDay) {
            final hour = DateTime.now().hour;
            final double baseUv = (12 - (hour - 13).abs()).clamp(1.0, 9.0).toDouble();
            if (condition.toLowerCase().contains('cloudy') ||
                condition.toLowerCase().contains('rain') ||
                condition.toLowerCase().contains('thunderstorm')) {
              uv = baseUv * 0.4;
            } else {
              uv = baseUv;
            }
          }

          return _buildPlantWeatherInfo(
            temp: temp,
            humidity: humidity,
            uv: uv,
            condition: condition,
            desc: desc,
            locationName: location.locationName,
          );
        }
      }
    } catch (e) {
      debugPrint("⚠️ OpenWeather fetch failed: $e");
    } finally {
      client.close();
    }
    return null;
  }

  /// Fetches weather from Open-Meteo API using user coordinates (Free, Real-Time, Global)
  Future<PlantWeatherInfo?> _fetchOpenMeteoWeather(UserLocationData location) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${location.latitude}&longitude=${location.longitude}&current=temperature_2m,relative_humidity_2m,weather_code,is_day&timezone=auto',
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

          return _buildPlantWeatherInfo(
            temp: temp,
            humidity: humidity,
            uv: uv,
            condition: condition,
            desc: desc,
            locationName: location.locationName,
          );
        }
      }
    } catch (e) {
      debugPrint("⚠️ Open-Meteo weather fetch failed: $e");
    } finally {
      client.close();
    }
    return null;
  }

  PlantWeatherInfo _buildPlantWeatherInfo({
    required double temp,
    required int humidity,
    required double uv,
    required String condition,
    required String desc,
    required String locationName,
  }) {
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
      locationName: locationName,
    );
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

  Future<void> _cacheWeatherInfo(PlantWeatherInfo weather) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_weather_json', json.encode(weather.toJson()));
    } catch (_) {}
  }

  Future<PlantWeatherInfo?> _loadCachedWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cached_weather_json');
      if (raw != null && raw.isNotEmpty) {
        return PlantWeatherInfo.fromJson(json.decode(raw));
      }
    } catch (_) {}
    return null;
  }
}
