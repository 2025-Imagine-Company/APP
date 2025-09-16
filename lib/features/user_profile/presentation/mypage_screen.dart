import 'package:APP/core/widgets/custom_bottom_bar.dart';
import 'package:flutter/material.dart';

class MypageScreen extends StatefulWidget {
  const MypageScreen({super.key});

  @override
  State<MypageScreen> createState() => _MypageScreenState();
}

class _MypageScreenState extends State<MypageScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFE9E9E9), // 전체 배경색
        appBar: AppBar(
          centerTitle: false,
          elevation: 0,
          backgroundColor: const Color(0xFFE9E9E9), // 전체 배경색
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const[
              Text(
                'MY PAGE',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0x80000000),
                ),
              ),
              Text(
                '마이페이지',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            SizedBox(
              height: 70,
              child: Row(
                children: [
                  SizedBox(width: 8,),
                  Icon(Icons.person, color: Colors.black, size: 40,),
                  SizedBox(width: 8,),
                  Container(
                    width: 284,
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8,),
                        Text(
                          'Name',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Wallet Address',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0x80000000)
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8,),
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
                  SizedBox(height: 8,),
                  Expanded(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          SizedBox(width: 10,),
                          ActivitySummary(),
                          SizedBox(width: 10,),
                          ActivitySummary(),
                          SizedBox(width: 10,),
                          ActivitySummary(),
                          SizedBox(width: 10,),
                          ActivitySummary(),
                          SizedBox(width: 10,),
                          ActivitySummary(),
                          SizedBox(width: 10,),
                        ],
                      )
                  ),
                  SizedBox(height: 8,),
                ],
              ),
            ),
            Expanded(child: Container(
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
                  SizedBox(height: 8,),
                  Expanded(
                      child: ListView.separated(
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          return MyNFT(name:'NFT 1', onEdit: (name) => MyNFT._showEditDialog(context, name));
                        },
                        separatorBuilder: (context, index) {
                          return Divider();  // 각 아이템 사이에 자동으로 삽입
                        },
                      )
                  ),
                ],
              ),
            )),
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
          borderRadius: BorderRadius.circular(6)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Recordings',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            Text('25',
              style: TextStyle(
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
              // 이름 재설정 버튼
              TextButton(
                style: TextButton.styleFrom (
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  // 이름 재설정 동작
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('이름 재설정 기능은 아직 구현되지 않았습니다.')),
                  );
                },
                child: const Text('이름 재설정'),
              ),
              TextButton(
                style: TextButton.styleFrom (
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  // 이름 재설정 동작
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('보내기 기능은 아직 구현되지 않았습니다.')),
                  );
                },
                child: const Text('보내기'),
              ),
              TextButton(
                style: TextButton.styleFrom (
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  // 이름 재설정 동작
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('숨기기 기능은 아직 구현되지 않았습니다.')),
                  );
                },
                child: const Text('숨기기'),
              ),
              TextButton(
                style: TextButton.styleFrom (
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
          )

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
                        child: Text('🎤'),
                    ),
                    SizedBox(width: 8,),
                    SizedBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Voice NFT1',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          Text('Recording1',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0x80000000),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                )
              ),
              SizedBox(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Date:'),
                    Text('01/01/2025')
                  ],
                ),
              ),
            ],
          ),
        )
    );
  }
}

