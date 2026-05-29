import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/payments_api.dart';
import '../../shared/models/payment.dart';

class PaymentState {
  final Payment? payment;
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final String? paymentUrl; // for redirect-based payment

  const PaymentState({
    this.payment,
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.paymentUrl,
  });

  PaymentState copyWith({
    Payment? payment,
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? paymentUrl,
  }) {
    return PaymentState(
      payment: payment ?? this.payment,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
      paymentUrl: paymentUrl ?? this.paymentUrl,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentsApi _api;
  final String enrollmentId;

  PaymentNotifier({required PaymentsApi api, required this.enrollmentId})
      : _api = api,
        super(const PaymentState());

  Future<bool> initiateMobileMoney({
    required String method,
    required String telephone,
    required int echeances,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.initiateCinetPay(
        enrollmentId: enrollmentId,
        method: method,
        telephone: telephone,
        echeances: echeances,
      );
      final payment = Payment.fromJson(data['payment'] ?? data);
      state = state.copyWith(
        payment: payment,
        isLoading: false,
        isSuccess: payment.isConfirme,
        paymentUrl: data['payment_url'],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> initiateStripe() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.initiateStripe(enrollmentId: enrollmentId);
      state = state.copyWith(
        isLoading: false,
        paymentUrl: data['payment_url'] ?? data['client_secret'],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> checkStatus(String paymentId) async {
    try {
      final data = await _api.checkPaymentStatus(paymentId);
      final payment = Payment.fromJson(data);
      state = state.copyWith(
        payment: payment,
        isSuccess: payment.isConfirme,
      );
    } catch (_) {}
  }
}

final paymentProvider =
    StateNotifierProvider.autoDispose.family<PaymentNotifier, PaymentState, String>(
  (ref, enrollmentId) {
    final api = ref.read(paymentsApiProvider);
    return PaymentNotifier(api: api, enrollmentId: enrollmentId);
  },
);
