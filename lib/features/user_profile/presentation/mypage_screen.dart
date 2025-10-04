import 'package:app/core/widgets/custom_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../authentication/presentation/authentication_bloc.dart';
import 'dart:js_util' as js_util;
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:web3dart/contracts.dart';
import 'package:web3dart/credentials.dart' show EthereumAddress;
import 'package:web3dart/crypto.dart' show bytesToHex;

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
        // 네트워크 전환은 여기선 강제하지 않고 목록만 실패 처리
        throw Exception('Sepolia로 전환 후 다시 시도하세요.');
      }

      // balanceOf
      final abiBalance = ContractAbi.fromJson('[{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]', 'ERC721');
      final fnBal = abiBalance.functions.firstWhere((f) => f.name == 'balanceOf');
      final dataBal = bytesToHex(fnBal.encodeCall([EthereumAddress.fromHex(wallet)]), include0x: true);
      final balHex = await js_util.promiseToFuture(
        js_util.callMethod(eth, 'request', [js_util.jsify({'method': 'eth_call', 'params': [
          {
            'to': _contractAddress,
            'data': dataBal,
          },
          'latest'
        ]})]),
      ) as String;
      final balance = BigInt.parse(balHex.substring(2), radix: 16);

      // owner의 단순 토큰 나열: tokenOfOwnerByIndex가 없으므로 1..nextTokenId 추정
      final abiNext = ContractAbi.fromJson('[{"inputs":[],"name":"nextTokenId","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]', 'AudionNFT');
      final fnNext = abiNext.functions.firstWhere((f) => f.name == 'nextTokenId');
      final dataNext = bytesToHex(fnNext.encodeCall([]), include0x: true);
      final nextHex = await js_util.promiseToFuture(
        js_util.callMethod(eth, 'request', [js_util.jsify({'method': 'eth_call', 'params': [
          {
            'to': _contractAddress,
            'data': dataNext,
          },
          'latest'
        ]})]),
      ) as String;
      final nextId = BigInt.parse(nextHex.substring(2), radix: 16);

      final abiOwnerOf = ContractAbi.fromJson('[{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"ownerOf","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"}]', 'ERC721');
      final fnOwner = abiOwnerOf.functions.firstWhere((f) => f.name == 'ownerOf');

      final List<BigInt> owned = [];
      for (BigInt id = BigInt.one; id <= nextId; id = id + BigInt.one) {
        final callData = bytesToHex(fnOwner.encodeCall([id]), include0x: true);
        final res = await js_util.promiseToFuture(
          js_util.callMethod(eth, 'request', [js_util.jsify({'method': 'eth_call', 'params': [
            {
              'to': _contractAddress,
              'data': callData,
            },
            'latest'
          ]})]),
        ) as String;
        if (res is String && res.length >= 66) {
          final addr = '0x' + res.substring(res.length - 40);
          if (addr.toLowerCase() == wallet.toLowerCase()) {
            owned.add(id);
            if (owned.length >= balance.toInt()) break;
          }
        }
      }

      setState(() {
        _myTokenIds = owned;
      });
    } catch (e) {
      setState(() {
        _nftError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() { _loadingNfts = false; });
      }
    }
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fetched) {
      _fetched = true;
      // 첫 의존성 준비 후 호출하여 Provider 트리 접근 안정화
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AuthenticationBloc>().add(const CheckSession());
          final w = context.read<AuthenticationBloc>().state.me?.walletAddress;
          if (w != null && w.isNotEmpty) {
            _loadMyNfts(w);
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'MY PAGE',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              '마이페이지',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
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
              height: 300, // 원하는 높이
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              SizedBox(
                height: 80,
                child: Row(
                  children: [
                    SizedBox(width: 8),
                    Icon(Icons.person, color: Colors.black, size: 40),
                    SizedBox(width: 8),
                    Container(
                      width: 284,
                      padding: const EdgeInsets.all(5),
                      child: BlocBuilder<AuthenticationBloc, AuthState>(
                        builder: (context, state) {
                          final displayName = state.me?.displayName ?? 'Name';
                          final walletFull = state.me?.walletAddress ?? '';
                          final wallet = _shortenWallet(walletFull);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8),
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                wallet,
                                style: TextStyle(
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
                    SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: const Text(
                        'Activity Summary',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          SizedBox(width: 10),
                          ActivitySummary(),
                          SizedBox(width: 10),
                          ActivitySummary(),
                          SizedBox(width: 10),
                          ActivitySummary(),
                          SizedBox(width: 10),
                          ActivitySummary(),
                          SizedBox(width: 10),
                          ActivitySummary(),
                          SizedBox(width: 10),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '내 NFT 관리',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      BlocBuilder<AuthenticationBloc, AuthState>(
                        builder: (context, state) {
                          final currentWallet = state.me?.walletAddress ?? '';
                          return Expanded(
                            child: _loadingNfts
                                ? const Center(child: CircularProgressIndicator())
                                : _nftError != null
                                    ? Center(child: Text(_nftError!))
                                    : RefreshIndicator(
                                        onRefresh: () async {
                                          if (currentWallet.isNotEmpty) {
                                            await _loadMyNfts(currentWallet);
                                          }
                                        },
                                        child: ListView.separated(
                                          itemCount: _myTokenIds.length,
                                          itemBuilder: (context, index) {
                                            final tokenId = _myTokenIds[index];
                                            return MyNFT(
                                              name: 'Audion NFT (${tokenId.toInt()})',
                                              onEdit: (name) => MyNFT._showEditDialog(context, name),
                                            );
                                          },
                                          separatorBuilder: (context, index) => const Divider(color: Color(0x1A000000), thickness: 1),
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
  const ActivitySummary({super.key});

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
          Text('Total Recordings', style: TextStyle(fontSize: 14)),
          Text(
            '25',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              // 이름 재설정 버튼
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                onPressed: () {
                  // 이름 재설정 동작
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('이름 재설정 기능은 아직 구현되지 않았습니다.')),
                  );
                },
                child: const Text('이름 재설정'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                onPressed: () {
                  // 이름 재설정 동작
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('보내기 기능은 아직 구현되지 않았습니다.')),
                  );
                },
                child: const Text('보내기'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                onPressed: () {
                  // 이름 재설정 동작
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('숨기기 기능은 아직 구현되지 않았습니다.')),
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
                  // 이름 재설정 동작
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('플레이 기능은 아직 구현되지 않았습니다.')),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0x0D000000),
                    backgroundImage: const AssetImage('assets/images/audion_logo.png'),
                  ),
                  SizedBox(width: 8),
                  SizedBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(name, style: TextStyle(fontSize: 14)),
                        Text(
                          'Recording1',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0x80000000),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [Text('Date:'), Text('01/01/2025')],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
