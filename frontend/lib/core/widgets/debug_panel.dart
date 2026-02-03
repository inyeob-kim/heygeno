import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/device_uid_service.dart';
import '../storage/secure_storage.dart';
import '../storage/storage_keys.dart';
import '../../features/home/presentation/controllers/home_controller.dart';
import '../../app/router/route_paths.dart';

/// 디버그 패널 (디버그 빌드에서만 표시)
class DebugPanel extends ConsumerStatefulWidget {
  const DebugPanel({super.key});

  @override
  ConsumerState<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends ConsumerState<DebugPanel> {
  String? _deviceUid;
  String? _userId;
  bool? _onboardingCompleted;
  String? _primaryPetId;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    if (!kDebugMode) return;

    final deviceUid = await DeviceUidService.get();
    final onboardingCompleted = await SecureStorage.read(StorageKeys.onboardingCompleted);
    final primaryPetId = await SecureStorage.read(StorageKeys.primaryPetId);
    
    final homeState = ref.read(homeControllerProvider);
    final userId = homeState.petSummary?.petId; // TODO: 실제 userId는 서버 응답에서 가져와야 함

    setState(() {
      _deviceUid = deviceUid;
      _userId = userId;
      _onboardingCompleted = onboardingCompleted == 'true';
      _primaryPetId = primaryPetId;
    });
  }

  Future<void> _resetUid() async {
    if (!kDebugMode) return;
    
    await DeviceUidService.reset();
    await _loadDebugInfo();
    
    if (mounted) {
      context.go(RoutePaths.onboarding);
    }
  }

  Future<void> _resetOnboarding() async {
    if (!kDebugMode) return;
    
    await SecureStorage.delete(StorageKeys.onboardingCompleted);
    await SecureStorage.delete(StorageKeys.draftNickname);
    await SecureStorage.delete(StorageKeys.draftPetProfile);
    await SecureStorage.delete(StorageKeys.primaryPetId);
    await SecureStorage.delete(StorageKeys.primaryPetSummary);
    
    await _loadDebugInfo();
    
    if (mounted) {
      context.go(RoutePaths.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔧 Debug Panel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          _buildDebugRow('UID', _deviceUid?.substring(0, 8) ?? 'N/A'),
          _buildDebugRow('UserID', _userId ?? 'N/A'),
          _buildDebugRow('Onboarding', _onboardingCompleted?.toString() ?? 'N/A'),
          _buildDebugRow('PetID', _primaryPetId?.substring(0, 8) ?? 'N/A'),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _resetUid,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Reset UID',
                    style: TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: _resetOnboarding,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Reset Onboarding',
                    style: TextStyle(fontSize: 10, color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 9, color: Colors.white70),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 9, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
