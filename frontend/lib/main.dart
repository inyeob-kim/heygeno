/*
코드 생성 명령어:
flutter pub run build_runner build --delete-conflicting-outputs

DTO 모델의 fromJson/toJson 메서드를 생성하기 위해 위 명령어를 실행하세요.
모델 파일을 수정한 후에는 반드시 다시 실행해야 합니다.
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // .env 파일 로드 (assets에서 로드)
  // pubspec.yaml에 .env 파일이 assets로 등록되어 있음
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("✓ .env file loaded successfully");
  } catch (e) {
    // .env 파일이 없으면 앱 실행 불가
    debugPrint("✗ Error loading .env file: $e");
    debugPrint("Please make sure .env file exists in frontend/ directory");
    rethrow; // .env 파일이 필수이므로 에러를 다시 던짐
  }
  
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
