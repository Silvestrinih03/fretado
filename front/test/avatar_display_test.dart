import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:front/app/design_system/design_system.dart';
import 'package:front/core/services/myself/models/myself_user_model.dart';
import 'package:front/core/services/myself/repositories/myself_repository.dart';
import 'package:front/core/services/myself/services/myself_service.dart';
import 'package:front/features/driver_operations/data/models/driver_operation_models.dart';
import 'package:front/features/home/presentation/widgets/home_profile_avatar.dart';
import 'package:front/features/ride_chat/data/models/ride_chat_models.dart';

MyselfUserModel _user(String? url) => MyselfUserModel(
  firstName: 'Maria',
  lastName: 'Silva',
  email: 'maria@example.com',
  cpf: '12345678901',
  avatarUrl: url,
);

class _Repository implements MyselfRepository {
  int loads = 0;
  Completer<MyselfUserModel>? pending;
  @override
  Future<MyselfUserModel> getUserById(int userId) async {
    loads++;
    return pending?.future ?? _user('https://example.test/initial.png');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final repository = _Repository();
  final service = MyselfService(repository: repository);
  setUp(() {
    service.currentUserId = null;
    service.currentUserId = 1;
    repository.loads = 0;
    repository.pending = null;
  });

  test('ride and chat models read optional participant avatar URLs', () {
    final ride = DriverRideModel.fromJson({
      'total_price': 50,
      'client': {
        'id': 1,
        'full_name': 'Maria Silva',
        'avatar_url': 'https://example.test/client.png',
      },
      'driver': {
        'id': 2,
        'full_name': 'João Silva',
        'avatar_url': 'https://example.test/driver.png',
      },
    });
    expect(ride.client!.avatarUrl, endsWith('/client.png'));
    expect(ride.driver!.avatarUrl, endsWith('/driver.png'));
    expect(RidePartyModel.fromJson({'id': 3}).avatarUrl, isNull);
    expect(
      RideChatParticipant.fromJson({
        'id': 2,
        'avatar_url': 'https://example.test/chat.png',
      }).avatarUrl,
      endsWith('/chat.png'),
    );
    expect(RideChatParticipant.fromJson({'id': 2}).avatarUrl, isNull);
  });

  testWidgets('avatar uses network photo and falls back when it fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FretAvatar(
            imageUrl: 'https://example.test/avatar.png',
            initials: 'MS',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as NetworkImage).url,
      'https://example.test/avatar.png',
    );
    expect(find.text('MS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing photo keeps initials or the existing profile icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              FretAvatar(initials: 'MS'),
              FretAvatar(),
            ],
          ),
        ),
      ),
    );
    expect(find.text('MS'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets(
    'active ride summary passes the participant photo to its avatar',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FretRideSummaryCard(
              rideId: 1,
              statusId: 3,
              createdAt: DateTime(2026),
              origin: 'Coleta',
              destination: 'Entrega',
              totalPrice: 50,
              packageWeight: 10,
              participantName: 'João Silva',
              participantInitials: 'JS',
              participantAvatarUrl: 'https://example.test/driver.png',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<FretAvatar>(find.byType(FretAvatar)).imageUrl,
        'https://example.test/driver.png',
      );
      expect(find.text('João Silva'), findsOneWidget);
    },
  );

  testWidgets(
    'home header and profile tab react to photo changes without extra requests',
    (tester) async {
      await service.getMyself(1);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                HomeProfileAvatar(userId: 1),
                HomeProfileAvatar(userId: 1, size: 22),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<FretAvatar>(find.byType(FretAvatar))
            .every(
              (avatar) => avatar.imageUrl == 'https://example.test/initial.png',
            ),
        isTrue,
      );
      service.updateCachedProfile(1, _user('https://example.test/new.png'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<FretAvatar>(find.byType(FretAvatar))
            .every(
              (avatar) => avatar.imageUrl == 'https://example.test/new.png',
            ),
        isTrue,
      );
      service.updateCachedProfile(1, _user(null));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.person_outline_rounded), findsNWidgets(2));
      expect(repository.loads, 1);
    },
  );

  testWidgets('switching accounts clears the previous photo', (tester) async {
    service.updateCachedProfile(1, _user('https://example.test/user-one.png'));
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomeProfileAvatar(userId: 1))),
    );
    await tester.pumpAndSettle();
    service.currentUserId = 2;
    await tester.pumpAndSettle();
    expect(service.currentProfile.value, isNull);
    expect(find.byType(Image), findsNothing);
    service.updateCachedProfile(
      1,
      _user('https://example.test/old-response.png'),
    );
    expect(service.currentProfile.value, isNull);
  });

  test(
    'an older profile request cannot overwrite a newly uploaded photo',
    () async {
      repository.pending = Completer<MyselfUserModel>();
      final fetch = service.getMyself(1);
      service.updateCachedProfile(1, _user('https://example.test/new.png'));
      repository.pending!.complete(_user('https://example.test/old.png'));
      await fetch;
      expect(
        service.currentProfile.value!.avatarUrl,
        'https://example.test/new.png',
      );
    },
  );
}
