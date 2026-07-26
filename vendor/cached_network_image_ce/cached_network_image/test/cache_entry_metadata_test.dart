import 'package:cached_network_image_ce/src/cache/default_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CacheEntryMetadata', () {
    test('constructor sets all fields', () {
      final validTill = DateTime(2025, 1, 1);
      final metadata = CacheEntryMetadata(
        url: 'https://example.com/image.png',
        fileExtension: 'png',
        validTill: validTill,
        eTag: '"etag-value"',
        length: 1024,
      );

      expect(metadata.url, 'https://example.com/image.png');
      expect(metadata.fileExtension, 'png');
      expect(metadata.validTill, validTill);
      expect(metadata.eTag, '"etag-value"');
      expect(metadata.length, 1024);
    });

    test('constructor defaults length to 0', () {
      final metadata = CacheEntryMetadata(
        url: 'https://example.com/image.png',
        fileExtension: 'png',
        validTill: DateTime(2025, 1, 1),
      );

      expect(metadata.length, 0);
      expect(metadata.eTag, isNull);
    });

    test('fromMap constructs correctly with all fields', () {
      final map = {
        'url': 'https://example.com/image.png',
        'fileExtension': 'png',
        'validTill': DateTime(2025, 6, 15).millisecondsSinceEpoch,
        'eTag': '"some-etag"',
        'length': 2048,
      };

      final metadata = CacheEntryMetadata.fromMap(map);

      expect(metadata.url, 'https://example.com/image.png');
      expect(metadata.fileExtension, 'png');
      expect(
        metadata.validTill,
        DateTime.fromMillisecondsSinceEpoch(
          DateTime(2025, 6, 15).millisecondsSinceEpoch,
        ),
      );
      expect(metadata.eTag, '"some-etag"');
      expect(metadata.length, 2048);
    });

    test('fromMap defaults length to 0 when missing', () {
      final map = {
        'url': 'https://example.com/image.png',
        'fileExtension': 'png',
        'validTill': DateTime(2025, 1, 1).millisecondsSinceEpoch,
        'eTag': null,
      };

      final metadata = CacheEntryMetadata.fromMap(map);

      expect(metadata.length, 0);
      expect(metadata.eTag, isNull);
    });

    test('toMap serializes correctly', () {
      final validTill = DateTime(2025, 3, 20);
      final metadata = CacheEntryMetadata(
        url: 'https://example.com/test.jpg',
        fileExtension: 'jpg',
        validTill: validTill,
        eTag: '"my-etag"',
        length: 512,
      );

      final map = metadata.toMap();

      expect(map['url'], 'https://example.com/test.jpg');
      expect(map['fileExtension'], 'jpg');
      expect(map['validTill'], validTill.millisecondsSinceEpoch);
      expect(map['eTag'], '"my-etag"');
      expect(map['length'], 512);
    });

    test('toMap → fromMap roundtrip preserves data', () {
      final original = CacheEntryMetadata(
        url: 'https://example.com/roundtrip.png',
        fileExtension: 'png',
        validTill: DateTime(2025, 12, 31, 23, 59, 59),
        eTag: '"roundtrip-etag"',
        length: 4096,
      );

      final reconstructed = CacheEntryMetadata.fromMap(original.toMap());

      expect(reconstructed.url, original.url);
      expect(reconstructed.fileExtension, original.fileExtension);
      expect(
        reconstructed.validTill.millisecondsSinceEpoch,
        original.validTill.millisecondsSinceEpoch,
      );
      expect(reconstructed.eTag, original.eTag);
      expect(reconstructed.length, original.length);
    });

    test('toMap with null eTag', () {
      final metadata = CacheEntryMetadata(
        url: 'https://example.com/no-etag.png',
        fileExtension: 'png',
        validTill: DateTime(2025, 1, 1),
      );

      final map = metadata.toMap();
      expect(map['eTag'], isNull);
    });
  });
}
