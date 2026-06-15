import 'package:flutter_test/flutter_test.dart';
import 'package:studycast/app/studycast_app.dart';

void main() {
  testWidgets('studyCast app shell starts without backend calls', (
    tester,
  ) async {
    await tester.pumpWidget(const StudycastApp());

    expect(find.text('studyCast backend core ready'), findsOneWidget);
  });
}
