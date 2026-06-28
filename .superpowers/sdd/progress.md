# CCCD Scanner — Progress Ledger

Branch: feat/cccd-scanner
Flutter: 3.44.4 / Dart 3.12.2 (bin: C:\Users\ADMIN\Downloads\flutter_windows_3.44.4-stable\flutter\bin)

- Bootstrap: complete (flutter create + deps + git init, branch feat/cccd-scanner)

- Tasks 1-8 (logic core): complete. 22/22 tests pass, analyze clean.
  Files: models/cccd_data, models/pending_record, core/date_utils, core/cccd_validator,
  core/qr_parser, core/hometown_extractor, core/full_ocr_parser, services/offline_queue.

- Tasks 9-13 (services): complete (analyze clean, no device tests possible yet).
  NOTE: real package versions newer than plan -> google_sign_in 7.2.0 (NEW API:
  initialize/authenticate/authorizeScopes), connectivity_plus 7.2.0, mobile_scanner 7.2.0,
  extension 3.0.0. auth_service rewritten for 7.x. Added googleapis_auth direct dep.
  Files: auth_service, sheets_service, ocr_service, capture_service, sync_service.

- Tasks 14-17 (UI + wiring): complete. analyze clean, 22/22 tests pass.
  Files: screens/login, screens/capture, screens/review, widgets/card_frame_overlay, main.dart.
  Platform config: Android minSdk=23 + CAMERA/INTERNET perms; iOS camera+photo plist keys.
  Adapted: mobile_scanner 7.x onDetect kept; avoided firstOrNull.
  docs/superpowers/notes/google-setup.md added.
  PENDING (needs user): Android SDK (Android Studio), Google Cloud OAuth, kSpreadsheetId/kServerClientId, device test.
