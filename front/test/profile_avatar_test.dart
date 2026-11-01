import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:front/core/services/http_service.dart';
import 'package:front/core/services/myself/models/myself_user_model.dart';
import 'package:front/core/services/myself/repositories/myself_repository.dart';
import 'package:front/core/services/myself/services/myself_service.dart';
import 'package:front/core/services/session/session_storage.dart';
import 'package:front/features/profile/data/models/avatar_image.dart';
import 'package:front/features/profile/data/models/change_password_model.dart';
import 'package:front/features/profile/data/models/update_user_model.dart';
import 'package:front/features/profile/data/repositories/profile_repository.dart';
import 'package:front/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:front/features/profile/data/services/avatar_image_picker.dart';
import 'package:front/features/profile/presentation/controllers/profile_controller.dart';
import 'package:front/features/profile/presentation/pages/user_data_page.dart';
import 'package:front/features/profile/presentation/widgets/editable_profile_avatar.dart';
import 'package:front/features/profile/presentation/widgets/profile_widgets.dart';

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAFElEQVR4nGP8f52BgYGBCUQwMAAAFzEB2pKCXKgAAAAASUVORK5CYII=',
);

MyselfUserModel _user({String? avatarUrl}) => MyselfUserModel(
  firstName: 'Maria',
  lastName: 'Silva',
  email: 'maria@example.com',
  cpf: '12345678901',
  userTypeId: 1,
  avatarUrl: avatarUrl,
);

class _Picker implements AvatarImagePicker {
  AvatarImage? image = AvatarImage.fromBytes(_png);
  AvatarImage? recovered;
  Object? error;
  AvatarSource? selectedSource;
  @override
  bool supportsCamera = true;
  @override
  Future<AvatarImage?> pick(AvatarSource source) async {
    selectedSource = source;
    if (error != null) throw error!;
    return image;
  }

  @override
  Future<AvatarImage?> recoverLostImage() async => recovered;
}

class _Repository implements ProfileRepository {
  int uploads = 0;
  int removals = 0;
  Object? error;
  Completer<MyselfUserModel>? pending;
  @override
  Future<MyselfUserModel> uploadAvatar({
    required int userId,
    required AvatarImage image,
  }) async {
    uploads++;
    if (error != null) throw error!;
    return pending?.future ??
        _user(avatarUrl: 'https://example.test/avatar.png');
  }

  @override
  Future<MyselfUserModel> removeAvatar({required int userId}) async {
    removals++;
    if (error != null) throw error!;
    return _user();
  }

  @override
  Future<void> changePassword({
    required int userId,
    required ChangePasswordModel payload,
  }) async {}
  @override
  Future<MyselfUserModel> updateUser({
    required int userId,
    required UpdateUserModel payload,
  }) async => _user();
}

class _MyselfRepository implements MyselfRepository {
  @override
  Future<MyselfUserModel> getUserById(int userId) async => _user();
}

Future<void> _mount(
  WidgetTester tester,
  _Picker picker,
  _Repository repository, {
  String? url,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EditableProfileAvatar(
          userId: 1,
          name: 'Maria Silva',
          avatarUrl: url,
          picker: picker,
          controller: ProfileController(repository),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _choose(
  WidgetTester tester, {
  String source = 'Escolher foto',
}) async {
  await tester.tap(find.byType(ProfileAvatar));
  await tester.pumpAndSettle();
  await tester.tap(find.text(source));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final myself = MyselfService(repository: _MyselfRepository());

  test('avatar URL is optional and parsed without breaking old profiles', () {
    expect(MyselfUserModel.fromJson({}).avatarUrl, isNull);
    expect(
      MyselfUserModel.fromJson({
        'avatar_url': '  https://example.test/a.png  ',
      }).avatarUrl,
      'https://example.test/a.png',
    );
  });

  test('selection checks size and supported signatures', () {
    expect(AvatarImage.fromBytes(_png).contentType, 'image/png');
    expect(
      () => AvatarImage.fromBytes(Uint8List(0)),
      throwsA(isA<AvatarSelectionException>()),
    );
    expect(
      () => AvatarImage.fromBytes(Uint8List(maxAvatarBytes + 1)),
      throwsA(isA<AvatarSelectionException>()),
    );
    expect(
      () => AvatarImage.fromBytes(Uint8List.fromList([71, 73, 70])),
      throwsA(isA<AvatarSelectionException>()),
    );
  });

  testWidgets('cancelling selection or preview does not upload', (
    tester,
  ) async {
    final picker = _Picker()..image = null;
    final repo = _Repository();
    await _mount(tester, picker, repo);
    await _choose(tester);
    expect(find.text('Confirmar foto de perfil'), findsNothing);
    expect(repo.uploads, 0);
    picker.image = AvatarImage.fromBytes(_png);
    await _choose(tester);
    expect(find.text('Confirmar foto de perfil'), findsOneWidget);
    expect(repo.uploads, 0);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repo.uploads, 0);
    expect(
      tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).imageUrl,
      isNull,
    );
  });

  testWidgets('camera shows preview and upload waits for confirmation', (
    tester,
  ) async {
    final picker = _Picker();
    final repo = _Repository();
    await _mount(tester, picker, repo);
    await _choose(tester, source: 'Tirar foto');
    expect(picker.selectedSource, AvatarSource.camera);
    expect(repo.uploads, 0);
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(repo.uploads, 1);
    expect(
      tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).imageUrl,
      'https://example.test/avatar.png',
    );
    expect(find.text('Foto atualizada com sucesso.'), findsOneWidget);
  });

  testWidgets('browser-style picker offers gallery without camera', (
    tester,
  ) async {
    final picker = _Picker()..supportsCamera = false;
    await _mount(tester, picker, _Repository());
    await tester.tap(find.byType(ProfileAvatar));
    await tester.pumpAndSettle();
    expect(find.text('Escolher foto'), findsOneWidget);
    expect(find.text('Tirar foto'), findsNothing);
  });

  testWidgets('removal asks for confirmation and restores initials', (
    tester,
  ) async {
    final repo = _Repository();
    await _mount(tester, _Picker(), repo, url: 'https://example.test/old.png');
    await _choose(tester, source: 'Remover foto');
    expect(repo.removals, 0);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repo.removals, 0);
    await _choose(tester, source: 'Remover foto');
    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();
    expect(repo.removals, 1);
    expect(
      tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).imageUrl,
      isNull,
    );
    expect(find.text('MS'), findsOneWidget);
  });

  testWidgets('upload errors preserve old photo and show a Portuguese message', (
    tester,
  ) async {
    final repo = _Repository()
      ..error = const ProfileRepositoryException('Falha na conexão.');
    await _mount(tester, _Picker(), repo, url: 'https://example.test/old.png');
    await _choose(tester);
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(find.text('Falha na conexão.'), findsOneWidget);
    expect(
      tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).imageUrl,
      'https://example.test/old.png',
    );
  });

  testWidgets('permissions denied leave the current photo intact', (
    tester,
  ) async {
    final picker = _Picker()
      ..error = const AvatarSelectionException('Permita o acesso às fotos.');
    final repo = _Repository();
    await _mount(tester, picker, repo);
    await _choose(tester);
    expect(find.text('Permita o acesso às fotos.'), findsOneWidget);
    expect(repo.uploads, 0);
  });

  testWidgets(
    'recovered Android selection still requires preview confirmation',
    (tester) async {
      final picker = _Picker()..recovered = AvatarImage.fromBytes(_png);
      final repo = _Repository();
      await _mount(tester, picker, repo);
      expect(find.text('Confirmar foto de perfil'), findsOneWidget);
      expect(repo.uploads, 0);
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(repo.uploads, 1);
    },
  );

  testWidgets(
    'pending upload blocks duplicate requests and displays progress',
    (tester) async {
      final repo = _Repository()..pending = Completer<MyselfUserModel>();
      await _mount(tester, _Picker(), repo);
      await _choose(tester);
      await tester.tap(find.text('Confirmar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).isLoading,
        isTrue,
      );
      await tester.tap(find.byType(ProfileAvatar));
      await tester.pump();
      expect(find.text('Escolher foto'), findsNothing);
      expect(repo.uploads, 1);
      repo.pending!.complete(_user());
      await tester.pumpAndSettle();
      expect(
        tester.widget<ProfileAvatar>(find.byType(ProfileAvatar)).isLoading,
        isFalse,
      );
    },
  );

  testWidgets('personal data keeps unsaved edits when a photo is uploaded', (
    tester,
  ) async {
    myself.currentUserId = 1;
    final repo = _Repository();
    await tester.pumpWidget(
      MaterialApp(
        home: UserDataPage(
          avatarPicker: _Picker(),
          profileController: ProfileController(repo),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final firstName = find.byType(TextField).first;
    await tester.enterText(firstName, 'Nome ainda não salvo');
    await _choose(tester);
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(firstName).controller!.text,
      'Nome ainda não salvo',
    );
    expect(repo.uploads, 1);
  });

  testWidgets('network image failure falls back to initials', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProfileAvatar(
            name: 'Maria Silva',
            imageUrl: 'https://example.test/broken.png',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('MS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'multipart sends bytes with Bearer token and a generated boundary',
    () async {
      SharedPreferences.setMockInitialValues({});
      await SessionStorage.instance.saveSession(
        userId: 1,
        userTypeId: 1,
        accessToken: 'avatar-test-token',
      );
      final client = MockClient.streaming((request, stream) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/users/1/avatar');
        expect(request.headers['Authorization'], 'Bearer avatar-test-token');
        expect(
          request.headers['content-type'],
          startsWith('multipart/form-data; boundary='),
        );
        final bytes = await stream.toBytes();
        final body = latin1.decode(bytes);
        expect(body, contains('name="file"; filename="avatar.png"'));
        expect(body, contains('content-type: image/png'));
        expect(body, contains(latin1.decode(_png)));
        return http.StreamedResponse(
          Stream.value(
            utf8.encode('{"avatar_url":"https://example.test/new.png"}'),
          ),
          200,
        );
      });
      final service = HttpService(
        baseUrl: 'https://api.example.test',
        client: client,
      );
      addTearDown(service.dispose);
      final response = await service.putMultipart(
        '/users/1/avatar',
        bytes: _png,
        filename: 'avatar.png',
        contentType: 'image/png',
      );
      expect(response['avatar_url'], 'https://example.test/new.png');
    },
  );

  test(
    'multipart preserves API errors and clears an expired session',
    () async {
      SharedPreferences.setMockInitialValues({});
      await SessionStorage.instance.saveSession(
        userId: 1,
        userTypeId: 1,
        accessToken: 'expired-token',
      );
      final service = HttpService(
        baseUrl: 'https://api.example.test',
        client: MockClient(
          (_) async => http.Response('{"detail":"Sessão expirada."}', 401),
        ),
      );
      addTearDown(service.dispose);
      await expectLater(
        service.putMultipart(
          '/users/1/avatar',
          bytes: _png,
          filename: 'avatar.png',
          contentType: 'image/png',
        ),
        throwsA(
          isA<HttpServiceException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', 'Sessão expirada.'),
        ),
      );
      expect(SessionStorage.instance.currentAccessToken, isNull);
    },
  );
}
