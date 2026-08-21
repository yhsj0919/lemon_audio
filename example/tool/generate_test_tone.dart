import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() {
  const sampleRate = 8000;
  const seconds = 30;
  const frequency = 440.0;
  const amplitude = 5000;
  final sampleCount = sampleRate * seconds;
  final dataSize = sampleCount * 2;
  final bytes = ByteData(44 + dataSize);

  void text(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      bytes.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  text(0, 'RIFF');
  bytes.setUint32(4, 36 + dataSize, Endian.little);
  text(8, 'WAVEfmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  text(36, 'data');
  bytes.setUint32(40, dataSize, Endian.little);

  for (var i = 0; i < sampleCount; i++) {
    final fade = math.min(1.0, math.min(i, sampleCount - i) / 400);
    final sample =
        (math.sin(2 * math.pi * frequency * i / sampleRate) * amplitude * fade)
            .round();
    bytes.setInt16(44 + i * 2, sample, Endian.little);
  }

  File('assets/test-tone.wav')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes.buffer.asUint8List());
}
