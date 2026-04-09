import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_campaign.dart';
import '../utils/perf_diagnostics.dart';
import 'auth_service.dart';

class AppCampaignException implements Exception {
  final String message;
  const AppCampaignException(this.message);

  @override
  String toString() => 'AppCampaignException: $message';
}

class AppCampaignUnauthorizedException extends AppCampaignException {
  const AppCampaignUnauthorizedException(super.message);
}

class AppCampaignService {
  static final _supabase = Supabase.instance.client;
  static const _campaignCacheTtl = Duration(seconds: 45);
  static String? _cachedAppVersion;
  static final Map<String, _CampaignCacheEntry> _campaignCache = {};

  static void _logError(String action, Object error, [StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('❌ AppCampaignService ERROR [$action]: $error');
      if (stack != null) debugPrint(stack.toString());
    }
  }

  static Future<String> getAppVersion() async {
    if (_cachedAppVersion != null) return _cachedAppVersion!;

    final info = await PackageInfo.fromPlatform();
    _cachedAppVersion = '${info.version}+${info.buildNumber}';
    return _cachedAppVersion!;
  }

  static Future<Map<String, String>> _headers() async {
    final trace = PerfDiagnostics.startTrace('campaign_service._headers');
    final session = await trace.measureAsync(
      'AuthService.restoreSession',
      AuthService.restoreSession,
    );
    final token = AuthService.sessionToken;
    if (session == null || token == null) {
      trace.finish(data: {'authorized': false});
      throw const AppCampaignUnauthorizedException('No hay sesión activa');
    }

    trace.finish(data: {'authorized': true});
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static bool _looksUnauthorized(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('401') ||
        normalized.contains('sin autorización') ||
        normalized.contains('sin autorizacion') ||
        normalized.contains('sesión inválida') ||
        normalized.contains('sesion invalida') ||
        normalized.contains('token inválido') ||
        normalized.contains('token invalido');
  }

  static Future<Map<String, dynamic>> _post(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _supabase.functions.invoke(
        functionName,
        body: body,
        headers: await _headers(),
      );

      final data = response.data;
      if (data is Map && data['ok'] == false) {
        final message = (data['message'] as String?) ?? 'Error desconocido';
        if (_looksUnauthorized(message)) {
          await AuthService.signOut();
          throw AppCampaignUnauthorizedException(message);
        }
        throw AppCampaignException(message);
      }

      if (data is Map<String, dynamic>) {
        return data;
      }

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      throw const AppCampaignException('Respuesta inválida del servidor');
    } on AppCampaignException {
      rethrow;
    } catch (error, stack) {
      _logError('_post/$functionName', error, stack);
      final message = error.toString();
      if (_looksUnauthorized(message)) {
        await AuthService.signOut();
        throw AppCampaignUnauthorizedException(message);
      }
      throw AppCampaignException(message);
    }
  }

  static Future<List<AppCampaign>> listCampaigns({
    required String screen,
    bool forceRefresh = false,
  }) async {
    final cacheKey = await _buildCacheKey(screen);
    final trace = PerfDiagnostics.startTrace(
      'campaign_service.listCampaigns',
      context: {'screen': screen, 'forceRefresh': forceRefresh},
    );
    final cachedEntry = _campaignCache[cacheKey];
    final cacheAge = cachedEntry == null
        ? null
        : DateTime.now().difference(cachedEntry.createdAt);
    if (!forceRefresh &&
        cachedEntry != null &&
        cacheAge != null &&
        cacheAge <= _campaignCacheTtl) {
      trace.finish(
        data: {
          'screen': screen,
          'source': 'memory_cache',
          'count': cachedEntry.campaigns.length,
          'cacheAgeMs': cacheAge.inMilliseconds,
        },
      );
      return List<AppCampaign>.from(cachedEntry.campaigns);
    }

    final data = await trace.measureAsync('functions_invoke_app-campaigns-list', () async {
      return _post('app-campaigns-list', {
        'screen': screen,
        'appVersion': await getAppVersion(),
      });
    });

    final rawCampaigns = data['campaigns'] as List<dynamic>? ?? const [];
    final campaigns = rawCampaigns
        .whereType<Map>()
        .map((raw) => AppCampaign.fromMap(Map<String, dynamic>.from(raw)))
        .toList();
    _campaignCache[cacheKey] = _CampaignCacheEntry(
      campaigns: List<AppCampaign>.from(campaigns),
      createdAt: DateTime.now(),
    );
    trace.finish(data: {'count': campaigns.length, 'screen': screen, 'source': 'remote'});
    return List<AppCampaign>.from(campaigns);
  }

  static Future<void> ackCampaign({
    required int campaignId,
    required String action,
  }) async {
    await _post('app-campaigns-ack', {
      'campaignId': campaignId,
      'action': action,
    });
    _campaignCache.clear();
  }

  static Future<String> _buildCacheKey(String screen) async {
    final userId = AuthService.currentUserId ?? 'unknown';
    return '$userId|${await getAppVersion()}|${screen.trim().toLowerCase()}';
  }
}

class _CampaignCacheEntry {
  final List<AppCampaign> campaigns;
  final DateTime createdAt;

  const _CampaignCacheEntry({
    required this.campaigns,
    required this.createdAt,
  });
}
