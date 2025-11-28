import 'dart:developer' as developer;
import '../models/loyalty.dart';
import 'api_service.dart';

/// Loyalty service for points and rewards
class LoyaltyService {
  final ApiService _apiService = ApiService();

  /// Get user's loyalty points and stats
  Future<Map<String, dynamic>> getLoyaltyPoints() async {
    try {
      developer.log('Fetching loyalty points', name: 'LoyaltyService');

      final response = await _apiService.get('/loyalty/points');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      }

      throw Exception('Failed to fetch loyalty points');
    } catch (e) {
      developer.log('Error fetching loyalty points: $e',
          name: 'LoyaltyService', error: e);
      rethrow;
    }
  }

  /// Get loyalty transaction history
  Future<List<LoyaltyTransaction>> getTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      developer.log('Fetching loyalty transactions', name: 'LoyaltyService');

      final response = await _apiService.get(
        '/loyalty/transactions',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List transactionsData = response.data['data']['transactions'];
        return transactionsData
            .map((json) => LoyaltyTransaction.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      developer.log('Error fetching transactions: $e',
          name: 'LoyaltyService', error: e);
      rethrow;
    }
  }

  /// Get all available badges
  Future<List<Badge>> getAllBadges() async {
    try {
      developer.log('Fetching all badges', name: 'LoyaltyService');

      final response = await _apiService.get('/loyalty/badges');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List badgesData = response.data['data'];
        return badgesData.map((json) => Badge.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      developer.log('Error fetching badges: $e',
          name: 'LoyaltyService', error: e);
      rethrow;
    }
  }

  /// Get user's earned badges
  Future<List<Badge>> getUserBadges() async {
    try {
      developer.log('Fetching user badges', name: 'LoyaltyService');

      final response = await _apiService.get('/loyalty/user-badges');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List badgesData = response.data['data'];
        return badgesData.map((json) => Badge.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      developer.log('Error fetching user badges: $e',
          name: 'LoyaltyService', error: e);
      rethrow;
    }
  }

  /// Get loyalty tier information
  Future<List<Map<String, dynamic>>> getLoyaltyTiers() async {
    try {
      developer.log('Fetching loyalty tiers', name: 'LoyaltyService');

      final response = await _apiService.get('/loyalty/tiers');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }

      return [];
    } catch (e) {
      developer.log('Error fetching tiers: $e',
          name: 'LoyaltyService', error: e);
      rethrow;
    }
  }

  /// Redeem loyalty points
  Future<bool> redeemPoints({
    required int points,
    required String reason,
  }) async {
    try {
      developer.log('Redeeming $points points', name: 'LoyaltyService');

      final response = await _apiService.post(
        '/loyalty/redeem',
        data: {
          'points': points,
          'reason': reason,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        developer.log('Points redeemed successfully', name: 'LoyaltyService');
        return true;
      }

      return false;
    } catch (e) {
      developer.log('Error redeeming points: $e',
          name: 'LoyaltyService', error: e);
      rethrow;
    }
  }
}
