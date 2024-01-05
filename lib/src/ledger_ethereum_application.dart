import 'dart:typed_data';

import 'package:ledger_ethereum/src/ethereum_app_config.dart';
import 'package:ledger_ethereum/src/etherum_transformer.dart';
import 'package:ledger_ethereum/src/operations/ethereum_app_config_operation.dart';
import 'package:ledger_ethereum/src/operations/ethereum_sign_msg_operation.dart';
import 'package:ledger_ethereum/src/operations/ethereum_sign_tx_operation.dart';
import 'package:ledger_ethereum/src/operations/etherum_provide_erc20_token_information_operation.dart';
import 'package:ledger_ethereum/src/operations/etherum_provide_nft_information_operation.dart';
import 'package:ledger_ethereum/src/operations/etherum_wallet_address_operation.dart';
import 'package:ledger_ethereum/src/utils/erc20_info_helper.dart';
import 'package:ledger_ethereum/src/utils/nft_info_helper.dart';
import 'package:ledger_flutter/ledger_flutter.dart';

class EthereumLedgerApp extends LedgerApp {
  EthereumTransformer transformer;

  /// The [derivationPath] is a Bip32-path used to derive the public key/Address
  /// If the path is not standard, an error is returned
  final String derivationPath;

  EthereumLedgerApp(
    super.ledger, {
    this.transformer = const EthereumTransformer(),
    this.derivationPath = "m/44'/60'/0'/0/0",
  });

  @override
  Future<List<String>> getAccounts(LedgerDevice device) async {
    final (_, address, _) =
        await ledger.sendOperation<(String, String, String?)>(
      device,
      EthereumWalletAddressOperation(derivationPath: derivationPath),
      transformer: transformer,
    );
    return [address];
  }

  @override
  Future<EthereumAppConfig> getVersion(LedgerDevice device) =>
      getAppConfig(device);

  Future<EthereumAppConfig> getAppConfig(LedgerDevice device) =>
      ledger.sendOperation<EthereumAppConfig>(
        device,
        EthereumAppConfigOperation(),
        transformer: transformer,
      );

  @override
  Future<Uint8List> signTransaction(
          LedgerDevice device, Uint8List transaction) =>
      ledger.sendOperation<Uint8List>(
        device,
        EthereumSignTxOperation(transaction, derivationPath: derivationPath),
        transformer: transformer,
      );

  @override
  Future<List<Uint8List>> signTransactions(
      LedgerDevice device, List<Uint8List> transactions) async {
    final signatures = <Uint8List>[];
    for (var transaction in transactions) {
      final signature = await ledger.sendOperation<Uint8List>(
        device,
        EthereumSignTxOperation(transaction, derivationPath: derivationPath),
        transformer: transformer,
      );
      signatures.add(signature);
    }
    return signatures;
  }

  /// Signs a message according to eth_sign RPC call and retrieves v, r, s given the message and the BIP 32 path of the account to sign.
  ///
  /// v = sig[0].toInt()
  /// r = sig.sublist(1, 1 + 32).toHexString();
  /// s = sig.sublist(1 + 32, 1 + 32 + 32).toHexString();
  Future<Uint8List> signMessage(LedgerDevice device, Uint8List message) =>
      ledger.sendOperation<Uint8List>(
        device,
        EthereumSignMsgOperation(message, derivationPath: derivationPath),
        transformer: transformer,
      );

  Future<void> provideERC20TokenInformation(
    LedgerDevice device, {
    required String erc20Ticker,
    required String erc20ContractAddress,
    required int decimals,
    required int chainId,
    required String tokenInformationSignature,
  }) =>
      ledger.sendOperation<void>(
        device,
        EthereumProvideERC20TokenInformationOperation(
            erc20Ticker: erc20Ticker,
            erc20ContractAddress: erc20ContractAddress,
            decimals: decimals,
            chainId: chainId,
            tokenInformationSignature: tokenInformationSignature),
        transformer: transformer,
      );

  /// Requests the required additional information from Ledger's CDN.
  /// Only [chainId] and [erc20ContractAddress] are needed this way to provide the Ledger Device with valid ERC20-Token information
  Future<void> getAndProvideERC20TokenInformation(
    LedgerDevice device, {
    required String erc20ContractAddress,
    required int chainId,
  }) async {
    final (erc20Ticker, decimals, tokenInformationSignature) =
        await getERC20Signatures(chainId, erc20ContractAddress);

    return provideERC20TokenInformation(device,
        erc20Ticker: erc20Ticker,
        erc20ContractAddress: erc20ContractAddress,
        decimals: decimals,
        chainId: chainId,
        tokenInformationSignature: tokenInformationSignature);
  }

  Future<void> provideNFTInformation(
    LedgerDevice device, {
    required int type,
    required int version,
    required String collectionName,
    required String collectionAddress,
    required int chainId,
    required int keyId,
    required int algorithmId,
    required String collectionInformationSignature,
  }) =>
      ledger.sendOperation<void>(
        device,
        EthereumProvideNFTInformationOperation(
            type: type,
            version: version,
            collectionName: collectionName,
            collectionAddress: collectionAddress,
            chainId: chainId,
            keyId: keyId,
            algorithmId: algorithmId,
            collectionInformationSignature: collectionInformationSignature),
        transformer: transformer,
      );

  /// Requests the required additional information from Ledger's API.
  /// Only [chainId] and [collectionAddress] are needed this way to provide the Ledger Device with valid NFT information
  Future<void> getAndProvideNFTInformation(
    LedgerDevice device, {
    required String collectionAddress,
    required int chainId,
  }) async {
    final (
      type,
      version,
      collectionName,
      keyId,
      algorithmId,
      collectionInformationSignature
    ) = await getNFTInfo(chainId, collectionAddress);

    return provideNFTInformation(device,
        type: type,
        version: version,
        collectionName: collectionName,
        collectionAddress: collectionAddress,
        chainId: chainId,
        keyId: keyId,
        algorithmId: algorithmId,
        collectionInformationSignature: collectionInformationSignature);
  }
}
