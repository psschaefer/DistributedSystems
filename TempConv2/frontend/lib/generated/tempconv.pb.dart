// Hand-written stub matching proto tempconv.proto for use without protoc.
// Regenerate with: see README scripts/gen-dart.sh

import 'dart:convert';
import 'dart:typed_data';

class ConversionRequest {
  double value;
  ConversionRequest({this.value = 0});

  List<int> writeToBuffer() {
    final out = <int>[];
    if (value != 0) {
      out.addAll(_encodeTag(1, 1)); // fixed64
      out.addAll(_encodeDouble(value));
    }
    return out;
  }

  static ConversionRequest mergeFromBuffer(List<int> bytes) {
    final r = ConversionRequest();
    var i = 0;
    while (i < bytes.length) {
      final tag = _decodeVarint(bytes, i);
      i = tag.nextIndex;
      final fieldNumber = tag.value >> 3;
      final wireType = tag.value & 7;
      if (fieldNumber == 1 && wireType == 1) {
        final d = _decodeDouble(bytes, i);
        r.value = d.value;
        i = d.nextIndex;
      } else {
        i = _skipField(bytes, i, wireType);
      }
    }
    return r;
  }
}

class ConversionResponse {
  double input;
  double output;
  String fromUnit;
  String toUnit;
  String description;

  ConversionResponse({
    this.input = 0,
    this.output = 0,
    this.fromUnit = '',
    this.toUnit = '',
    this.description = '',
  });

  static ConversionResponse mergeFromBuffer(List<int> bytes) {
    final r = ConversionResponse();
    var i = 0;
    while (i < bytes.length) {
      final tag = _decodeVarint(bytes, i);
      i = tag.nextIndex;
      final fieldNumber = tag.value >> 3;
      final wireType = tag.value & 7;
      if (fieldNumber == 1 && wireType == 1) {
        final d = _decodeDouble(bytes, i);
        r.input = d.value;
        i = d.nextIndex;
      } else if (fieldNumber == 2 && wireType == 1) {
        final d = _decodeDouble(bytes, i);
        r.output = d.value;
        i = d.nextIndex;
      } else if (fieldNumber == 3 && wireType == 2) {
        final s = _decodeLengthDelimited(bytes, i);
        r.fromUnit = utf8.decode(s.value);
        i = s.nextIndex;
      } else if (fieldNumber == 4 && wireType == 2) {
        final s = _decodeLengthDelimited(bytes, i);
        r.toUnit = utf8.decode(s.value);
        i = s.nextIndex;
      } else if (fieldNumber == 5 && wireType == 2) {
        final s = _decodeLengthDelimited(bytes, i);
        r.description = utf8.decode(s.value);
        i = s.nextIndex;
      } else {
        i = _skipField(bytes, i, wireType);
      }
    }
    return r;
  }
}

List<int> _encodeTag(int fieldNumber, int wireType) {
  return _encodeVarint((fieldNumber << 3) | wireType);
}

List<int> _encodeVarint(int v) {
  final out = <int>[];
  while (v > 0x7f) {
    out.add((v & 0x7f) | 0x80);
    v >>= 7;
  }
  out.add(v & 0x7f);
  return out;
}

List<int> _encodeDouble(double v) {
  final data = ByteData(8);
  data.setFloat64(0, v, Endian.little);
  // Avoid getUint64 (not supported by dart2js on web); use raw bytes instead.
  return data.buffer.asUint8List(0, 8).toList();
}

class _Decoded<T> {
  final T value;
  final int nextIndex;
  _Decoded(this.value, this.nextIndex);
}

_Decoded<int> _decodeVarint(List<int> bytes, int start) {
  var result = 0;
  var shift = 0;
  var i = start;
  while (i < bytes.length) {
    final b = bytes[i++];
    result |= (b & 0x7f) << shift;
    if ((b & 0x80) == 0) break;
    shift += 7;
  }
  return _Decoded(result, i);
}

_Decoded<double> _decodeDouble(List<int> bytes, int start) {
  if (start + 8 > bytes.length) return _Decoded(0.0, bytes.length);
  final data = ByteData(8);
  for (var i = 0; i < 8; i++) data.setUint8(i, bytes[start + i]);
  final v = data.getFloat64(0, Endian.little);
  return _Decoded(v, start + 8);
}

_Decoded<List<int>> _decodeLengthDelimited(List<int> bytes, int start) {
  final len = _decodeVarint(bytes, start);
  final end = len.nextIndex + len.value;
  return _Decoded(bytes.sublist(len.nextIndex, end), end);
}

int _skipField(List<int> bytes, int i, int wireType) {
  if (wireType == 0) {
    final v = _decodeVarint(bytes, i);
    return v.nextIndex;
  }
  if (wireType == 1) return i + 8;
  if (wireType == 2) {
    final len = _decodeVarint(bytes, i);
    return len.nextIndex + len.value;
  }
  if (wireType == 5) return i + 4;
  return i;
}
