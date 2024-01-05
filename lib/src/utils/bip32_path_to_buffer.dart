import 'dart:typed_data';

import 'package:ledger_flutter/ledger_flutter.dart';

Uint8List packDerivationPath(List<int> path) {
  final inputWriter = ByteDataWriter();

  inputWriter.writeUint8(path.length); // Write length of the derivation path

  for (var element in path) {
    inputWriter.writeUint32(element); // Add each part of the path
  }

  return inputWriter.toBytes();
}
