import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/weather_service.dart';

class WeatherStreakDashboard extends StatelessWidget {
  final int careStreak;
  final PlantWeatherInfo? weatherInfo;
  final bool loadingWeather;
  final VoidCallback? onRefreshWeather;

  const WeatherStreakDashboard({
    super.key,
    required this.careStreak,
    required this.weatherInfo,
    required this.loadingWeather,
    this.onRefreshWeather,
  });

  Color _getWeatherIconColor(String? condition) {
    if (condition == null) return Colors.amber;
    final cond = condition.toLowerCase();
    if (cond.contains('rain') || cond.contains('drizzle') || cond.contains('shower')) return Colors.lightBlue;
    if (cond.contains('cloudy') || cond.contains('partly')) return Colors.blueGrey;
    return Colors.amber;
  }

  IconData _getWeatherIcon(String? condition) {
    if (condition == null) return Icons.wb_sunny_rounded;
    final cond = condition.toLowerCase();
    if (cond.contains('sunny') || cond.contains('clear')) return Icons.wb_sunny_rounded;
    if (cond.contains('cloudy') || cond.contains('partly')) return Icons.cloud_queue_rounded;
    if (cond.contains('fog')) return Icons.blur_on_rounded;
    if (cond.contains('rain') || cond.contains('drizzle') || cond.contains('shower')) return Icons.grain_rounded;
    if (cond.contains('snow')) return Icons.ac_unit_rounded;
    if (cond.contains('thunderstorm')) return Icons.thunderstorm_rounded;
    return Icons.device_thermostat_rounded;
  }

  void _showLocationSearchBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        List<UserLocationData> searchResults = [];
        bool isSearching = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Choose Weather Location',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceMuted),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      autofocus: true,
                      style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type city or town (e.g. Sangota, Swat)',
                        hintStyle: const TextStyle(color: AppColors.onSurfaceMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                        suffixIcon: isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                ),
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surfaceHighlight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) async {
                        if (val.trim().length >= 2) {
                          setModalState(() => isSearching = true);
                          final results = await WeatherService().searchLocations(val);
                          setModalState(() {
                            searchResults = results;
                            isSearching = false;
                          });
                        } else {
                          setModalState(() {
                            searchResults = [];
                            isSearching = false;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    if (searchResults.isNotEmpty) ...[
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: searchResults.length,
                          separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                          itemBuilder: (c, idx) {
                            final loc = searchResults[idx];
                            return ListTile(
                              leading: const Icon(Icons.place_rounded, color: AppColors.primary, size: 18),
                              title: Text(
                                loc.locationName,
                                style: const TextStyle(color: AppColors.onSurface, fontSize: 13.5, fontWeight: FontWeight.w600),
                              ),
                              onTap: () async {
                                Navigator.pop(context);
                                await WeatherService().setManualLocation(loc);
                                if (onRefreshWeather != null) onRefreshWeather!();
                              },
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Popular Locations:',
                        style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildPresetChip(
                            context,
                            label: '📍 Sangota, Swat, PK',
                            lat: 34.7963,
                            lon: 72.4162,
                          ),
                          _buildPresetChip(
                            context,
                            label: '📍 Mingora, Swat, PK',
                            lat: 34.7717,
                            lon: 72.3600,
                          ),
                          _buildPresetChip(
                            context,
                            label: '📍 Peshawar, KPK, PK',
                            lat: 34.0151,
                            lon: 71.5249,
                          ),
                          _buildPresetChip(
                            context,
                            label: '📍 Islamabad, PK',
                            lat: 33.6844,
                            lon: 73.0479,
                          ),
                          _buildPresetChip(
                            context,
                            label: '📍 Lahore, PK',
                            lat: 31.5204,
                            lon: 74.3587,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await WeatherService().clearManualLocation();
                        if (onRefreshWeather != null) onRefreshWeather!();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryLight, width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 16),
                      label: const Text(
                        'Reset to Auto-IP Location',
                        style: TextStyle(color: AppColors.primary, fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPresetChip(BuildContext context, {required String label, required double lat, required double lon}) {
    return ActionChip(
      backgroundColor: AppColors.surfaceHighlight,
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
      label: Text(label, style: const TextStyle(color: AppColors.onSurface, fontSize: 11.5, fontWeight: FontWeight.w500)),
      onPressed: () async {
        Navigator.pop(context);
        final loc = UserLocationData(latitude: lat, longitude: lon, locationName: label.replaceAll('📍 ', ''));
        await WeatherService().setManualLocation(loc);
        if (onRefreshWeather != null) onRefreshWeather!();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Streak Card
            Expanded(
              flex: 2,
              child: Container(
                constraints: const BoxConstraints(minHeight: 130),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.borderLight.withValues(alpha: 0.2),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 18),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'STREAK',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$careStreak Day${careStreak == 1 ? "" : "s"}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Daily care active',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Weather Card (Interactive Location Selector)
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: () => _showLocationSearchBottomSheet(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 130),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.borderLight.withValues(alpha: 0.2),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: loadingWeather
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getWeatherIcon(weatherInfo?.condition),
                                    color: _getWeatherIconColor(weatherInfo?.condition),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          weatherInfo?.condition ?? 'Clear',
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                weatherInfo?.locationName ?? 'Sangota, Swat, PK',
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: AppColors.onSurfaceMuted,
                                                  fontSize: 9.5,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const Icon(Icons.edit_location_alt_rounded, color: AppColors.primary, size: 11),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${weatherInfo?.temperature != null ? weatherInfo!.temperature.toStringAsFixed(1) : "24"}°C',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildWeatherMetricBadge(
                                    icon: Icons.water_drop_rounded,
                                    iconColor: Colors.lightBlue,
                                    label: 'Humidity',
                                    value: '${weatherInfo?.humidity ?? 60}%',
                                    theme: theme,
                                  ),
                                  _buildWeatherMetricBadge(
                                    icon: Icons.wb_sunny_rounded,
                                    iconColor: Colors.amber,
                                    label: 'UV Index',
                                    value: '${weatherInfo?.uvIndex ?? 5.0}',
                                    theme: theme,
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (weatherInfo?.isFrostWarning == true ? AppColors.danger : AppColors.primary).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (weatherInfo?.isFrostWarning == true ? AppColors.danger : AppColors.primaryLight).withValues(alpha: 0.15),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      weatherInfo?.isFrostWarning == true ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                                      size: 10,
                                      color: weatherInfo?.isFrostWarning == true ? AppColors.dangerLight : AppColors.primaryLight,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        weatherInfo?.outdoorAdvice ?? 'Optimal conditions for plants.',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: weatherInfo?.isFrostWarning == true ? AppColors.dangerLight : AppColors.onSurfaceMuted,
                                          fontSize: 9.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherMetricBadge({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceMuted,
                  fontSize: 8.5,
                  height: 1.0,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                  fontSize: 10.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
