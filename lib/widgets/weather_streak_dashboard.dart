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
    if (cond.contains('rain') ||
        cond.contains('drizzle') ||
        cond.contains('shower')) {
      return Colors.lightBlue;
    }
    if (cond.contains('cloudy') || cond.contains('partly')) {
      return Colors.blueGrey;
    }
    return Colors.amber;
  }

  IconData _getWeatherIcon(String? condition) {
    if (condition == null) return Icons.wb_sunny_rounded;
    final cond = condition.toLowerCase();
    if (cond.contains('sunny') || cond.contains('clear')) {
      return Icons.wb_sunny_rounded;
    }
    if (cond.contains('cloudy') || cond.contains('partly')) {
      return Icons.cloud_queue_rounded;
    }
    if (cond.contains('fog')) return Icons.blur_on_rounded;
    if (cond.contains('rain') ||
        cond.contains('drizzle') ||
        cond.contains('shower')) {
      return Icons.grain_rounded;
    }
    if (cond.contains('snow')) return Icons.ac_unit_rounded;
    if (cond.contains('thunderstorm')) return Icons.thunderstorm_rounded;
    return Icons.device_thermostat_rounded;
  }

  String _getStreakLabel() {
    if (careStreak == 0) return 'Start your streak!';
    if (careStreak < 3) return 'Keep it up!';
    if (careStreak < 7) return 'Building momentum';
    if (careStreak < 14) return 'On fire! 🔥';
    return 'Legendary gardener';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final hPad = constraints.maxWidth < 360 ? 16.0 : 24.0;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8.0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Streak Card ─────────────────────────────────────────
                Expanded(
                  flex: 5,
                  child: _StreakCard(
                    careStreak: careStreak,
                    streakLabel: _getStreakLabel(),
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 12),
                // ── Weather Card ─────────────────────────────────────────
                Expanded(
                  flex: 7,
                  child: _WeatherCard(
                    weatherInfo: weatherInfo,
                    loadingWeather: loadingWeather,
                    onRefreshWeather: onRefreshWeather,
                    weatherIcon: _getWeatherIcon(weatherInfo?.condition),
                    weatherIconColor: _getWeatherIconColor(weatherInfo?.condition),
                    theme: theme,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int careStreak;
  final String streakLabel;
  final ThemeData theme;

  const _StreakCard({
    required this.careStreak,
    required this.streakLabel,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final hasStreak = careStreak > 0;
    final streakColor = hasStreak ? Colors.orange : AppColors.onSurfaceFaint;

    return Container(
      constraints: const BoxConstraints(minHeight: 130),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            hasStreak
                ? Colors.orange.withValues(alpha: 0.10)
                : AppColors.surfaceElevated,
            AppColors.surfaceElevated,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasStreak
              ? Colors.orange.withValues(alpha: 0.22)
              : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasStreak
                ? Colors.orange.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
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
            // Label row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: streakColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: streakColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'STREAK',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: streakColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            // Count + description
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$careStreak',
                  style: TextStyle(
                    fontFamily: 'NunitoSans',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: hasStreak ? Colors.orange : AppColors.onSurfaceFaint,
                    height: 1.0,
                  ),
                ),
                Text(
                  careStreak == 1 ? 'Day' : 'Days',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hasStreak ? Colors.orange.withValues(alpha: 0.8) : AppColors.onSurfaceFaint,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  streakLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceMuted,
                    fontSize: 9.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  final PlantWeatherInfo? weatherInfo;
  final bool loadingWeather;
  final VoidCallback? onRefreshWeather;
  final IconData weatherIcon;
  final Color weatherIconColor;
  final ThemeData theme;

  const _WeatherCard({
    required this.weatherInfo,
    required this.loadingWeather,
    required this.onRefreshWeather,
    required this.weatherIcon,
    required this.weatherIconColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 130),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: loadingWeather
          ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Header: icon + condition + temp + refresh
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: weatherIconColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              weatherIcon,
                              color: weatherIconColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            weatherInfo?.condition ?? '—',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            weatherInfo?.temperature != null
                                ? '${weatherInfo!.temperature.toStringAsFixed(0)}°'
                                : '—',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                          if (onRefreshWeather != null) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: onRefreshWeather,
                              child: Icon(
                                Icons.refresh_rounded,
                                size: 14,
                                color: AppColors.onSurfaceFaint,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Metrics Row
                  Row(
                    children: [
                      _buildMetricBadge(
                        icon: Icons.water_drop_rounded,
                        iconColor: Colors.lightBlue,
                        label: 'Humidity',
                        value: weatherInfo?.humidity != null
                            ? '${weatherInfo!.humidity}%'
                            : '—',
                      ),
                      const SizedBox(width: 8),
                      _buildMetricBadge(
                        icon: Icons.wb_sunny_rounded,
                        iconColor: Colors.amber,
                        label: 'UV Index',
                        value: weatherInfo?.uvIndex != null
                            ? '${weatherInfo!.uvIndex}'
                            : '—',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Advice box
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: (weatherInfo?.isFrostWarning == true
                              ? AppColors.danger
                              : AppColors.primary)
                          .withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (weatherInfo?.isFrostWarning == true
                                ? AppColors.danger
                                : AppColors.primaryLight)
                            .withValues(alpha: 0.18),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(
                            weatherInfo?.isFrostWarning == true
                                ? Icons.warning_amber_rounded
                                : Icons.eco_rounded,
                            size: 12,
                            color: weatherInfo?.isFrostWarning == true
                                ? AppColors.dangerLight
                                : AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            weatherInfo?.outdoorAdvice ??
                                'Weather is optimal for outdoor plants.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: weatherInfo?.isFrostWarning == true
                                  ? AppColors.dangerLight
                                  : AppColors.onSurfaceMuted,
                              fontSize: 9.5,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricBadge({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 5),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.onSurfaceFaint,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      fontSize: 11,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
