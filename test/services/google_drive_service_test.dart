import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_asistencia/services/google_drive_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockAuthClient extends Mock implements AuthClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGoogleSignIn mockSignIn;
  late MockGoogleSignInAccount mockAccount;
  late MockAuthClient mockAuthClient;

  setUpAll(() {
    registerFallbackValue(http.Request('GET', Uri.parse('http://example.com')));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    mockSignIn = MockGoogleSignIn();
    mockAccount = MockGoogleSignInAccount();
    mockAuthClient = MockAuthClient();

    GoogleDriveService.mockGoogleSignIn = mockSignIn;
  });

  tearDown(() {
    GoogleDriveService.mockGoogleSignIn = null;
  });

  group('GoogleDriveService - Authentication', () {
    test('signIn returns account on success', () async {
      when(() => mockSignIn.currentUser).thenReturn(null);
      when(() => mockSignIn.signIn()).thenAnswer((_) async => mockAccount);

      final account = await GoogleDriveService.signIn();

      expect(account, isNotNull);
      verify(() => mockSignIn.signIn()).called(1);
    });

    test('signIn returns existing currentUser if already signed in', () async {
      when(() => mockSignIn.currentUser).thenReturn(mockAccount);

      final account = await GoogleDriveService.signIn();

      expect(account, isNotNull);
      verifyNever(() => mockSignIn.signIn());
    });

    test('signInSilently returns account on success', () async {
      when(() => mockSignIn.signInSilently()).thenAnswer((_) async => mockAccount);

      final account = await GoogleDriveService.signInSilently();

      expect(account, isNotNull);
      verify(() => mockSignIn.signInSilently()).called(1);
    });

    test('signOut calls disconnect', () async {
      when(() => mockSignIn.disconnect()).thenAnswer((_) async => mockAccount);

      await GoogleDriveService.signOut();

      verify(() => mockSignIn.disconnect()).called(1);
    });
  });

  group('GoogleDriveService - Google Drive', () {
    test('createFolder returns null when not authenticated', () async {
      when(() => mockSignIn.currentUser).thenReturn(null);
      when(() => mockSignIn.signIn()).thenAnswer((_) async => null);

      final result = await GoogleDriveService.createFolder('New Folder');
      expect(result, isNull);
    });

    test('uploadPhoto returns false when not authenticated', () async {
      when(() => mockSignIn.signInSilently()).thenAnswer((_) async => null);
      when(() => mockSignIn.currentUser).thenReturn(null);
      when(() => mockSignIn.signIn()).thenAnswer((_) async => null);

      final result = await GoogleDriveService.uploadPhoto('folder_id', 'base64_data', 'photo.jpg');
      expect(result, isFalse);
    });
  });

  group('GoogleDriveService - Drive Folder Preferences', () {
    test('setDriveFolder and getDriveFolderId/Name', () async {
      // Act
      await GoogleDriveService.setDriveFolder('folder_id_123', 'My QR Folder');

      final folderId = await GoogleDriveService.getDriveFolderId();
      final folderName = await GoogleDriveService.getDriveFolderName();

      // Assert
      expect(folderId, 'folder_id_123');
      expect(folderName, 'My QR Folder');
    });

    test('clearDriveFolder', () async {
      // Arrange
      await GoogleDriveService.setDriveFolder('folder_id_123', 'My QR Folder');

      // Act
      await GoogleDriveService.clearDriveFolder();

      final folderId = await GoogleDriveService.getDriveFolderId();
      final folderName = await GoogleDriveService.getDriveFolderName();

      // Assert
      expect(folderId, isNull);
      expect(folderName, isNull);
    });
  });

  group('GoogleDriveService - Sheets Info Preferences', () {
    test('setSheetsInfo and getSheetsId/Info', () async {
      // Act
      await GoogleDriveService.setSheetsInfo(
        'sheet_id_456',
        'My Attendance Sheet',
        'https://docs.google.com/spreadsheets/d/sheet_id_456'
      );

      final sheetId = await GoogleDriveService.getSheetsId();
      final sheetInfo = await GoogleDriveService.getSheetsInfo();

      // Assert
      expect(sheetId, 'sheet_id_456');
      expect(sheetInfo, isNotNull);
      expect(sheetInfo!['id'], 'sheet_id_456');
      expect(sheetInfo['name'], 'My Attendance Sheet');
      expect(sheetInfo['url'], 'https://docs.google.com/spreadsheets/d/sheet_id_456');
      expect(sheetInfo['autoSync'], isTrue); // Auto-sync is true by default when linked
    });

    test('getSheetsInfo returns default name if not set but id exists', () async {
      // Arrange - Only set the ID directly via SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sheets_spreadsheet_id', 'sheet_id_only');

      // Act
      final sheetInfo = await GoogleDriveService.getSheetsInfo();

      // Assert
      expect(sheetInfo, isNotNull);
      expect(sheetInfo!['id'], 'sheet_id_only');
      expect(sheetInfo['name'], 'Hoja de Asistencia'); // Default name
      expect(sheetInfo['url'], ''); // Default url
      expect(sheetInfo['autoSync'], isFalse); // Default autoSync
    });

    test('getSheetsInfo returns null if id is not set', () async {
      // Act
      final sheetInfo = await GoogleDriveService.getSheetsInfo();

      // Assert
      expect(sheetInfo, isNull);
    });

    test('clearSheetsInfo', () async {
      // Arrange
      await GoogleDriveService.setSheetsInfo(
        'sheet_id_456',
        'My Attendance Sheet',
        'https://docs.google.com/spreadsheets/d/sheet_id_456'
      );

      // Act
      await GoogleDriveService.clearSheetsInfo();

      final sheetId = await GoogleDriveService.getSheetsId();
      final sheetInfo = await GoogleDriveService.getSheetsInfo();
      final isAutoSync = await GoogleDriveService.isAutoSyncEnabled();

      // Assert
      expect(sheetId, isNull);
      expect(sheetInfo, isNull);
      expect(isAutoSync, isFalse); // Defaults to false
    });
  });

  group('GoogleDriveService - Auto Sync Preferences', () {
    test('setAutoSync and isAutoSyncEnabled', () async {
      // Default should be false
      expect(await GoogleDriveService.isAutoSyncEnabled(), isFalse);

      // Act
      await GoogleDriveService.setAutoSync(true);

      // Assert
      expect(await GoogleDriveService.isAutoSyncEnabled(), isTrue);

      // Act
      await GoogleDriveService.setAutoSync(false);

      // Assert
      expect(await GoogleDriveService.isAutoSyncEnabled(), isFalse);
    });
  });
}
