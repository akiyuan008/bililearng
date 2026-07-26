@TestOn('mac-os')
library;

import 'package:file_picker/src/platform/macos/file_picker_macos.dart';
import 'package:file_picker/src/api/file_picker_types.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fileTypeToFileFilter()', () {
    test('should return the file filter', () {
      final picker = FilePickerMacOS();

      expect(picker.fileTypeToFileFilter(FileType.any, null), equals([]));

      expect(
        picker.fileTypeToFileFilter(FileType.audio, null),
        equals(["aac", "midi", "mp3", "ogg", "wav"]),
      );

      expect(
        picker.fileTypeToFileFilter(FileType.image, null),
        equals(["bmp", "gif", "jpeg", "jpg", "png", "webp"]),
      );

      expect(
        picker.fileTypeToFileFilter(FileType.media, null),
        equals([
          "avi",
          "flv",
          "m4v",
          "mkv",
          "mov",
          "mp4",
          "mpeg",
          "webm",
          "wmv",
          "bmp",
          "gif",
          "jpeg",
          "jpg",
          "png",
        ]),
      );

      expect(
        picker.fileTypeToFileFilter(FileType.video, null),
        equals([
          "avi",
          "flv",
          "mkv",
          "mov",
          "mp4",
          "m4v",
          "mpeg",
          "webm",
          "wmv",
        ]),
      );
    });

    test(
      'should return the file filter when given a list of custom file extensions',
      () {
        final picker = FilePickerMacOS();

        expect(
          picker.fileTypeToFileFilter(FileType.custom, ['dart']),
          equals(["dart"]),
        );

        expect(
          picker.fileTypeToFileFilter(FileType.custom, ['dart', 'html']),
          equals(["dart", "html"]),
        );
      },
    );
  });
  group('escapeInitialDirectory()', () {
    late FilePickerMacOS picker;

    setUp(() {
      picker = FilePickerMacOS();
    });

    test('should return null when input is null', () {
      expect(picker.escapeInitialDirectory(null), isNull);
    });

    test('should remove ~/ from the beginning of the path', () {
      expect(picker.escapeInitialDirectory('~/Documents'), equals('Documents'));
    });

    test('should remove single ~ from the beginning of the path', () {
      expect(picker.escapeInitialDirectory('~Documents'), equals('Documents'));
    });

    test('should not modify path without tilde', () {
      expect(
        picker.escapeInitialDirectory('/Users/Documents'),
        equals('/Users/Documents'),
      );
    });

    test('should handle empty string', () {
      expect(picker.escapeInitialDirectory(''), equals(''));
    });
  });

  group('getDirectoryPath()', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    final MethodChannel channel = const MethodChannel(
      'miguelruivo.flutter.plugins.filepicker',
    );
    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            log.add(methodCall);
            if (methodCall.method == 'getDirectoryPath') {
              return '/Users/test/Documents';
            }
            return null;
          });
      log.clear();
    });

    test(
      'should pass dialogTitle and initialDirectory to method channel',
      () async {
        final picker = FilePickerMacOS();

        final result = await picker.getDirectoryPath(
          dialogTitle: 'Select Directory',
          initialDirectory: '~/Documents',
        );

        expect(result, equals('/Users/test/Documents'));
        expect(log, hasLength(1));
        expect(log.first.method, equals('getDirectoryPath'));
        expect(
          log.first.arguments,
          equals({
            'dialogTitle': 'Select Directory',
            'initialDirectory': 'Documents',
          }),
        );
      },
    );
  });
}
