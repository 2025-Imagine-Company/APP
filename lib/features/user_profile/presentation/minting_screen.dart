import 'package:app/core/widgets/custom_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../authentication/presentation/authentication_bloc.dart';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:typed_data';
import 'package:web3dart/contracts.dart';
import 'package:web3dart/crypto.dart' show bytesToHex;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:app/core/constants/endpoints.dart';

class MintingScreen extends StatefulWidget {
  const MintingScreen({super.key});

  @override
  State<MintingScreen> createState() => _MintingScreenState();
}

class _MintingScreenState extends State<MintingScreen> {
  bool _fetched = false;
  bool _isMinting = false;

  // mypage에서 받아온 모델 정보
  // _MintingScreenState
  String? _argModelId;
  String? _argModelName;
  String? _argPreviewUrl;
  String? _argModelPath;


  // Sepolia 배포된 컨트랙트/고정 tokenURI(데모용)
  static const String _contractAddress = '0x147cf4ba7825a8e70d0a016f9ad523b2bacdde36';
  static const String _sepoliaChainHex = '0xaa36a7'; // 11155111
  static const String _demoTokenUri = 'ipfs://bafkreigja7pcz37oop3wxsgzqkuykkjctlqvqdclbmsumv4x5dsp4hkine';

  String _encodeMintData(String tokenUri) {
    const abiJson = '[{"inputs":[{"internalType":"string","name":"tokenURI_","type":"string"}],"name":"mint","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"}]';
    final abi = ContractAbi.fromJson(abiJson, 'AudionNFT');
    final fn = abi.functions.firstWhere((f) => f.name == 'mint');
    final Uint8List bytes = fn.encodeCall([tokenUri]);
    return '0x' + bytesToHex(bytes, include0x: false);
  }

  Future<void> _mint() async {
    if (_isMinting) return;
    setState(() { _isMinting = true; });
    try {
      // MetaMask 존재 확인
      if (!js_util.hasProperty(html.window, 'ethereum')) {
        throw Exception('MetaMask가 감지되지 않았습니다.');
      }
      final eth = js_util.getProperty(html.window, 'ethereum');

      // 계정 요청
      await js_util.promiseToFuture(js_util.callMethod(eth, 'request', [js_util.jsify({'method': 'eth_requestAccounts'})]));
      final List accounts = await js_util.promiseToFuture<List>(
        js_util.callMethod(eth, 'request', [js_util.jsify({'method': 'eth_accounts'})]),
      );
      if (accounts.isEmpty) {
        throw Exception('지갑 계정을 불러오지 못했습니다.');
      }
      final String from = (accounts.first as String).toLowerCase();

      // 네트워크 확인/전환 → Sepolia
      final String chainId = await js_util.promiseToFuture(
        js_util.callMethod(eth, 'request', [js_util.jsify({'method': 'eth_chainId'})]),
      );
      if (chainId.toLowerCase() != _sepoliaChainHex) {
        try {
          await js_util.promiseToFuture(js_util.callMethod(eth, 'request', [
            js_util.jsify({
              'method': 'wallet_switchEthereumChain',
              'params': [
                {
                  'chainId': _sepoliaChainHex,
                }
              ]
            })
          ]));
        } catch (e) {
          throw Exception('Sepolia 네트워크로 전환이 필요합니다.');
        }
      }

      final dataHex = _encodeMintData(_demoTokenUri);
      final tx = {
        'from': from,
        'to': _contractAddress,
        'data': dataHex,
      };

      final String txHash = await js_util.promiseToFuture(
        js_util.callMethod(eth, 'request', [js_util.jsify({'method': 'eth_sendTransaction', 'params': [tx]})]),
      );

      if (!mounted) return;
      _showMintResultDialog(context: context, from: from, txHash: txHash);
      // receipt 폴링하여 Confirmed로 갱신
      final authToken = context.read<AuthenticationBloc>().state.token?.token;
      unawaited(_pollReceiptAndNotify(txHash, authToken));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('민팅 실패: $e')),
      );
    } finally {
      if (mounted) setState(() { _isMinting = false; });
    }
  }
  String _shortenWallet(String w) {
    if (w.isEmpty) return 'Loading...';
    final t = w.trim();
    if (t.length <= 13) return t;
    return '${t.substring(0,6)}...${t.substring(t.length-4).toUpperCase()}';
  }

  String _shortenHex(String h) {
    if (h.isEmpty) return h;
    final t = h.trim();
    if (t.length <= 12) return t;
    return '${t.substring(0,6)}...${t.substring(t.length-4)}';
  }

  Future<void> _pollReceiptAndNotify(String txHash, String? authToken) async {
    try {
      if (!js_util.hasProperty(html.window, 'ethereum')) return;
      final eth = js_util.getProperty(html.window, 'ethereum');
      for (int i = 0; i < 40; i++) { // 최대 ~120초 (3s * 40)
        final receipt = await js_util.promiseToFuture(
          js_util.callMethod(eth, 'request', [js_util.jsify({'method': 'eth_getTransactionReceipt', 'params': [txHash]})]),
        );
        if (receipt != null) {
          // status: 0x1 success, 0x0 failed
          final status = js_util.getProperty(receipt, 'status');
          // tokenId 파싱 (ERC721 Transfer)
          String? tokenIdStr;
          try {
            final logs = js_util.getProperty(receipt, 'logs');
            if (logs != null) {
              final int len = js_util.getProperty(logs, 'length') as int? ?? 0;
              for (int j = 0; j < len; j++) {
                final log = js_util.getProperty(logs, j);
                final topics = js_util.getProperty(log, 'topics');
                final int tlen = topics != null ? (js_util.getProperty(topics, 'length') as int? ?? 0) : 0;
                if (tlen >= 4) {
                  final topic0 = js_util.getProperty(topics, 0) as String?;
                  if (topic0 == '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef') {
                    final t3 = js_util.getProperty(topics, 3) as String?; // tokenId
                    if (t3 != null && t3.startsWith('0x')) {
                      tokenIdStr = BigInt.parse(t3.substring(2), radix: 16).toString();
                      break;
                    }
                  }
                }
              }
            }
          } catch (_) {}
          if (mounted) {
            _mintDialogStatus?.value = status == '0x1' ? 'Confirmed' : 'Failed';
            if (tokenIdStr != null) {
              _mintDialogTokenId?.value = tokenIdStr!;
              // DB 기록 시도
              unawaited(_recordMintToServer(tokenIdStr!, _demoTokenUri, authToken));
            }
          }
          return;
        }
        await Future.delayed(const Duration(seconds: 3));
      }
      if (mounted) {
        _mintDialogStatus?.value = 'Pending';
      }
    } catch (_) {
      // 무시
    }
  }

  ValueNotifier<String>? _mintDialogStatus;
  ValueNotifier<String>? _mintDialogTokenId;
  void _showMintResultDialog({required BuildContext context, required String from, required String txHash}) {
    _mintDialogStatus?.dispose();
    _mintDialogStatus = ValueNotifier<String>('Submitted');
    _mintDialogTokenId?.dispose();
    _mintDialogTokenId = ValueNotifier<String>('Parsing...');
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 360,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF5F5F5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset('assets/images/audion_logo.png', fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You successfully minted 1 NFT from',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _shortenHex(from),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Transaction ID', style: TextStyle(color: Colors.black54)),
                        InkWell(
                          onTap: () {
                            html.window.open('https://sepolia.etherscan.io/tx/$txHash', '_blank');
                          },
                          child: Text(
                            _shortenHex(txHash),
                            style: const TextStyle(decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Status', style: TextStyle(color: Colors.black54)),
                        ValueListenableBuilder<String>(
                          valueListenable: _mintDialogStatus!,
                          builder: (context, v, _) {
                            final color = v == 'Confirmed' ? Colors.green : (v == 'Failed' ? Colors.red : Colors.orange);
                            return Text(v, style: TextStyle(color: color, fontWeight: FontWeight.w600));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Token ID', style: TextStyle(color: Colors.black54)),
                        ValueListenableBuilder<String>(
                          valueListenable: _mintDialogTokenId!,
                          builder: (context, v, _) {
                            return Text(v);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _mintDialogStatus?.dispose();
      _mintDialogStatus = null;
      _mintDialogTokenId?.dispose();
      _mintDialogTokenId = null;
    });
  }

  Future<void> _recordMintToServer(String tokenId, String tokenUri, String? authToken) async {
    if (authToken == null || authToken.isEmpty) return;
    final url = Uri.parse(Endpoints.baseUrl + '/nft/record');
    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + authToken,
        },
        body: '{"tokenId":"$tokenId","metadataUrl":"$tokenUri","modelId":""}',
      );
      // 성공/실패는 조용히 처리
    } catch (e) {
      // 조용히 무시
    }
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fetched) {
      _fetched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AuthenticationBloc>().add(const CheckSession());
        }
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
        title: Text(
          'Mint your voice as an NFT',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              "assets/images/bottom_gradient.png",
              height: 300, // 원하는 높이
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Title',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Enter the title of your NFT',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: Color.fromRGBO(0, 0, 0, 0.1),
                                  width: 1,
                                ),
                              ),
                            ),
                            onChanged: (_) {},
                          ),
                          SizedBox(height: 3),
                          Text(
                            'This field is required.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color.fromRGBO(0, 0, 0, 0.5),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Enter a description (optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onChanged: (_) {},
                          ),
                          SizedBox(height: 3),
                          Text(
                            'You can provide additional context.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color.fromRGBO(0, 0, 0, 0.5),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Visibility',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          SizedBox(
                            child: Row(
                              children: [
                                Container(
                                  height: 36,
                                  width: 164,
                                  alignment: Alignment.center,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Color.fromRGBO(
                                        0,
                                        0,
                                        0,
                                        0.05,
                                      ),
                                      foregroundColor: Colors.black,
                                      fixedSize: Size(164, 36),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    onPressed: () {},
                                    child: Text(
                                      'Public',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  height: 36,
                                  width: 164,
                                  alignment: Alignment.center,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Color.fromRGBO(
                                        0,
                                        0,
                                        0,
                                        0.05,
                                      ),
                                      foregroundColor: Colors.black,
                                      fixedSize: Size(164, 36),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    onPressed: () {},
                                    child: Text(
                                      'Private',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Choose who can view your NFT.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color.fromRGBO(0, 0, 0, 0.5),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Tags',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Add tags (optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onChanged: (_) {},
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Separate with commas.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color.fromRGBO(0, 0, 0, 0.5),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Wallet Info',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Your wallet address and fees',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color.fromRGBO(0, 0, 0, 0.5),
                            ),
                          ),
                          SizedBox(height: 3),
                          SizedBox(
                            child: Row(
                              children: [
                                Container(
                                  height: 76,
                                  width: 164,
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Color(0x1A000000),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Wallet Address',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color.fromRGBO(0, 0, 0, 0.5),
                                        ),
                                      ),
                                      BlocBuilder<AuthenticationBloc, AuthState>(
                                        builder: (context, state) {
                                          final w = state.me?.walletAddress ?? '';
                                          final display = _shortenWallet(w);
                                          return Text(
                                            display,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  height: 76,
                                  width: 164,
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Color(0x1A000000),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Minting Fee',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color.fromRGBO(0, 0, 0, 0.5),
                                        ),
                                      ),
                                      Text(
                                        '0.00 ETH',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          SizedBox(
                            child: Row(
                              children: [
                                Container(
                                  height: 42,
                                  width: 164,
                                  alignment: Alignment.center,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      fixedSize: Size(164, 42),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    onPressed: () {},
                                    child: Text(
                                      'Loading...',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  height: 42,
                                  width: 164,
                                  alignment: Alignment.center,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      fixedSize: Size(164, 42),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    onPressed: _isMinting ? null : _mint,
                                    child: Text(
                                      _isMinting ? 'Minting...' : 'Mint NFT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomBar(),
    );
  }
}

class NftFormPage extends StatefulWidget {
  @override
  _NftFormPageState createState() => _NftFormPageState();
}

class _NftFormPageState extends State<NftFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mint your NFT")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Title",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: "Enter the title of your NFT",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "This field is required.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // 입력값 확인
                    // submit pressed
                  }
                },
                child: const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
