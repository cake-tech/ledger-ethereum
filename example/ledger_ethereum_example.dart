import 'package:ledger_ethereum/ledger_ethereum.dart';
import 'package:ledger_flutter/ledger_flutter.dart';

Future<void> main() async {
  /// Create a new instance of LedgerOptions.
  final options = LedgerOptions(
    maxScanDuration: const Duration(milliseconds: 5000),
  );

  /// Create a new instance of Ledger.
  final ledger = Ledger(
    options: options,
  );

  /// Create a new Ethereum Ledger Plugin.
  final ethereumApp = EthereumLedgerApp(ledger);

  /// Scan for devices
  ledger.scan().listen((device) => print(device));

  /// or get a connected one
  final device = ledger.devices.first;

  /// Fetch a list of accounts/public keys from your ledger.
  final accounts = await ethereumApp.getAccounts(device);

  print(accounts); // ["0x0"];
}
