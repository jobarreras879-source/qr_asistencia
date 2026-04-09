import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/app_campaign.dart';
import '../services/app_campaign_service.dart';
import '../services/app_feedback_service.dart';
import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../services/campaign_coordinator.dart';
import '../services/project_service.dart';
import '../theme/app_theme.dart';
import '../utils/perf_diagnostics.dart';
import '../widgets/campaign_banner_card.dart';
import '../widgets/campaign_modal_dialog.dart';
import '../widgets/campaign_tooltip_overlay.dart';
import '../widgets/home/home_actions_section.dart';
import '../widgets/home/home_cta.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/home_project_section.dart';
import '../widgets/home/home_stats_grid.dart';
import 'drive_config_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'project_management_screen.dart';
import 'qr_scanner_screen.dart';
import 'sheets_config_screen.dart';
import 'user_management_screen.dart';

class HomeScreen extends StatefulWidget {
  final String usuario;
  final String rol;

  const HomeScreen({super.key, required this.usuario, required this.rol});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const _targetScanAction = 'home_scan_action';
  static const _targetProjectSelector = 'home_project_selector';
  static const _targetAdminProjects = 'home_admin_projects';
  static const _targetAdminDrive = 'home_admin_drive';
  static const _targetAdminSheets = 'home_admin_sheets';
  static const _targetHistory = 'home_history';
  static const _targetAdminUsers = 'home_admin_users';
  static const _targetLogout = 'home_logout';
  static const _connectivityCheckInterval = Duration(seconds: 45);
  static const _connectivityLookupTimeout = Duration(seconds: 3);
  static const _resumeReloadCooldown = Duration(seconds: 45);
  static const _campaignReloadCooldown = Duration(seconds: 30);

  bool _hasInternet = false;
  List<Map<String, dynamic>> _proyectos = [];
  Map<String, dynamic>? _proyectoSeleccionado;
  late String _usuario;
  late String _rol;

  int _registrosHoy = 0;
  int _proyectosActivos = 0;

  Timer? _connectivityTimer;
  bool _isCheckingInternet = false;
  bool _isLoadingHomeData = false;
  bool _isLoadingCampaigns = false;
  bool _campaignFlowActive = false;
  bool _isShowingModal = false;

  AppCampaign? _bannerCampaign;
  Map<String, AppCampaign> _badgeCampaigns = const {};
  List<AppCampaign> _tooltipSequence = const [];
  int _activeTooltipIndex = 0;
  Rect? _activeTooltipRect;
  final Set<int> _ackedSeenTooltipIds = <int>{};
  int _homeLoadSequence = 0;
  DateTime? _lastHomeLoadCompletedAt;
  DateTime? _lastCampaignLoadCompletedAt;

  late final Map<String, GlobalKey> _campaignTargetKeys = {
    _targetScanAction: GlobalKey(debugLabel: _targetScanAction),
    _targetProjectSelector: GlobalKey(debugLabel: _targetProjectSelector),
    _targetAdminProjects: GlobalKey(debugLabel: _targetAdminProjects),
    _targetAdminDrive: GlobalKey(debugLabel: _targetAdminDrive),
    _targetAdminSheets: GlobalKey(debugLabel: _targetAdminSheets),
    _targetHistory: GlobalKey(debugLabel: _targetHistory),
    _targetAdminUsers: GlobalKey(debugLabel: _targetAdminUsers),
    _targetLogout: GlobalKey(debugLabel: _targetLogout),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _usuario = widget.usuario;
    _rol = widget.rol;
    PerfDiagnostics.log(
      'home_screen',
      'init_state',
      data: {
        'usuario': _usuario,
        'rol': _rol,
        'sinceAppStartMs': PerfDiagnostics.appStart.elapsedMilliseconds,
      },
    );

    _startConnectivityMonitoring();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      PerfDiagnostics.log(
        'home_screen',
        'shell_first_frame',
        data: {'sinceAppStartMs': PerfDiagnostics.appStart.elapsedMilliseconds},
      );
    });
    unawaited(_loadHomeData(reason: 'startup'));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivityTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      PerfDiagnostics.log('home_screen', 'app_resumed');
      if (_isFreshWithin(_lastHomeLoadCompletedAt, _resumeReloadCooldown)) {
        PerfDiagnostics.log(
          'home_screen',
          'resume_reload_skipped',
          data: {
            'lastLoadMsAgo': DateTime.now()
                .difference(_lastHomeLoadCompletedAt!)
                .inMilliseconds,
          },
        );
        return;
      }
      unawaited(_loadHomeData(reason: 'resume'));
    }
  }

  bool get _isAdmin => _rol.toUpperCase() == 'ADMIN';

  AppCampaign? get _activeTooltipCampaign {
    if (_tooltipSequence.isEmpty) return null;
    if (_activeTooltipIndex < 0 || _activeTooltipIndex >= _tooltipSequence.length) {
      return null;
    }
    return _tooltipSequence[_activeTooltipIndex];
  }

  void _startConnectivityMonitoring() {
    _checkInternetConnection();
    _connectivityTimer = Timer.periodic(
      _connectivityCheckInterval,
      (_) => _checkInternetConnection(),
    );
  }

  Future<void> _checkInternetConnection() async {
    if (_isCheckingInternet) return;
    _isCheckingInternet = true;
    final stopwatch = Stopwatch()..start();
    var hasInternet = false;
    try {
      final result = await InternetAddress.lookup(
        'example.com',
      ).timeout(_connectivityLookupTimeout);
      hasInternet = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      hasInternet = false;
    } catch (_) {
      hasInternet = false;
    } finally {
      _isCheckingInternet = false;
    }

    final changed = _hasInternet != hasInternet;
    if (PerfDiagnostics.enabled && (changed || stopwatch.elapsedMilliseconds >= 250)) {
      PerfDiagnostics.log(
        'home_connectivity',
        'lookup_complete',
        data: {
          'online': hasInternet,
          'changed': changed,
          'ms': stopwatch.elapsedMilliseconds,
        },
      );
    }

    if (!mounted || _hasInternet == hasInternet) return;
    setState(() {
      _hasInternet = hasInternet;
    });
  }

  Future<void> _loadHomeData({required String reason}) async {
    final trace = PerfDiagnostics.startTrace(
      'home_load_data',
      context: {
        'reason': reason,
        'sequence': ++_homeLoadSequence,
      },
    );
    if (_isLoadingHomeData) {
      trace.finish(data: {'reason': reason, 'skipped': 'already_loading'});
      return;
    }
    _isLoadingHomeData = true;

    try {
      final hasSession = await trace.measureAsync(
        '_refreshSession',
        _refreshSession,
      );
      if (!mounted || !hasSession) {
        trace.finish(data: {'reason': reason, 'hasSession': hasSession});
        return;
      }

      final shouldRefreshData =
          reason != 'resume' || !_isFreshWithin(_lastHomeLoadCompletedAt, _resumeReloadCooldown);
      final shouldRefreshCampaigns =
          reason != 'resume' || !_isFreshWithin(_lastCampaignLoadCompletedAt, _campaignReloadCooldown);

      if (!shouldRefreshData && !shouldRefreshCampaigns) {
        trace.finish(
          data: {
            'reason': reason,
            'hasSession': hasSession,
            'skipped': 'fresh_data',
          },
        );
        return;
      }

      await trace.measureAsync('parallel_fetch_home_data', () async {
        await Future.wait([
          if (shouldRefreshData) _fetchData(reason: reason),
          if (shouldRefreshCampaigns) _loadCampaigns(reason: reason),
        ]);
      });

      _lastHomeLoadCompletedAt = DateTime.now();
      trace.mark(
        'home_data_completed',
        data: {
          'reason': reason,
          'refreshedData': shouldRefreshData,
          'refreshedCampaigns': shouldRefreshCampaigns,
        },
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        trace.mark(
          'first_useful_frame',
          data: {'sinceAppStartMs': PerfDiagnostics.appStart.elapsedMilliseconds},
        );
        trace.finish(
          data: {
            'reason': reason,
            'hasSession': hasSession,
            'refreshedData': shouldRefreshData,
            'refreshedCampaigns': shouldRefreshCampaigns,
          },
        );
      });
    } finally {
      _isLoadingHomeData = false;
    }
  }

  Future<void> _fetchData({required String reason}) async {
    final trace = PerfDiagnostics.startTrace(
      'home_fetch_data',
      context: {'reason': reason, 'usuario': _usuario},
    );
    final forceProjectRefresh = reason == 'return_from_projects';

    final proyectosFuture = trace.measureAsync(
      'ProjectService.getProyectos',
      () => ProjectService.getProyectos(forceRefresh: forceProjectRefresh),
    );
    final registrosHoyFuture = trace.measureAsync(
      'AttendanceService.getTodayCount',
      () => AttendanceService.getTodayCount(_usuario),
    );

    final proys = await proyectosFuture;
    final registrosHoy = await registrosHoyFuture;

    if (!mounted) {
      trace.finish(data: {'reason': reason, 'mounted': false});
      return;
    }

    final selectedNumber = _proyectoSeleccionado?['numero']?.toString();
    Map<String, dynamic>? proyectoSeleccionado;

    if (selectedNumber != null) {
      for (final proyecto in proys) {
        if (proyecto['numero']?.toString() == selectedNumber) {
          proyectoSeleccionado = Map<String, dynamic>.from(proyecto);
          break;
        }
      }
    }

    trace.mark(
      'before_set_state',
      data: {
        'reason': reason,
        'projectCount': proys.length,
        'registrosHoy': registrosHoy,
      },
    );
    setState(() {
      _proyectos = proys;
      _proyectosActivos = proys.length;
      _registrosHoy = registrosHoy;
      _proyectoSeleccionado = proyectoSeleccionado;
    });
    trace.mark('after_set_state', data: {'reason': reason});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      trace.mark('post_fetch_frame', data: {'reason': reason});
      trace.finish(
        data: {
          'reason': reason,
          'projectCount': proys.length,
          'registrosHoy': registrosHoy,
        },
      );
    });
  }

  Future<bool> _refreshSession() async {
    final trace = PerfDiagnostics.startTrace('home_refresh_session');
    final session = await trace.measureAsync(
      'AuthService.restoreSession',
      AuthService.restoreSession,
    );
    if (!mounted) return false;

    if (session == null) {
      trace.finish(data: {'hasSession': false});
      _redirectToLogin();
      return false;
    }

    final nextUsuario = session['usuario']!;
    final nextRol = session['rol']!;
    final sessionChanged = _usuario != nextUsuario || _rol != nextRol;
    if (sessionChanged) {
      trace.mark(
        'before_set_state',
        data: {'usuario': nextUsuario, 'rol': nextRol},
      );
      setState(() {
        _usuario = nextUsuario;
        _rol = nextRol;
      });
      trace.mark('after_set_state');
    }
    trace.finish(
      data: {
        'hasSession': true,
        'rol': nextRol,
        'sessionChanged': sessionChanged,
      },
    );

    return true;
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _loadCampaigns({required String reason}) async {
    final trace = PerfDiagnostics.startTrace(
      'home_load_campaigns',
      context: {'reason': reason},
    );
    if (_isLoadingCampaigns) {
      trace.finish(data: {'reason': reason, 'skipped': 'already_loading'});
      return;
    }
    _isLoadingCampaigns = true;
    final result = <String, Object?>{'reason': reason};

    try {
      final campaigns = await trace.measureAsync(
        'AppCampaignService.listCampaigns',
        () => AppCampaignService.listCampaigns(screen: 'home'),
      );
      if (!mounted) {
        result['mounted'] = false;
        return;
      }

      final snapshot = CampaignCoordinator.build(campaigns);
      trace.mark(
        'before_set_state',
        data: {
          'reason': reason,
          'campaignCount': campaigns.length,
          'hasModal': snapshot.modal != null,
          'hasBanner': snapshot.banner != null,
          'tooltipCount': snapshot.tooltips.length,
          'badgeCount': snapshot.badges.length,
        },
      );
      setState(() {
        _bannerCampaign = snapshot.banner;
        _badgeCampaigns = snapshot.badges;

        if (!_campaignFlowActive) {
          _tooltipSequence = const [];
          _activeTooltipIndex = 0;
          _activeTooltipRect = null;
          _ackedSeenTooltipIds.clear();
        }
      });
      trace.mark('after_set_state', data: {'reason': reason});
      result['campaignCount'] = campaigns.length;
      result['hasModal'] = snapshot.modal != null;
      result['hasBanner'] = snapshot.banner != null;
      result['tooltipCount'] = snapshot.tooltips.length;
      result['badgeCount'] = snapshot.badges.length;
      _lastCampaignLoadCompletedAt = DateTime.now();

      await _maybeStartCampaignFlow(snapshot, reason: reason);
    } on AppCampaignUnauthorizedException {
      result['unauthorized'] = true;
      if (!mounted) return;
      _redirectToLogin();
    } catch (error, stack) {
      debugPrint('❌ HomeScreen campaign load failed: $error');
      debugPrint(stack.toString());
      result['error'] = error.toString();
    } finally {
      _isLoadingCampaigns = false;
      result['loadingFlagCleared'] = true;
      trace.finish(data: result);
    }
  }

  bool _isFreshWithin(DateTime? timestamp, Duration ttl) {
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) <= ttl;
  }

  Future<void> _maybeStartCampaignFlow(
    CampaignCoordinatorSnapshot snapshot, {
    required String reason,
  }) async {
    final trace = PerfDiagnostics.startTrace(
      'home_maybe_start_campaign_flow',
      context: {
        'reason': reason,
        'hasModal': snapshot.modal != null,
        'tooltipCount': snapshot.tooltips.length,
        'flowActive': _campaignFlowActive,
        'showingModal': _isShowingModal,
      },
    );
    if (!mounted || _campaignFlowActive || _isShowingModal) {
      trace.finish(data: {'reason': reason, 'skipped': true});
      return;
    }

    if (snapshot.modal != null) {
      trace.finish(data: {'reason': reason, 'action': 'show_modal'});
      await _showCampaignModal(snapshot.modal!);
      return;
    }

    if (snapshot.tooltips.isNotEmpty) {
      trace.finish(
        data: {
          'reason': reason,
          'action': 'start_tooltips',
          'tooltipCount': snapshot.tooltips.length,
        },
      );
      _startTooltipSequence(snapshot.tooltips);
      return;
    }

    trace.finish(data: {'reason': reason, 'action': 'none'});
  }

  Future<void> _showCampaignModal(AppCampaign campaign) async {
    _campaignFlowActive = true;
    _isShowingModal = true;
    await _safeAckCampaign(campaign.id, 'seen');
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return CampaignModalDialog(
          campaign: campaign,
          onDismiss: () async {
            await _safeAckCampaign(campaign.id, 'dismissed');
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          },
          onAction: campaign.hasCta
              ? () async {
                  await _safeAckCampaign(campaign.id, 'clicked');
                  final handled = await _handleCampaignRoute(campaign.ctaRoute);
                  if (handled) {
                    await _safeAckCampaign(campaign.id, 'completed');
                  }
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                }
              : null,
        );
      },
    );

    _campaignFlowActive = false;
    _isShowingModal = false;
    if (mounted) {
      await _loadCampaigns(reason: 'modal_closed');
    }
  }

  void _startTooltipSequence(List<AppCampaign> tooltips) {
    if (tooltips.isEmpty) return;

    setState(() {
      _campaignFlowActive = true;
      _tooltipSequence = tooltips;
      _activeTooltipIndex = 0;
      _activeTooltipRect = null;
      _ackedSeenTooltipIds.clear();
    });

    unawaited(_markCurrentTooltipSeen());
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveActiveTooltipRect());
  }

  Future<void> _markCurrentTooltipSeen() async {
    final campaign = _activeTooltipCampaign;
    if (campaign == null || _ackedSeenTooltipIds.contains(campaign.id)) return;
    _ackedSeenTooltipIds.add(campaign.id);
    await _safeAckCampaign(campaign.id, 'seen');
  }

  void _resolveActiveTooltipRect() {
    if (!mounted) return;

    final campaign = _activeTooltipCampaign;
    final targetKey = campaign?.targetKey;
    final key = targetKey == null ? null : _campaignTargetKeys[targetKey];
    final targetContext = key?.currentContext;
    final renderObject = targetContext?.findRenderObject();

    Rect? rect;
    if (renderObject is RenderBox && renderObject.attached) {
      final offset = renderObject.localToGlobal(Offset.zero);
      rect = offset & renderObject.size;
    }

    if (!mounted) return;
    setState(() {
      _activeTooltipRect = rect;
    });
  }

  Future<void> _handleTooltipNext() async {
    final current = _activeTooltipCampaign;
    if (current == null) return;

    final isLast = _activeTooltipIndex >= _tooltipSequence.length - 1;
    if (isLast) {
      await _safeAckCampaign(current.id, 'completed');
      await _finishTooltipSequence();
      return;
    }

    setState(() {
      _activeTooltipIndex += 1;
      _activeTooltipRect = null;
    });

    await _markCurrentTooltipSeen();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveActiveTooltipRect());
  }

  Future<void> _handleTooltipSkip() async {
    final remaining = _tooltipSequence.skip(_activeTooltipIndex).toList();
    for (final campaign in remaining) {
      await _safeAckCampaign(campaign.id, 'dismissed');
    }
    await _finishTooltipSequence();
  }

  Future<void> _finishTooltipSequence() async {
    if (!mounted) return;
    setState(() {
      _campaignFlowActive = false;
      _tooltipSequence = const [];
      _activeTooltipIndex = 0;
      _activeTooltipRect = null;
      _ackedSeenTooltipIds.clear();
    });
    await _loadCampaigns(reason: 'tooltip_finished');
  }

  Future<void> _dismissBanner(AppCampaign campaign) async {
    await _safeAckCampaign(campaign.id, 'dismissed');
    if (!mounted) return;
    setState(() {
      _bannerCampaign = null;
    });
    await _loadCampaigns(reason: 'banner_dismissed');
  }

  Future<void> _handleBannerAction(AppCampaign campaign) async {
    await _safeAckCampaign(campaign.id, 'clicked');
    final handled = await _handleCampaignRoute(campaign.ctaRoute);
    if (handled) {
      await _safeAckCampaign(campaign.id, 'completed');
    }
    await _loadCampaigns(reason: 'banner_action');
  }

  Future<void> _safeAckCampaign(int campaignId, String action) async {
    try {
      await AppCampaignService.ackCampaign(campaignId: campaignId, action: action);
    } on AppCampaignUnauthorizedException {
      if (!mounted) return;
      _redirectToLogin();
    } catch (error, stack) {
      debugPrint('❌ HomeScreen campaign ack failed: $error');
      debugPrint(stack.toString());
    }
  }

  Future<bool> _handleCampaignRoute(String? route) async {
    final normalizedRoute = (route ?? '').trim().toLowerCase();
    if (normalizedRoute.isEmpty) return false;

    switch (normalizedRoute) {
      case _targetProjectSelector:
        return _scrollToCampaignTarget(_targetProjectSelector);
      case _targetScanAction:
        _iniciarRegistro();
        return true;
      case _targetAdminProjects:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProjectManagementScreen()),
        );
        if (mounted) await _fetchData(reason: 'return_from_projects');
        return true;
      case _targetAdminDrive:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DriveConfigScreen()),
        );
        return true;
      case _targetAdminSheets:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SheetsConfigScreen()),
        );
        return true;
      case _targetHistory:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HistoryScreen()),
        );
        return true;
      case _targetAdminUsers:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserManagementScreen()),
        );
        return true;
      case _targetLogout:
        await _logout();
        return true;
      default:
        return false;
    }
  }

  Future<bool> _scrollToCampaignTarget(String targetKey) async {
    final targetContext = _campaignTargetKeys[targetKey]?.currentContext;
    if (targetContext == null) return false;

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.25,
    );
    return true;
  }

  void _iniciarRegistro() {
    final proyecto = _proyectoSeleccionado;
    if (proyecto == null) {
      AppFeedbackService.showSnackBar(
        context,
        'Selecciona un proyecto primero',
        type: AppFeedbackType.warning,
      );
      return;
    }

    final numero = proyecto['numero']?.toString() ?? '';
    final nombre = proyecto['nombre']?.toString() ?? '';
    final cliente = proyecto['cliente']?.toString() ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRScannerScreen(
          usuario: _usuario,
          rol: _rol,
          projectNumber: numero,
          projectName: nombre,
          projectClient: cliente,
          tipo: 'Proyecto',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTooltip = _activeTooltipCampaign;
    final actions = _buildActionItems();
    final badgeTargets = _badgeCampaigns.keys.toSet();
    final badgeCounts = _badgeCampaigns.map(
      (key, campaign) => MapEntry(key, campaign.badgeCount),
    );
    final selectedProjectNumber = _proyectoSeleccionado?['numero']?.toString();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                HomeHeader(usuario: _usuario, rol: _rol),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_bannerCampaign != null) ...[
                          CampaignBannerCard(
                            campaign: _bannerCampaign!,
                            onDismiss: () => _dismissBanner(_bannerCampaign!),
                            onAction: _bannerCampaign!.hasCta
                                ? () => _handleBannerAction(_bannerCampaign!)
                                : null,
                          ),
                          const SizedBox(height: 18),
                        ],
                        HomeStatsGrid(
                          registrosHoy: _registrosHoy,
                          proyectosActivos: _proyectosActivos,
                        ),
                        const SizedBox(height: 18),
                        HomeProjectSection(
                          selectorKey: _campaignTargetKeys[_targetProjectSelector],
                          projects: _proyectos,
                          selectedValue: selectedProjectNumber,
                          onChanged: _handleProjectChanged,
                          labelBuilder: _projectDropdownLabel,
                          showBadge: badgeTargets.contains(_targetProjectSelector),
                          badgeCount: badgeCounts[_targetProjectSelector],
                        ),
                        const SizedBox(height: 18),
                        HomeActionsSection(
                          actions: actions,
                          targetKeys: _campaignTargetKeys,
                          badgeTargets: badgeTargets,
                          badgeCounts: badgeCounts,
                        ),
                      ],
                    ),
                  ),
                ),
                HomeCta(
                  buttonKey: _campaignTargetKeys[_targetScanAction],
                  enabled: _proyectoSeleccionado != null,
                  onPressed: _iniciarRegistro,
                  showBadge: badgeTargets.contains(_targetScanAction),
                  badgeCount: badgeCounts[_targetScanAction],
                ),
              ],
            ),
          ),
          if (activeTooltip != null)
            CampaignTooltipOverlay(
              campaign: activeTooltip,
              targetRect: _activeTooltipRect,
              currentStep: _activeTooltipIndex + 1,
              totalSteps: _tooltipSequence.length,
              isLastStep: _activeTooltipIndex == _tooltipSequence.length - 1,
              onNext: _handleTooltipNext,
              onSkip: _handleTooltipSkip,
            ),
        ],
      ),
    );
  }

  void _handleProjectChanged(String? value) {
    if (value == null) return;
    Map<String, dynamic>? project;
    for (final item in _proyectos) {
      if (item['numero']?.toString() == value) {
        project = Map<String, dynamic>.from(item);
        break;
      }
    }
    setState(() {
      _proyectoSeleccionado = project;
    });
  }

  List<HomeActionItem> _buildActionItems() {
    return <HomeActionItem>[
      if (_isAdmin) ...[
        HomeActionItem(
          label: 'Proyectos',
          icon: Icons.folder_open_outlined,
          iconColor: AppTheme.primary,
          targetKey: _targetAdminProjects,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProjectManagementScreen(),
              ),
            );
            if (mounted) await _fetchData(reason: 'return_from_projects');
          },
        ),
        HomeActionItem(
          label: 'Drive',
          icon: Icons.cloud_outlined,
          iconColor: const Color(0xFF10A6D9),
          targetKey: _targetAdminDrive,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DriveConfigScreen()),
            );
          },
        ),
        HomeActionItem(
          label: 'Sheets',
          icon: Icons.grid_view_rounded,
          iconColor: const Color(0xFF19B99A),
          targetKey: _targetAdminSheets,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SheetsConfigScreen()),
            );
          },
        ),
        HomeActionItem(
          label: 'Historial',
          icon: Icons.history_rounded,
          iconColor: const Color(0xFFF39A21),
          targetKey: _targetHistory,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            );
          },
        ),
        HomeActionItem(
          label: 'Usuarios',
          icon: Icons.people_outline_rounded,
          iconColor: const Color(0xFF7A4DFF),
          targetKey: _targetAdminUsers,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserManagementScreen()),
            );
          },
        ),
      ] else
        HomeActionItem(
          label: 'Historial',
          icon: Icons.history_rounded,
          iconColor: const Color(0xFFF39A21),
          targetKey: _targetHistory,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            );
          },
        ),
      HomeActionItem(
        label: 'Salir',
        icon: Icons.logout_rounded,
        iconColor: const Color(0xFFEF4444),
        targetKey: _targetLogout,
        onTap: _logout,
      ),
    ];
  }

  String _projectDropdownLabel(Map<String, dynamic> proyecto) {
    final numero = proyecto['numero']?.toString() ?? '';
    final nombre = proyecto['nombre']?.toString() ?? '';
    if (nombre.isEmpty || nombre == 'Sin nombre') {
      return 'Proyecto #$numero';
    }
    return 'Proyecto #$numero - $nombre';
  }
}
