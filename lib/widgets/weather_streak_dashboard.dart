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
            // Weather Card (Clean, Automatic, Full Advice Visible)
            Expanded(
              flex: 3,
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Header Row: Weather Condition & Temp (No location text as requested)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getWeatherIcon(weatherInfo?.condition),
                                      color: _getWeatherIconColor(weatherInfo?.condition),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      weatherInfo?.condition ?? '—',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  weatherInfo?.temperature != null
                                      ? '${weatherInfo!.temperature.toStringAsFixed(1)}°C'
                                      : '—',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Metrics Row: Humidity & UV Index
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildWeatherMetricBadge(
                                  icon: Icons.water_drop_rounded,
                                  iconColor: Colors.lightBlue,
                                  label: 'Humidity',
                                  value: weatherInfo?.humidity != null
                                    ? '${weatherInfo!.humidity}%'
                                    : '—',
                                  theme: theme,
                                ),
                                _buildWeatherMetricBadge(
                                  icon: Icons.wb_sunny_rounded,
                                  iconColor: Colors.amber,
                                  label: 'UV Index',
                                  value: weatherInfo?.uvIndex != null
                                    ? '${weatherInfo!.uvIndex}'
                                    : '—',
                                  theme: theme,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Full Advice Box: Fully visible without ellipsis truncation
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: (weatherInfo?.isFrostWarning == true ? AppColors.danger : AppColors.primary).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (weatherInfo?.isFrostWarning == true ? AppColors.danger : AppColors.primaryLight).withValues(alpha: 0.15),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 1),
                                    child: Icon(
                                      weatherInfo?.isFrostWarning == true ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                                      size: 13,
                                      color: weatherInfo?.isFrostWarning == true ? AppColors.dangerLight : AppColors.primaryLight,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      weatherInfo?.outdoorAdvice ?? 'Weather is optimal for outdoor plants.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: weatherInfo?.isFrostWarning == true ? AppColors.dangerLight : AppColors.onSurfaceMuted,
                                        fontSize: 9.8,
                                        height: 1.25,
                                      ),
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
