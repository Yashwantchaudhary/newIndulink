import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/analytics_service.dart';
import '../models/analytics_models.dart';
import '../config/api_client.dart';
import 'dart:io';

part 'analytics_provider.g.dart';

// Analytics Service Provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AnalyticsService(apiClient);
});

// Sales Trends Provider
@riverpod
class SalesTrendsNotifier extends _$SalesTrendsNotifier {
  @override
  Future<SalesTrends?> build() async {
    return null; // Initial state
  }

  Future<void> fetchSalesTrends({
    required String startDate,
    required String endDate,
    String interval = 'day',
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(analyticsServiceProvider);
      return await service.getSalesTrends(
        startDate: startDate,
        endDate: endDate,
        interval: interval,
      );
    });
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

// Product Performance Provider
@riverpod
class ProductPerformanceNotifier extends _$ProductPerformanceNotifier {
  @override
  Future<ProductPerformance?> build() async {
    return null;
  }

  Future<void> fetchProductPerformance({int limit = 20}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(analyticsServiceProvider);
      return await service.getProductPerformance(limit: limit);
    });
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

// Customer Behavior Provider
@riverpod
class CustomerBehaviorNotifier extends _$CustomerBehaviorNotifier {
  @override
  Future<CustomerBehavior?> build() async {
    return null;
  }

  Future<void> fetchCustomerBehavior() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(analyticsServiceProvider);
      return await service.getCustomerBehavior();
    });
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

// Supplier Performance Provider
@riverpod
class SupplierPerformanceNotifier extends _$SupplierPerformanceNotifier {
  @override
  Future<SupplierPerformance?> build() async {
    return null;
  }

  Future<void> fetchSupplierPerformance() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(analyticsServiceProvider);
      return await service.getSupplierPerformance();
    });
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

// Comparative Analysis Provider
@riverpod
class ComparativeAnalysisNotifier extends _$ComparativeAnalysisNotifier {
  @override
  Future<ComparativeAnalysis?> build() async {
    return null;
  }

  Future<void> fetchComparative({String period = 'month'}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(analyticsServiceProvider);
      return await service.getComparative(period: period);
    });
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

// Date Range State Provider
class DateRangeState {
  final DateTime startDate;
  final DateTime endDate;
  final String preset;

  DateRangeState({
    required this.startDate,
    required this.endDate,
    this.preset = 'month',
  });

  DateRangeState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? preset,
  }) {
    return DateRangeState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      preset: preset ?? this.preset,
    );
  }
}

@riverpod
class DateRangeNotifier extends _$DateRangeNotifier {
  @override
  DateRangeState build() {
    // Default to last 30 days
    final now = DateTime.now();
    return DateRangeState(
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
      preset: 'month',
    );
  }

  void setDateRange(DateTime start, DateTime end, {String preset = 'custom'}) {
    state = DateRangeState(
      startDate: start,
      endDate: end,
      preset: preset,
    );
  }

  void setPreset(String preset) {
    final range = AnalyticsService.getPresetRange(preset);
    state = DateRangeState(
      startDate: range.start,
      endDate: range.end,
      preset: preset,
    );
  }
}

// Export Status Provider
enum ExportStatus { idle, loading, success, error }

class ExportState {
  final ExportStatus status;
  final File? file;
  final String? error;

  ExportState({
    required this.status,
    this.file,
    this.error,
  });

  ExportState copyWith({
    ExportStatus? status,
    File? file,
    String? error,
  }) {
    return ExportState(
      status: status ?? this.status,
      file: file ?? this.file,
      error: error ?? this.error,
    );
  }
}

@riverpod
class ExportNotifier extends _$ExportNotifier {
  @override
  ExportState build() {
    return ExportState(status: ExportStatus.idle);
  }

  Future<void> exportCSV({
    required String reportType,
    required String startDate,
    required String endDate,
  }) async {
    state = ExportState(status: ExportStatus.loading);

    try {
      final service = ref.read(analyticsServiceProvider);
      final file = await service.exportCSV(
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
      );

      state = ExportState(
        status: ExportStatus.success,
        file: file,
      );
    } catch (e) {
      state = ExportState(
        status: ExportStatus.error,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = ExportState(status: ExportStatus.idle);
  }
}

// Predictive Insights Provider
@riverpod
class PredictiveInsightsNotifier extends _$PredictiveInsightsNotifier {
  @override
  Future<PredictiveInsights?> build() async {
    return null;
  }

  Future<void> fetchPredictiveInsights({int period = 30}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(analyticsServiceProvider);
      return await service.getPredictiveInsights(period: period);
    });
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

// User Segmentation Provider
@riverpod
class UserSegmentationNotifier extends _$UserSegmentationNotifier {
  @override
  Future<UserSegmentation?> build() async {
    return null;
  }

  Future<void> fetchUserSegmentation() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(analyticsServiceProvider);
      return await service.getUserSegmentation();
    });
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}
