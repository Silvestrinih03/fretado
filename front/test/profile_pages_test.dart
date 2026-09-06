import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:front/core/services/myself/models/myself_user_model.dart';
import 'package:front/core/services/myself/repositories/myself_repository.dart';
import 'package:front/core/services/myself/services/myself_service.dart';
import 'package:front/features/profile/presentation/pages/client_profile_page.dart';
import 'package:front/features/profile/presentation/pages/user_data_page.dart';
import 'package:front/features/profile/presentation/pages/change_password_popup.dart';
import 'package:front/features/profile/presentation/widgets/profile_widgets.dart';

class _MyselfRepository implements MyselfRepository {
  int loads = 0;
  @override
  Future<MyselfUserModel> getUserById(int userId) async {
    loads++;
    return const MyselfUserModel(firstName: 'Maria', lastName: 'Antonia',
      email: 'cliente@example.com', cpf: '51010985230', userTypeId: 1,
      completedRidesCount: 3, birthDate: '2003-11-30', phone: '19999999999');
  }
}

void main() {
  final repository = _MyselfRepository();
  MyselfService(repository: repository).currentUserId = 1;

  testWidgets('profile opens personal data without password and reloads on return', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: ClientProfilePage(userId: 1)));
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('Ajuda e suporte'), findsOneWidget);
    await tester.tap(find.text('Dados pessoais'));
    await tester.pumpAndSettle();
    expect(find.byType(UserDataPage), findsOneWidget);
    expect(find.byType(ProfileField), findsNWidgets(6));
    expect(find.text('SENHA'), findsNothing);
    expect(find.text('Cliente · cliente@example.com'), findsOneWidget);
    final loads = repository.loads;
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(repository.loads, greaterThan(loads));
    expect(tester.takeException(), isNull);
  });

  test('reads completed ride count returned by the API', () {
    final user = MyselfUserModel.fromJson({'completed_rides_count': 7});
    expect(user.completedRidesCount, 7);
    expect(MyselfUserModel.fromJson({}).completedRidesCount, 0);
  });

  testWidgets('security screen validates empty form and toggles each password independently', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChangePasswordPopup()));
    expect(find.text('Última alteração: há 2 meses'), findsOneWidget);
    expect(find.text('Ativa'), findsNothing);
    expect(find.byType(ProfileField), findsNWidgets(3));
    await tester.ensureVisible(find.text('Atualizar senha'));
    await tester.tap(find.text('Atualizar senha'));
    await tester.pump();
    expect(find.text('Informe sua senha atual.'), findsOneWidget);
    expect(find.text('Informe a nova senha.'), findsOneWidget);
    expect(find.text('Confirme a nova senha.'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Mostrar senha').first);
    await tester.tap(find.byTooltip('Mostrar senha').first);
    await tester.pump();
    final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[0].obscureText, isFalse);
    expect(fields[1].obscureText, isTrue);
    expect(fields[2].obscureText, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CPF remains read only and fields fit narrow screens', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TextEditingController(text: '510.109.852-30');
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ProfileField(
      label: 'CPF', controller: controller, readOnly: true, icon: Icons.check_rounded))));
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    expect(tester.takeException(), isNull);
  });
}
