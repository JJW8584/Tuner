import 'dart:typed_data';

/// Little-endian mono PCM16 decoder with overlapping, ordered ring-buffer frames.
class PcmFrameBuffer {
  PcmFrameBuffer({this.frameSize = 4096, this.hopSize = 2048})
    : assert(hopSize > 0 && hopSize <= frameSize),
      _samples = Float64List(frameSize);

  final int frameSize;
  final int hopSize;
  final Float64List _samples;
  int _writeIndex = 0;
  int _sampleCount = 0;
  int _sinceLastFrame = 0;
  int? _pendingLowByte;

  Iterable<Float64List> addBytes(Uint8List bytes) sync* {
    for (final byte in bytes) {
      if (_pendingLowByte == null) {
        _pendingLowByte = byte;
        continue;
      }
      var value = _pendingLowByte! | (byte << 8);
      _pendingLowByte = null;
      if (value >= 32768) value -= 65536;
      _samples[_writeIndex] = value / 32768;
      _writeIndex = (_writeIndex + 1) % frameSize;
      _sampleCount++;
      _sinceLastFrame++;
      if (_sampleCount >= frameSize && _sinceLastFrame >= hopSize) {
        _sinceLastFrame = 0;
        final frame = Float64List(frameSize);
        for (var i = 0; i < frameSize; i++) {
          frame[i] = _samples[(_writeIndex + i) % frameSize];
        }
        yield frame;
      }
    }
  }
}
