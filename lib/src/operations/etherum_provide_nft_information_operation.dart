import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:ledger_ethereum/src/ledger/ethereum_instructions.dart';
import 'package:ledger_ethereum/src/ledger/ledger_input_operation.dart';
import 'package:ledger_flutter/ledger_flutter.dart';

class EthereumProvideNFTInformationOperation
    extends LedgerInputOperation<void> {

  final int type;
  final int version;
  final String collectionName;
  final String collectionAddress;
  final int chainId;
  final int keyId;
  final int algorithmId;
  final String collectionInformationSignature;

  EthereumProvideNFTInformationOperation({
    this.type = 0x01,
    this.version = 0x01,
    required this.collectionName,
    required this.collectionAddress,
    required this.chainId,
    this.keyId = 0x01,
    this.algorithmId = 0x01,
    required this.collectionInformationSignature,
  }) : super(ethCLA, 0x0A);

  @override
  Future<void> read(ByteDataReader reader) async {}

  @override
  int get p1 => 0x00;

  @override
  int get p2 => 0x00;

  @override
  Future<Uint8List> writeInputData() async {
    final dataWriter = ByteDataWriter();

    dataWriter.writeUint8(type);
    dataWriter.writeUint8(version);
    dataWriter.writeUint8(collectionName.length);

    dataWriter.write(ascii.encode(collectionName));
    dataWriter.write(hex.decode(collectionAddress));

    dataWriter.writeUint64(chainId);

    dataWriter.writeUint8(keyId);
    dataWriter.writeUint8(algorithmId);

    dataWriter.writeUint8(collectionInformationSignature.length);
    dataWriter.write(hex.decode(collectionInformationSignature));

    return dataWriter.toBytes();
  }
}