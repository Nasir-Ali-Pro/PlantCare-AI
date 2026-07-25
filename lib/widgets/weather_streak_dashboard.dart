import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/weather_service.dart';

class WeatherStreakDashboard extends StatelessWidget {
  final int careStreak;
  final PlantWeatherInfo? weatherInfo;
  final bool loadingWeather;

  const WeatherStreakDashboard({
    super.key,
    required this.careStreak,
    required this.weatherInfo,
    required this.loadingWeather,
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
            // Weather Card
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
                                  child: Text(
                                    weatherInfo?.condition ?? 'Clear',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
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
                                        fontSize: 9,
                                        color: weatherInfo?.isFrostWarning == true ? AppColors.dangerLight : AppColors.onSurfaceMuted,
                                        fontWeight: weatherInfo?.isFrostWarning == true ? FontWeight.bold : FontWeight.normal,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: iconColor),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 7, color: AppColors.onSurfaceFaint, fontWeight: FontWeight.w600),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSurface),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
