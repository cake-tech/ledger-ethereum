import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:ledger_ethereum/src/ledger/ethereum_instructions.dart';
import 'package:ledger_ethereum/src/ledger/ledger_input_operation.dart';
import 'package:ledger_flutter/ledger_flutter.dart';

class EthereumProvideERC20TokenInformationOperation
    extends LedgerInputOperation<void> {
  final String erc20Ticker;
  final String erc20ContractAddress;
  final int decimals;
  final int chainId;
  final String tokenInformationSignature;

  EthereumProvideERC20TokenInformationOperation({
    required this.erc20Ticker,
    required this.erc20ContractAddress,
    required this.decimals,
    required this.chainId,
    required this.tokenInformationSignature,
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

    dataWriter.writeUint8(erc20Ticker.length);

    dataWriter.write(ascii.encode(erc20Ticker));
    dataWriter.write(hex.decode(erc20ContractAddress));

    dataWriter.writeUint32(decimals);
    dataWriter.writeUint32(chainId);

    dataWriter.write(hex.decode(tokenInformationSignature));

    return dataWriter.toBytes();
  }
}
