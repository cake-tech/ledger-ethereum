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
  final EthereumTransformer transformer;

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

  /// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1559.md
  ///
  /// This command signs an Ethereum transaction after having the user validate the following parameters
  ///
  /// Gas price
  /// Gas limit
  /// Recipient address
  /// Value
  ///
  /// The input data is the RLP encoded transaction, without v/r/s present.
  @override
  Future<Uint8List> signTransaction(
          LedgerDevice device, Uint8List transaction) =>
      ledger.sendOperation<Uint8List>(
        device,
        EthereumSignTxOperation(transaction, derivationPath: derivationPath),
        transformer: transformer,
      );

  /// This command signs a list of Ethereum transactions after having the user validate the following parameters of
  /// each transaction
  ///
  /// Gas price
  /// Gas limit
  /// Recipient address
  /// Value
  ///
  /// The input data is a list of the RLP encoded transactions, without v/r/s present.
  @override
  Future<List<Uint8List>> signTransactions(
      LedgerDevice device, List<Uint8List> transactions) async {
    final signatures = <Uint8List>[];
    for (final transaction in transactions) {
      final signature = await signTransaction(device, transaction);
      signatures.add(signature);
    }
    return signatures;
  }

  /// This command signs an Ethereum message following the personal_sign specification (ethereum/go-ethereum#2940) after
  /// having the user validate the SHA-256 hash of the message being signed.
  ///
  /// This command has been supported since firmware version 1.0.8
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

  /// This command provides a trusted description of an ERC 20 token to associate a contract address with a ticker and
  /// number of decimals.
  ///
  /// It shall be run immediately before performing a transaction involving a contract calling this contract address to
  /// display the proper token information to the user if necessary, as marked in [getAppConfig] flags.
  ///
  /// The signature is computed on
  /// ticker || address || number of decimals (uint4be) || chainId (uint4be)
  ///
  /// signed by the following secp256k1 public key
  /// 0482bbf2f34f367b2e5bc21847b6566f21f0976b22d3388a9a5e446ac62d25cf725b62a2555b2dd464a4da0ab2f4d506820543af1d242470b1b1a969a27578f353
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

  ///This command provides a trusted description of an NFT to associate a contract address with a collectionName.
  ///
  /// It shall be run immediately before performing a transaction involving a contract calling this contract address to
  /// display the proper nft information to the user if necessary, as marked in GET APP CONFIGURATION flags.
  ///
  /// The signature is computed on:
  /// type || version || len(collectionName) || collectionName || address || chainId || keyId || algorithmId
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
