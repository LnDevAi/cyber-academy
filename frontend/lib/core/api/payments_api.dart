import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

final paymentsApiProvider = Provider<PaymentsApi>((ref) {
  return PaymentsApi(ref.read(apiClientProvider));
});

class PaymentsApi {
  final ApiClient _client;
  PaymentsApi(this._client);

  Future<Map<String, dynamic>> initiateCinetPay({
    required String enrollmentId,
    required String method,
    required String telephone,
    required int echeances,
  }) async {
    final response = await _client.post('/payments/cinetpay/initiate/', data: {
      'enrollment_id': enrollmentId,
      'method': method,
      'telephone': telephone,
      'echeances': echeances,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> initiateStripe({
    required String enrollmentId,
  }) async {
    final response = await _client.post('/payments/stripe/intent/', data: {
      'enrollment_id': enrollmentId,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> checkPaymentStatus(String paymentId) async {
    final response = await _client.get('/payments/$paymentId/status/');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> listPayments() async {
    final response = await _client.get('/payments/');
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> listAllPayments() async {
    final response = await _client.get('/admin/payments/');
    return response.data as List<dynamic>;
  }
}
