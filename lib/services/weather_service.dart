import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  static const String _openWeatherApiKey = String.fromEnvironment(
    'OPEN_WEATHER_API_KEY',
    defaultValue: '0b5d11d8aa2fb213fdf6959519484e99',
  );

  /// Fetches real-time weather based dynamically on hardware GPS or user selected location.
  Future<PlantWeatherInfo> getWeather() async {
    // 1. Resolve user location
    final location = await _fetchUserLocation();
    
    PlantWeatherInfo? weather;

    // 2. Primary: Fetch from Open-Meteo with high-resolution ECMWF/ICON mountain & valley terrain models
    weather = await _fetchOpenMeteoWeather(location);

    // 3. Secondary/Fallback: If Open-Meteo is unreachable, fallback to OpenWeather API
    if (weather == null && _openWeatherApiKey.isNotEmpty) {
      weather = await _fetchOpenWeather(location);
    }

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
    await prefs.remove('cached_weather_json');
    debugPrint("📌 Manual location saved: ${location.locationName} (${location.latitude}, ${location.longitude})");
  }

  /// Clears manual location preference and switches back to automatic hardware GPS location
  Future<void> clearManualLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_manual_lat');
    await prefs.remove('user_manual_lon');
    await prefs.remove('user_manual_location_name');
    await prefs.remove('cached_user_city');
    await prefs.remove('cached_weather_json');
    debugPrint("🔄 Switched back to automatic hardware location detection.");
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

  /// Reverse geocodes exact coordinates into a human-readable city/town name (e.g. Sangota, Swat, PK)
  Future<String?> _reverseGeocode(double lat, double lon) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=en');
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 3));
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = json.decode(body);

        final locInfo = data['localityInfo'] ?? {};
        final admin = locInfo['administrative'] as List? ?? [];

        String? town;
        String? district;
        final String countryCode = data['countryCode'] as String? ?? 'PK';

        for (var item in admin) {
          final String name = item['name'] ?? '';
          if (name.toLowerCase().contains('district') || name.toLowerCase().contains('swat')) {
            district = name.replaceAll(' District', '');
          }
          final int level = item['adminLevel'] ?? 0;
          if (level >= 7 && town == null && !name.contains('Tehsil')) {
            town = name;
          }
        }

        town ??= data['city'] ?? data['locality'];
        district ??= data['principalSubdivision'];

        if (town != null && district != null && town != district) {
          return '$town, $district, $countryCode';
        } else if (district != null) {
          return '$district, $countryCode';
        }
      }
    } catch (e) {
      debugPrint("⚠️ Reverse geocoding error: $e");
    } finally {
      client.close();
    }
    return null;
  }

  /// Resolves the active location: checks user manual preference first, then hardware GPS, then IP geolocation.
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

    // 2. Hardware Device GPS Location (via Geolocator)
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled && (permission == LocationPermission.whileInUse || permission == LocationPermission.always)) {
          final Position pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 4),
            ),
          );
          
          final String? geocodedName = await _reverseGeocode(pos.latitude, pos.longitude);
          final String locName = geocodedName ?? 'Sangota, Swat, PK';

          await prefs.setDouble('cached_user_lat', pos.latitude);
          await prefs.setDouble('cached_user_lon', pos.longitude);
          await prefs.setString('cached_user_city', locName);

          debugPrint("📡 Hardware GPS Location: $locName (${pos.latitude}, ${pos.longitude})");
          return UserLocationData(latitude: pos.latitude, longitude: pos.longitude, locationName: locName);
        }
    } catch (e) {
      debugPrint("⚠️ Hardware GPS lookup failed or timed out: $e. Falling back to IP/Cache...");
    }

    // 3. Check cached location fallback & clear legacy inaccurate Lahore/Islamabad IP defaults
    final cachedLat = prefs.getDouble('cached_user_lat');
    final cachedLon = prefs.getDouble('cached_user_lon');
    final cachedCity = prefs.getString('cached_user_city');

    if (cachedCity != null && (cachedCity.contains('Lahore') || cachedCity.contains('Islamabad') || cachedCity.contains('Local Area'))) {
      debugPrint("🧹 Cleared legacy inaccurate location cache ($cachedCity). Defaulting to Sangota, Swat.");
      await prefs.remove('cached_user_city');
      await prefs.remove('cached_user_lat');
      await prefs.remove('cached_user_lon');
    } else if (cachedLat != null && cachedLon != null && cachedCity != null) {
      return UserLocationData(latitude: cachedLat, longitude: cachedLon, locationName: cachedCity);
    }

    // 4. Default coordinates: Sangota, Swat, KPK, Pakistan (Lat: 34.7963, Lon: 72.4162)
    return UserLocationData(latitude: 34.7963, longitude: 72.4162, locationName: 'Sangota, Swat, PK');
  }

  /// Fetches weather from Open-Meteo API using high-resolution ECMWF/ICON terrain models
  Future<PlantWeatherInfo?> _fetchOpenMeteoWeather(UserLocationData location) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${location.latitude}&longitude=${location.longitude}&current=temperature_2m,relative_humidity_2m,weather_code,is_day,precipitation&timezone=auto',
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
