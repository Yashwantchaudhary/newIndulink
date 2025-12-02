import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/address_provider.dart';
import '../../services/api_service.dart';

/// 🧪 API Test Screen
/// Simple screen to test data flow between Flutter and backend
class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final ApiService _apiService = ApiService();
  String _testResult = 'Not tested yet';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Test Screen'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Data Flow: Flutter ↔ Database',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Test Buttons
            ElevatedButton(
              onPressed: _testGetProducts,
              child: const Text('1. Test GET Products'),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _testPostAddress,
              child: const Text('2. Test POST Address (Will Fail - No Backend)'),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _testGetCategories,
              child: const Text('3. Test GET Categories'),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _testRawApiCall,
              child: const Text('4. Test Raw API Call'),
            ),
            const SizedBox(height: 20),

            // Results
            Text(
              'Test Result:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      _testResult,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testGetProducts() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing GET /api/products...';
    });

    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      await productProvider.fetchProducts();

      if (productProvider.products.isNotEmpty) {
        setState(() {
          _testResult = '✅ SUCCESS: Retrieved ${productProvider.products.length} products\n'
              'First product: ${productProvider.products[0].title}';
        });
      } else {
        setState(() {
          _testResult = '⚠️ PARTIAL: No products found (backend may be empty)';
        });
      }
    } catch (e) {
      setState(() {
        _testResult = '❌ FAILED: $e';
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testPostAddress() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing POST /api/addresses (Expected to fail - no backend)...';
    });

    try {
      final addressProvider = Provider.of<AddressProvider>(context, listen: false);

      // Create a test address
      final testAddress = Address(
        id: '',
        fullName: 'Test User',
        phoneNumber: '+9779800000000',
        addressLine1: 'Test Address Line 1',
        city: 'Kathmandu',
        state: 'Bagmati',
        zipCode: '44600',
      );

      final success = await addressProvider.addAddress(testAddress);

      if (success) {
        setState(() {
          _testResult = '✅ SUCCESS: Address added successfully';
        });
      } else {
        setState(() {
          _testResult = '❌ FAILED: ${addressProvider.errorMessage ?? "Unknown error"}';
        });
      }
    } catch (e) {
      setState(() {
        _testResult = '❌ FAILED: $e\n(This is expected - no address backend endpoints)';
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testGetCategories() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing GET /api/categories...';
    });

    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      await productProvider.fetchCategories();

      if (productProvider.categories.isNotEmpty) {
        setState(() {
          _testResult = '✅ SUCCESS: Retrieved ${productProvider.categories.length} categories\n'
              'First category: ${productProvider.categories[0].name}';
        });
      } else {
        setState(() {
          _testResult = '⚠️ PARTIAL: No categories found (backend may be empty)';
        });
      }
    } catch (e) {
      setState(() {
        _testResult = '❌ FAILED: $e';
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _testRawApiCall() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing raw API call to backend...';
    });

    try {
      final response = await _apiService.get('/products', requiresAuth: false);

      setState(() {
        _testResult = 'Raw API Response:\n'
            'Status: ${response.statusCode}\n'
            'Success: ${response.success}\n'
            'Message: ${response.message ?? "No message"}\n'
            'Has Data: ${response.data != null}';
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ FAILED: $e\nCheck if backend server is running on localhost:5000';
      });
    }

    setState(() => _isLoading = false);
  }
}