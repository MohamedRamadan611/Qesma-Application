import 'package:test/test.dart';
import 'package:qesma_api/qesma_api.dart';


/// tests for MeControllerApi
void main() {
  final instance = QesmaApi().getMeControllerApi();

  group(MeControllerApi, () {
    //Future<UserDto> getMe() async
    test('test getMe', () async {
      // TODO
    });

    //Future<UserDto> updateMe(UpdateMeRequest updateMeRequest) async
    test('test updateMe', () async {
      // TODO
    });

  });
}
