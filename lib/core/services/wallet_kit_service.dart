import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_util' as jsu;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';

/// Reown AppKit(Web3Modal) 기반 MetaMask 연동 서비스 (Web 전용)
class WalletKitService {
  WalletKitService._internal();
  static final WalletKitService instance = WalletKitService._internal();

  ReownAppKitModal? _modal;
  ReownAppKitModalWalletInfo? _injectedMetaMask;
  String? _lastAddress;
  String? _lastSignature;

  void _ensureInitializedWithContext(BuildContext context) {
    if (_modal != null) return;

    const String iconUrl =
        'https://raw.githubusercontent.com/2025-Imagine-Company/APP/develop/assets/images/audion_logo.png';

    final metaMaskListing = AppKitModalWalletListing(
      id: 'custom-metamask',
      name: 'MetaMask',
      homepage: 'https://metamask.io',
      imageId: '',
      order: 0,
      injected: [Injected(namespace: 'eip155', injectedId: 'metamask')],
    );
    final metaMaskInfo = ReownAppKitModalWalletInfo(
      listing: metaMaskListing,
      installed: true,
      recent: false,
    );
    _injectedMetaMask = metaMaskInfo;

    final String appUrl = _getAppOrigin();

    _modal = ReownAppKitModal(
      context: context,
      projectId: '627c842e83be890d9ea9ca694a38ebb3',
      metadata: PairingMetadata(
        name: 'Audion',
        description: 'Login to Audion',
        url: appUrl,
        icons: const [iconUrl],
      ),
      enableAnalytics: false,
      featuresConfig: FeaturesConfig(
        email: false,
        socials: [],
        showMainWallets: false,
      ),
      customWallets: [metaMaskInfo],
      optionalNamespaces: {
        'eip155': RequiredNamespace(
          chains: ['eip155:1'],
          methods: ['personal_sign'],
          events: ['accountsChanged'],
        ),
      },
    );
  }

  String _getAppOrigin() {
    if (kIsWeb) {
      try {
        final origin = html.window.location.origin;
        if (origin.isNotEmpty) {
          return origin;
        }
      } catch (_) {}
    }
    return 'http://localhost:8082';
  }

  Future<void> _waitForInit() async {
    await _modal!.init();
  }

  Future<bool> _fallbackMetamaskConnectAndSign(String message) async {
    if (!kIsWeb) return false;
    try {
      final eth = jsu.getProperty(html.window, 'ethereum');
      if (eth == null) {
        return false;
      }

      final accounts = await jsu.promiseToFuture(
        jsu.callMethod(eth, 'request', [jsu.jsify({'method': 'eth_requestAccounts'})]),
      ) as dynamic;
      final List accList = accounts is List ? accounts : <dynamic>[];
      if (accList.isEmpty) throw StateError('No accounts from provider');
      final address = accList.first as String;

      final encoded = _toHexPrefixed(message);
      final signature = await jsu.promiseToFuture(
        jsu.callMethod(eth, 'request', [
          jsu.jsify({'method': 'personal_sign', 'params': [encoded, address]})
        ]),
      );
      if (signature == null) throw StateError('Empty signature');
      _lastAddress = address;
      _lastSignature = signature as String?;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> requestAddress() async {
    if (!kIsWeb) return null;
    try {
      final eth = jsu.getProperty(html.window, 'ethereum');
      if (eth == null) return null;
      final accounts = await jsu.promiseToFuture(
        jsu.callMethod(eth, 'request', [jsu.jsify({'method': 'eth_requestAccounts'})]),
      ) as dynamic;
      final List accList = accounts is List ? accounts : <dynamic>[];
      if (accList.isEmpty) return null;
      final address = accList.first as String;
      _lastAddress = address;
      return address;
    } catch (_) {
      return null;
    }
  }

  String _toHexPrefixed(String message) {
    final bytes = utf8.encode(message);
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '0x$hex';
  }

  /// '/connectWallet' 진입 시 자동 연결 후 personal_sign 요청까지 수행
  Future<void> connectAndPersonalSign({
    required BuildContext context,
    String message = 'Login to Audion',
    void Function()? onSuccess,
    void Function(Object error)? onFailure,
  }) async {
    if (!kIsWeb) {
      onFailure?.call(UnsupportedError('Web only'));
      return;
    }

    try {
      final providerOk = await _fallbackMetamaskConnectAndSign(message);
      if (providerOk) {
        onSuccess?.call();
        return;
      }

      _ensureInitializedWithContext(context);
      final modal = _modal!;
      await _waitForInit();
      final metaMask = _injectedMetaMask;
      if (metaMask == null) throw StateError('MetaMask info not prepared');
      modal.selectWallet(metaMask);

      final connectCompleter = Completer<ReownAppKitModalSession>();
      void onConnect(ModalConnect e) {
        if (!connectCompleter.isCompleted && modal.session != null) {
          connectCompleter.complete(modal.session!);
        }
      }
      modal.onModalConnect.subscribe(onConnect);
      await modal.connectSelectedWallet(inBrowser: true);
      final session = await connectCompleter.future.timeout(const Duration(seconds: 6));
      modal.onModalConnect.unsubscribe(onConnect);

      final String? address = session.getAddress(NetworkUtils.eip155);
      final String? topic = session.topic;
      if (address == null || topic == null) {
        throw StateError('No wallet address or topic');
      }

      final encoded = _toHexPrefixed(message);
      final result = await modal.request(
        topic: topic,
        chainId: 'eip155:1',
        request: SessionRequestParams(
          method: 'personal_sign',
          params: [encoded, address],
        ),
      );

      if (result == null) {
        throw StateError('User rejected or empty signature');
      }
      _lastAddress = address;
      _lastSignature = result as String?;
      onSuccess?.call();
    } catch (e) {
      onFailure?.call(e);
    }
  }

  String? get lastAddress => _lastAddress;
  String? get lastSignature => _lastSignature;

  Future<void> openSelectionModal(BuildContext context) async {
    if (!kIsWeb) return;
    _ensureInitializedWithContext(context);
    await _waitForInit();
    await _modal!.openModalView();
  }
}


