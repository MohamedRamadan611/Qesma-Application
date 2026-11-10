import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/api/connectivity.dart';
import 'package:qesma/core/app_info.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/l10n/locale_controller.dart';
import 'package:qesma/core/prefs/preference_store.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'package:qesma/features/profile/application/update_profile_controller.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../support/auth_ui.dart';
import '../../support/fake_groups_server.dart';
import '../../support/groups_rig.dart';

UserDto _user(String name) => UserDto((b) => b
  ..hasPassword = false
  ..emailVerified = true
  ..id = 'u1'
  ..displayName = name
  ..email = 'test@example.com');

void main() {
  group('display name (pure)', () {
    ProfileForm form(String text, {String original = 'Mohamed'}) => ProfileForm(original: original, name: text);

    test('required, trimmed, at most 60 code points, and unchanged is not saveable', () {
      expect(form('').error, NameError.empty);
      expect(form('    ').error, NameError.empty);
      expect(form('a' * 60).error, isNull);
      expect(form('a' * 61).error, NameError.tooLong);
      expect(form('  ${'a' * 60}  ').error, isNull, reason: 'trimmed before counting');
      expect(form('😀' * 60).error, isNull, reason: 'code points, not UTF-16 units');
      expect(form('😀' * 61).error, NameError.tooLong);
      expect(form('محمد رمضان').canSave, isTrue);
      expect(form('Mohamed').canSave, isFalse, reason: 'the same name');
      expect(form('  Mohamed  ').canSave, isFalse, reason: 'the same name after trimming');
      expect(form('Mohamed').dirty, isFalse);
      expect(form('Mohamed R').dirty, isTrue);
    });
  });

  group('version', () {
    test('the default equals pubspec.yaml, so the two cannot drift', () {
      final line = File('pubspec.yaml').readAsLinesSync().firstWhere((l) => l.startsWith('version:'));
      expect(AppInfo.defaultVersion, line.substring('version:'.length).trim());
    });

    test('shown as version and build number', () {
      expect(AppInfo.display, '0.1.0 (1)');
    });
  });

  group('language is remembered', () {
    ProviderContainer containerWith(PreferenceStore store) {
      final c = ProviderContainer(overrides: [preferenceStoreProvider.overrideWithValue(store)]);
      addTearDown(c.dispose);
      return c;
    }

    test('first launch with nothing stored is Arabic', () async {
      final c = containerWith(InMemoryPreferenceStore());
      expect(c.read(localeProvider), const Locale('ar'));
      await Future<void>.delayed(Duration.zero);
      expect(c.read(localeProvider), const Locale('ar'));
    });

    test('choosing English applies at once, is stored, and a fresh start restores it', () async {
      final store = InMemoryPreferenceStore();
      final first = containerWith(store);
      await first.read(localeProvider.notifier).choose(const Locale('en'));
      expect(first.read(localeProvider), const Locale('en'));
      expect(store.values[kLocalePref], 'en');

      final second = containerWith(store);
      expect(second.read(localeProvider), const Locale('ar'), reason: 'Arabic until the stored value is read');
      await Future<void>.delayed(Duration.zero);
      expect(second.read(localeProvider), const Locale('en'));
    });

    test('a garbage stored value is ignored', () async {
      final c = containerWith(InMemoryPreferenceStore({kLocalePref: 'fr'}));
      c.read(localeProvider);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(localeProvider), const Locale('ar'));
    });

    test('a choice made before the stored value is read wins over it', () async {
      final c = containerWith(InMemoryPreferenceStore({kLocalePref: 'en'}));
      c.read(localeProvider.notifier).set(const Locale('ar'));
      await Future<void>.delayed(Duration.zero);
      expect(c.read(localeProvider), const Locale('ar'));
    });
  });

  group('connectivity comes from real traffic', () {
    late FakeGroupsServer server;
    late ProviderContainer container;

    setUp(() {
      server = FakeGroupsServer();
      container = groupsContainer(server);
      addTearDown(container.dispose);
    });

    test('a connection failure means offline; any answer, even a 404, means online again', () async {
      final api = container.read(qesmaApiProvider);
      expect(container.read(connectivityProvider), isTrue);

      server.offline = true;
      await expectLater(api.getMeControllerApi().getMe(), throwsA(anything));
      expect(container.read(connectivityProvider), isFalse);

      server.offline = false;
      await expectLater(api.getGroupControllerApi().getGroup(gid: 'nope'), throwsA(anything)); // 404
      expect(container.read(connectivityProvider), isTrue, reason: 'the server answered');
    });
  });

  group('update profile controller (real stack on the fake server)', () {
    late FakeGroupsServer server;
    late ProviderContainer container;

    setUp(() {
      server = FakeGroupsServer();
      container = groupsContainer(server, extra: [authControllerProvider.overrideWith(() => StubAuth(AuthSignedIn(_user('Test User'))))]);
      addTearDown(container.dispose);
      container.listen(updateProfileControllerProvider, (_, _) {});
    });

    UpdateProfileController ctl() => container.read(updateProfileControllerProvider.notifier);
    UpdateProfileState state() => container.read(updateProfileControllerProvider);

    test('starts from the signed-in name and saves the trimmed name with the exact body', () async {
      expect(state().form.name, 'Test User');
      expect(await ctl().save(), isFalse, reason: 'nothing changed');
      expect(server.meUpdates, isEmpty);

      ctl().setName('  Mohamed Ramadan  ');
      expect(await ctl().save(), isTrue);
      expect(server.meUpdates, [
        {'displayName': 'Mohamed Ramadan'}
      ]);
      final auth = container.read(authControllerProvider) as AuthSignedIn;
      expect(auth.user.displayName, 'Mohamed Ramadan', reason: 'the cached user is replaced everywhere');
      expect(state().form.dirty, isFalse);
    });

    test('an invalid name sends nothing', () async {
      ctl().setName('   ');
      expect(await ctl().save(), isFalse);
      ctl().setName('a' * 61);
      expect(await ctl().save(), isFalse);
      expect(server.meUpdates, isEmpty);
    });

    test('a refusal or no connection keeps the form and the old name', () async {
      ctl().setName('New');
      server.forceMeCode = 'VALIDATION_ERROR';
      expect(await ctl().save(), isFalse);
      expect(state().failure, isNotNull);
      expect(state().form.name, 'New');
      expect((container.read(authControllerProvider) as AuthSignedIn).user.displayName, 'Test User');

      server.offline = true;
      expect(await ctl().save(), isFalse);
      expect(state().saving, isFalse);
      server.offline = false;
      expect(await ctl().save(), isTrue, reason: 'the same input works once the network is back');
    });
  });
}
