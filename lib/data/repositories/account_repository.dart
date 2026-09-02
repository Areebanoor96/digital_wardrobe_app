import 'package:digital_wardrobe_app/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Client-side wrapper around the server-side account-management Edge Functions.
///
/// All privileged operations (toggling account status, permanently deleting
/// the Auth user and Storage objects) happen inside secure Edge Functions that
/// run with the service-role key — only the anon key and the requesting user's
/// JWT are ever used from the client.
class AccountRepository {
  const AccountRepository();

  /// Temporarily deactivates the signed-in account. Data is preserved and the
  /// account can be reactivated later. The user is signed out separately by the
  /// caller after a successful response.
  Future<void> deactivateAccount() async {
    await _invoke('account-deactivation', <String, dynamic>{
      'action': 'deactivate',
    });
  }

  /// Reactivates a temporarily deactivated account.
  Future<void> reactivateAccount() async {
    await _invoke('account-deactivation', <String, dynamic>{
      'action': 'reactivate',
    });
  }

  /// Permanently deletes the account and all associated user data.
  Future<void> deleteAccount() async {
    await _invoke('delete-account', <String, dynamic>{});
  }

  Future<void> _invoke(String name, Map<String, dynamic> body) async {
    final FunctionResponse response = await SupabaseService
        .client
        .functions
        .invoke(name, body: body);

    final Map<String, dynamic> data = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};

    final String? error = data['error'] as String?;

    if (error != null && error.isNotEmpty) {
      throw AccountOperationException(error);
    }
  }
}

class AccountOperationException implements Exception {
  AccountOperationException(this.message);

  final String message;

  @override
  String toString() => message;
}
