import 'package:app/core/widgets/custom_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../authentication/presentation/authentication_bloc.dart';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'package:web3dart/contracts.dart';
import 'package:web3dart/credentials.dart' show EthereumAddress;
import 'package:web3dart/crypto.dart' show bytesToHex;
import 'package:app/core/services/http_client.dart';
import 'package:app/core/services/token_provider.dart';
import 'package:app/features/record/data/record_api.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MypageScreen extends StatefulWidget {
  const MypageScreen({super.key});

  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends State<MypageScreen> {
  bool _fetched = false;
  bool _loadingNfts = false;
  List<BigInt> _myTokenIds = [];
  String? _nftError;

  // 음성 모델 상태
  final _voiceApi = VoiceApi(HttpClient(SecureTokenProvider()));
  bool _loadingModels = false;
  String? _modelError;
  List<Map<String, dynamic>> _myModels = [];

  // 정상(DONE) 모델 수 계산된 값
  int get _doneModelCount {
    return _myModels
        .where((m) => (m['status'] ?? '').toString().toUpperCase() == 'DONE')
        .length;
  }

  // 펼침 상태
  String? _expandedModelId;
  Map<String, dynamic>? _expandedDetail;
  bool _expandedLoading = false;

  static const String _contractAddress = '0x147cf4ba7825a8e70d0a016f9ad523b2bacdde36';
  static const String _sepoliaChainHex = '0xaa36a7';

  String _shortenWallet(String w) {
    if (w.isEmpty) return 'Wallet Address';
    final wallet = w.trim();
    if (wallet.length <= 13) return wallet;
    final head = wallet.substring(0, 6);
    final tail = wallet.substring(wallet.length - 5).toUpperCase();
    return '$head...$tail';
  }

  static String _shortenWalletStatic(String w) {
    if (w.isEmpty) return 'Wallet Address';
    final wallet = w.trim();
    if (wallet.length <= 13) return wallet;
    final head = wallet.substring(0, 6);
    final tail = wallet.substring(wallet.length - 5).toUpperCase();
    return '$head...$tail';
  }

  Future<void> _loadMyNfts(String wallet) async {
    setState(() {
      _loadingNfts = true;
      _nftError = null;
    });
    try {
      if (!js_util.hasProperty(html.window, 'ethereum')) {
        throw Exception('MetaMask가 필요합니다.');
      }
      final eth = js_util.getProperty(html.window, 'ethereum');

      // 체인 체크
      final String chainId = await js_util.promiseToFuture(
        js_util.callMethod(eth, 'request', [js_util.jsify({'method': 'eth_chainId'})]),
      );
      if (chainId.toLowerCase() != _sepoliaChainHex) {
        throw Exception('Sepolia로 전환 후 다시 시도하세요.');
      }

      // balanceOf
      final abiBalance = ContractAbi.fromJson(
        '[{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]',
        'ERC721',
      );
      final fnBal = abiBalance.functions.firstWhere((f) => f.name == 'balanceOf');
      final dataBal = bytesToHex(fnBal.encodeCall([EthereumAddress.fromHex(wallet)]), include0x: true);
      final balHex = await js_util.promiseToFuture(
        js_util.callMethod(eth, 'request', [
          js_util.jsify({
            'method': 'eth_call',
            'params': [
              {'to': _contractAddress, 'data': dataBal},
              'latest'
            ]
          })
        ]),
      ) as String;
      final balance = BigInt.parse(balHex.substring(2), radix: 16);

      // nextTokenId
      final abiNext = ContractAbi.fromJson(
        '[{"inputs":[],"name":"nextTokenId","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]',
        'AudionNFT',
      );
      final fnNext = abiNext.functions.firstWhere((f) => f.name == 'nextTokenId');
      final dataNext = bytesToHex(fnNext.encodeCall([]), include0x: true);
      final nextHex = await js_util.promiseToFuture(
        js_util.callMethod(eth, 'request', [
          js_util.jsify({
            'method': 'eth_call',
            'params': [
              {'to': _contractAddress, 'data': dataNext},
              'latest'
            ]
          })
        ]),
      ) as String;
      final nextId = BigInt.parse(nextHex.substring(2), radix: 16);

      // 소유 토큰 수집
      final abiOwnerOf = ContractAbi.fromJson(
        '[{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"ownerOf","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"}]',
        'ERC721',
      );
      final fnOwner = abiOwnerOf.functions.firstWhere((f) => f.name == 'ownerOf');

      final List<BigInt> owned = [];
      for (BigInt id = BigInt.one; id <= nextId; id = id + BigInt.one) {
        final callData = bytesToHex(fnOwner.encodeCall([id]), include0x: true);
        final res = await js_util.promiseToFuture(
          js_util.callMethod(eth, 'request', [
            js_util.jsify({
              'method': 'eth_call',
              'params': [
                {'to': _contractAddress, 'data': callData},
                'latest'
              ]
            })
          ]),
        ) as String;
        if (res is String && res.length >= 66) {
          final addr = '0x' + res.substring(res.length - 40);
          if (addr.toLowerCase() == wallet.toLowerCase()) {
            owned.add(id);
            if (owned.length >= balance.toInt()) break;
          }
        }
      }

      setState(() => _myTokenIds = owned);
    } catch (e) {
      setState(() => _nftError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingNfts = false);
    }
  }

  Future<void> _loadMyModels() async {
    setState(() {
      _loadingModels = true;
      _modelError = null;
    });
    try {
      final list = await _voiceApi.getMyModels();
      _myModels = list
          .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // 모델 로드된 뒤 ActivitySummary는 setState로 다시 그려지므로
      // 별도 작업 필요 없다.
      if (mounted) setState(() {});
    } catch (e) {
      _modelError = e.toString();
    } finally {
      if (mounted) setState(() => _loadingModels = false);
    }
  }

  Future<void> _onTapModelTile(String modelId) async {
    if (_expandedModelId == modelId) {
      setState(() {
        _expandedModelId = null;
        _expandedDetail = null;
      });
      return;
    }
    setState(() {
      _expandedModelId = modelId;
      _expandedDetail = null;
      _expandedLoading = true;
    });
    try {
      final detail = await _voiceApi.getModel(modelId);
      if (!mounted) return;
      setState(() => _expandedDetail = Map<String, dynamic>.from(detail));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모델 상세 조회 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _expandedLoading = false);
    }
  }

  Future<void> _confirmAndGoMint({
    required String modelId,
    required String modelName,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('민팅'),
        content: const Text('이 음성 모델로 민팅하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (ok == true) {
      Navigator.pushNamed(
        context,
        '/minting',
        arguments: {
          'modelId': modelId,
          'modelName': modelName,
          'previewUrl': (_expandedDetail?['previewUrl'] ?? '').toString(),
          'modelPath': (_expandedDetail?['modelPath'] ?? '').toString(),
        },
      );
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
          final w = context.read<AuthenticationBloc>().state.me?.walletAddress;
          if (w != null && w.isNotEmpty) {
            _loadMyModels();
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MY PAGE', style: TextStyle(fontSize: 14)),
            Text('마이페이지', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
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
              height: 300,
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              SizedBox(
                height: 80,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    const Icon(Icons.person, color: Colors.black, size: 40),
                    const SizedBox(width: 8),
                    Container(
                      width: 284,
                      padding: const EdgeInsets.all(5),
                      child: BlocBuilder<AuthenticationBloc, AuthState>(
                        builder: (context, state) {
                          final displayName =
                              state.me?.displayName ?? 'Name';
                          final walletFull =
                              state.me?.walletAddress ?? '';
                          final wallet = _shortenWallet(walletFull);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                wallet,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0x80000000),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Text(
                        'Activity Summary',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          const SizedBox(width: 10),
                          // 여기 숫자 전달
                          ActivitySummary(
                            totalDoneModels: _doneModelCount,
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('내 모델 관리',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      BlocBuilder<AuthenticationBloc, AuthState>(
                        builder: (context, state) {
                          return Expanded(
                            child: _loadingModels
                                ? const Center(
                              child: CircularProgressIndicator(),
                            )
                                : _modelError != null
                                ? Center(
                              child: Text(_modelError!),
                            )
                                : RefreshIndicator(
                              onRefresh: _loadMyModels,
                              child: _myModels.isEmpty
                                  ? ListView(
                                children: const [
                                  SizedBox(height: 120),
                                  Center(
                                    child: Text(
                                        '등록된 음성 모델이 없습니다.'),
                                  ),
                                ],
                              )
                                  : ListView.separated(
                                itemCount:
                                _myModels.length,
                                separatorBuilder:
                                    (_, __) =>
                                const Divider(
                                  color: Color(
                                      0x1A000000),
                                  thickness: 1,
                                ),
                                itemBuilder:
                                    (context, index) {
                                  final m =
                                  _myModels[index];
                                  final name = (m[
                                  'modelName'] ??
                                      '이름 없음')
                                      .toString();
                                  final status = (m[
                                  'status'] ??
                                      'UNKNOWN')
                                      .toString();
                                  final created = (m[
                                  'createdAt'] ??
                                      '')
                                      .toString();
                                  final modelId = (m[
                                  'modelId'] ??
                                      '')
                                      .toString();

                                  final isExpanded =
                                      _expandedModelId ==
                                          modelId;

                                  return Column(
                                    children: [
                                      _ModelTile(
                                        title: name,
                                        subtitle:
                                        '상태: $status · 생성: ${created.isEmpty ? '-' : created}',
                                        status:
                                        status,
                                        onTap: () =>
                                            _onTapModelTile(
                                                modelId),
                                      ),
                                      if (isExpanded &&
                                          _expandedLoading)
                                        const Padding(
                                          padding: EdgeInsets
                                              .symmetric(
                                              horizontal:
                                              12,
                                              vertical:
                                              8),
                                          child:
                                          LinearProgressIndicator(
                                            minHeight:
                                            2,
                                          ),
                                        ),
                                      if (isExpanded &&
                                          !_expandedLoading)
                                        _ModelActionBox(
                                          previewUrl: (_expandedDetail?[
                                          'previewUrl'] ??
                                              '')
                                              .toString(),
                                          onMint: () =>
                                              _confirmAndGoMint(
                                                modelId:
                                                modelId,
                                                modelName:
                                                name,
                                              ),
                                          onPlay:
                                              () {
                                            final url = (_expandedDetail?['previewUrl'] ??
                                                '')
                                                .toString();
                                            if (url
                                                .isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('미리보기 URL이 없습니다.'),
                                                ),
                                              );
                                              return;
                                            }
                                            if (kIsWeb) {
                                              html.window.open(
                                                  url,
                                                  '_blank');
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('미리보기: $url'),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomBar(),
    );
  }
}

class ActivitySummary extends StatelessWidget {
  final int totalDoneModels; // <- 추가된 필드

  const ActivitySummary({
    super.key,
    required this.totalDoneModels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 76,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0x1A000000), width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Recordings',
              style: TextStyle(fontSize: 14)),
          Text(
            '$totalDoneModels', // <- 여기 동적 표시
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class MyNFT extends StatelessWidget {
  final ValueChanged<String>? onEdit;
  final String name;

  const MyNFT({super.key, this.onEdit, required this.name});

  static void _showEditDialog(BuildContext context, String nftName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: Colors.black),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('이름 재설정 기능은 아직 구현되지 않았습니다.'),
                    ),
                  );
                },
                child: const Text('이름 재설정'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: Colors.black),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('보내기 기능은 아직 구현되지 않았습니다.'),
                    ),
                  );
                },
                child: const Text('보내기'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: Colors.black),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('숨기기 기능은 아직 구현되지 않았습니다.'),
                    ),
                  );
                },
                child: const Text('숨기기'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Color(0xFFFF2424),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('플레이 기능은 아직 구현되지 않았습니다.'),
                    ),
                  );
                },
                child: const Text('Play'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onEdit?.call(name),
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0x0D000000),
                  backgroundImage:
                  AssetImage('assets/images/audion_logo.png'),
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Text('Voice NFT',
                        style: TextStyle(fontSize: 14)),
                    Text(
                      'Recording',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0x80000000),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              crossAxisAlignment:
              CrossAxisAlignment.end,
              children: [
                Text('Date:'),
                Text('01/01/2025'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelActionBox extends StatelessWidget {
  final String previewUrl;
  final VoidCallback onMint;
  final VoidCallback onPlay;

  const _ModelActionBox({
    Key? key,
    required this.previewUrl,
    required this.onMint,
    required this.onPlay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor:
                    const Color(0xFFEDEDED),
                    foregroundColor: Colors.black,
                    padding:
                    const EdgeInsets.symmetric(
                        vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onMint,
                  child: const Text('보내기'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor:
                    const Color(0xFFEDEDED),
                    foregroundColor: Colors.black,
                    padding:
                    const EdgeInsets.symmetric(
                        vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(8),
                    ),
                  ),
                  onPressed:
                  previewUrl.isEmpty ? null : onPlay,
                  child: const Text('Play'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModelTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final VoidCallback? onTap;

  const _ModelTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.status,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final up = status.toUpperCase();
    Color c = Colors.grey;
    if (up == 'DONE') c = Colors.green;
    if (up == 'TRAINING') c = Colors.orange;
    if (up == 'ERROR') c = Colors.red;

    return ListTile(
      onTap: onTap,
      leading: const CircleAvatar(
        radius: 18,
        backgroundColor: Color(0x0D000000),
        backgroundImage:
        AssetImage('assets/images/audion_logo.png'),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0x80000000),
        ),
      ),
      trailing: Chip(
        label: Text(up),
        backgroundColor: c.withOpacity(.15),
        labelStyle: TextStyle(
          color: c,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: c.withOpacity(.3)),
      ),
    );
  }
}
