import 'dart:typed_data';

import 'package:ledger_flutter/ledger_flutter.dart';

abstract class LedgerInputOperation<T> extends LedgerOperation<T> {
  final int cla;
  final int ins;

  LedgerInputOperation(this.cla, this.ins);

  int get p1;
  int get p2;
  Future<Uint8List> writeInputData();

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    writer.writeUint8(cla);
    writer.writeUint8(ins);
    writer.writeUint8(p1);
    writer.writeUint8(p2);

    final inputData = await writeInputData();
    writer.writeUint8(inputData.length);
    writer.write(inputData);

    return [writer.toBytes()];
  }
}
