import 'dart:typed_data';

import 'package:ledger_ethereum/src/ledger/ethereum_instructions.dart';
import 'package:ledger_ethereum/src/utils/bip32_path_helper.dart';
import 'package:ledger_ethereum/src/utils/bip32_path_to_buffer.dart';
import 'package:ledger_flutter/ledger_flutter.dart';

class EthereumSignTxOperation
    extends LedgerOperation<Uint8List> {
  /// The [derivationPath] is a Bip32-path used to derive the public key/Address
  /// If the path is not standard, an error is returned
  final String derivationPath;

  /// The [rawTx] is a RLP encoded transaction
  final Uint8List rawTx;

  EthereumSignTxOperation(this.rawTx,
      {this.derivationPath = "m/44'/60'/0'/0/0"});

  @override
  Future<Uint8List> read(ByteDataReader reader) async {
    final response = reader.read(reader.remainingLength);

    // final v = response[0].toInt();
    // final r = response.sublist(1, 1 + 32).toHexString();
    // final s = response.sublist(1 + 32, 1 + 32 + 32).toHexString();

    return response;
  }

  Uint8List createNextChunk(int offset, int chunkSize) {
    final writer = ByteDataWriter();

    writer.writeUint8(ethCLA);
    writer.writeUint8(0x04);
    writer.writeUint8(0x80);
    writer.writeUint8(0x00);

    writer.writeUint8(chunkSize);

    writer.write(rawTx.sublist(offset, offset + chunkSize));

    return writer.toBytes();
  }

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    final outputs = <Uint8List>[];

    writer.writeUint8(ethCLA);
    writer.writeUint8(0x04);
    writer.writeUint8(0x00);
    writer.writeUint8(0x00);

    final path = BIPPath.fromString(derivationPath).toPathArray();

    // writer.writeUint8(0x96);

    final dwriter = ByteDataWriter();
    dwriter.write(packDerivationPath(path));

    var offset = 0;
    final firstChunkMaxSize = 150 - 1 - path.length * 4;
    final firstChunkSize = offset + firstChunkMaxSize > rawTx.length
        ? rawTx.length : firstChunkMaxSize;

    // Write first chunk
    dwriter.write(rawTx.sublist(0, firstChunkSize));

    final dataBy = dwriter.toBytes();
    writer.writeUint8(dataBy.length);
    writer.write(dataBy);

    outputs.add(writer.toBytes());

    offset = firstChunkSize;

    while (offset < rawTx.length) {
      final chunkSize =
          offset + 150 > rawTx.length ? rawTx.length - offset : 150;

      outputs.add(createNextChunk(offset, chunkSize));
      offset += chunkSize;
    }

    return outputs;
  }
}
