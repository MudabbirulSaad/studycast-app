import 'package:flutter_test/flutter_test.dart';
import 'package:studycast/application/voice_service.dart';
import 'package:studycast/domain/api/api_failure.dart';
import 'package:studycast/domain/api/studycast_models.dart';

import 'fake_studycast_backend.dart';

void main() {
  test('lists and uploads voice profiles through the backend port', () async {
    final defaultVoice = _voice(id: 'default', hasSample: false);
    final uploadedVoice = _voice(id: 'voice-1', hasSample: true);
    final calls = <String>[];
    final backend = FakeStudycastBackend()
      ..onListVoices = () async {
        calls.add('list');
        return [defaultVoice];
      }
      ..onUploadVoice =
          ({required displayName, required filename, required bytes}) async {
            calls.add('upload:$displayName:$filename:${bytes.join(',')}');
            return uploadedVoice;
          };
    final service = VoiceService(backend);

    expect(await service.listVoices(), [same(defaultVoice)]);
    expect(
      await service.uploadVoice(
        displayName: 'Teacher Voice',
        filename: 'teacher.wav',
        bytes: [1, 2, 3],
      ),
      same(uploadedVoice),
    );
    expect(calls, ['list', 'upload:Teacher Voice:teacher.wav:1,2,3']);
  });

  test('lets backend failures propagate', () async {
    const failure = ApiFailure(message: 'unsupported extension');
    final backend = FakeStudycastBackend()
      ..onUploadVoice =
          ({required displayName, required filename, required bytes}) async {
            throw failure;
          };
    final service = VoiceService(backend);

    await expectLater(
      service.uploadVoice(
        displayName: 'Teacher Voice',
        filename: 'teacher.aac',
        bytes: [1],
      ),
      throwsA(same(failure)),
    );
  });
}

VoiceProfile _voice({required String id, required bool hasSample}) {
  return VoiceProfile(
    id: id,
    displayName: id == 'default' ? 'Default' : 'Teacher Voice',
    source: id == 'default' ? 'builtin' : 'uploaded',
    samplePath: null,
    hasSample: hasSample,
    createdAt: DateTime.utc(2026, 6, 15),
    updatedAt: DateTime.utc(2026, 6, 15),
  );
}
