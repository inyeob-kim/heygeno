import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 현재 선택된 반려동물 ID를 관리하는 프로바이더
/// 
/// @deprecated 이 Provider는 하위 호환성을 위해 유지되지만,
/// 새로운 코드는 `activePetContextProvider`를 사용하세요.
/// 
/// TODO: 실제로는 SharedPreferences나 로컬 DB에서 가져와야 함
@Deprecated('Use activePetContextProvider instead')
final currentPetIdProvider = StateProvider<String?>((ref) {
  // MVP에서는 null 반환 (나중에 실제 저장소에서 가져오도록 구현)
  return null;
});

