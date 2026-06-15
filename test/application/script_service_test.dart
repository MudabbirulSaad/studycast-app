import 'package:flutter_test/flutter_test.dart';
import 'package:studycast/application/script_service.dart';
import 'package:studycast/domain/api/api_failure.dart';
import 'package:studycast/domain/api/studycast_models.dart';

import 'fake_studycast_backend.dart';

void main() {
  test(
    'saves pasted text, uploads a text file, and gets the active script',
    () async {
      final pasted = _script(ScriptSource.pasted);
      final uploaded = _script(ScriptSource.uploaded);
      final calls = <String>[];
      final backend = FakeStudycastBackend()
        ..onSaveScript =
            ({required projectId, required text, required source}) async {
              calls.add('save:$projectId:$text:${source.name}');
              return pasted;
            }
        ..onUploadScriptFile =
            ({required projectId, required filename, required bytes}) async {
              calls.add('upload:$projectId:$filename:${bytes.join(',')}');
              return uploaded;
            }
        ..onGetScript = (projectId) async {
          calls.add('get:$projectId');
          return pasted;
        };
      final service = ScriptService(backend);

      expect(
        await service.savePastedScript(
          projectId: 'project-1',
          text: 'Host: Hello',
        ),
        same(pasted),
      );
      expect(
        await service.uploadTextScript(
          projectId: 'project-1',
          filename: 'lesson.txt',
          bytes: [1, 2, 3],
        ),
        same(uploaded),
      );
      expect(await service.getActiveScript('project-1'), same(pasted));
      expect(calls, [
        'save:project-1:Host: Hello:pasted',
        'upload:project-1:lesson.txt:1,2,3',
        'get:project-1',
      ]);
    },
  );

  test('lets backend failures propagate', () async {
    const failure = ApiFailure(message: 'script missing', code: 'not_found');
    final backend = FakeStudycastBackend()
      ..onGetScript = (projectId) async => throw failure;
    final service = ScriptService(backend);

    await expectLater(
      service.getActiveScript('project-1'),
      throwsA(same(failure)),
    );
  });
}

Script _script(ScriptSource source) {
  return Script(
    projectId: 'project-1',
    text: 'Host: Hello',
    source: source,
    speakers: const ['Host'],
    updatedAt: DateTime.utc(2026, 6, 15),
    chunks: const [Chunk(index: 0, speaker: 'Host', text: 'Hello')],
  );
}
