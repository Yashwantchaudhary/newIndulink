import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../models/loyalty.dart';
import '../services/loyalty_service.dart';

/// Loyalty state
class LoyaltyState {
  final int points;
  final String tier;
  final int lifetimePoints;
  final List<LoyaltyTransaction> transactions;
  final List<Badge> userBadges;
  final List<Badge> allBadges;
  final List<Map<String, dynamic>> tiers;
  final bool isLoading;
  final String? error;

  LoyaltyState({
    this.points = 0,
    this.tier = 'bronze',
    this.lifetimePoints = 0,
    this.transactions = const [],
    this.userBadges = const [],
    this.allBadges = const [],
    this.tiers = const [],
    this.isLoading = false,
    this.error,
  });

  LoyaltyState copyWith({
    int? points,
    String? tier,
    int? lifetimePoints,
    List<LoyaltyTransaction>? transactions,
    List<Badge>? userBadges,
    List<Badge>? allBadges,
    List<Map<String, dynamic>>? tiers,
    bool? isLoading,
    String? error,
  }) {
    return LoyaltyState(
      points: points ?? this.points,
      tier: tier ?? this.tier,
      lifetimePoints: lifetimePoints ?? this.lifetimePoints,
      transactions: transactions ?? this.transactions,
      userBadges: userBadges ?? this.userBadges,
      allBadges: allBadges ?? this.allBadges,
      tiers: tiers ?? this.tiers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Loyalty notifier
class LoyaltyNotifier extends StateNotifier<LoyaltyState> {
  final LoyaltyService _loyaltyService = LoyaltyService();

  LoyaltyNotifier() : super(LoyaltyState());

  /// Load all loyalty data
  Future<void> loadLoyaltyData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load points in parallel with other data
      final results = await Future.wait([
        _loyaltyService.getLoyaltyPoints(),
        _loyaltyService.getTransactions(),
        _loyaltyService.getUserBadges(),
        _loyaltyService.getAllBadges(),
        _loyaltyService.getLoyaltyTiers(),
      ]);

      final pointsData = results[0] as Map<String, dynamic>;
      final transactions = results[1] as List<LoyaltyTransaction>;
      final userBadges = results[2] as List<Badge>;
      final allBadges = results[3] as List<Badge>;
      final tiers = results[4] as List<Map<String, dynamic>>;

      state = state.copyWith(
        points: pointsData['points'] ?? 0,
        tier: pointsData['tier'] ?? 'bronze',
        lifetimePoints: pointsData['lifetimePoints'] ?? 0,
        transactions: transactions,
        userBadges: userBadges,
        allBadges: allBadges,
        tiers: tiers,
        isLoading: false,
      );

      developer.log('Loyalty data loaded successfully',
          name: 'LoyaltyProvider');
    } catch (e) {
      developer.log('Error loading loyalty data: $e',
          name: 'LoyaltyProvider', error: e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh loyalty points
  Future<void> refreshPoints() async {
    try {
      final pointsData = await _loyaltyService.getLoyaltyPoints();
      state = state.copyWith(
        points: pointsData['points'] ?? 0,
        tier: pointsData['tier'] ?? 'bronze',
        lifetimePoints: pointsData['lifetimePoints'] ?? 0,
      );
    } catch (e) {
      developer.log('Error refreshing points: $e',
          name: 'LoyaltyProvider', error: e);
    }
  }

  /// Redeem points
  Future<bool> redeemPoints(int points, String reason) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _loyaltyService.redeemPoints(
        points: points,
        reason: reason,
      );

      if (success) {
        // Refresh points after redemption
        await refreshPoints();
        // Refresh transactions
        final transactions = await _loyaltyService.getTransactions();
        state = state.copyWith(
          transactions: transactions,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }

      return success;
    } catch (e) {
      developer.log('Error redeeming points: $e',
          name: 'LoyaltyProvider', error: e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}

/// Loyalty provider
final loyaltyProvider =
    StateNotifierProvider<LoyaltyNotifier, LoyaltyState>((ref) {
  return LoyaltyNotifier();
});
