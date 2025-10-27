import 'package:flutter/material.dart';

class RecordWarningScreen extends StatelessWidget {
  const RecordWarningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                '주의사항 및 NFT 서비스\n이용 안내',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 30),

              // 스크롤 영역
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: const [
                      _WarningCard(
                        title: '녹음 및 AI 학습 안내',
                        lines: [
                          '이 서비스는 사용자의 음성을 녹음합니다.',
                          '녹음된 음성은 AI 음성 모델 학습에 사용됩니다.',
                          '개인정보(실명, 연락처, 주소 등)와 민감한 발언은 말하지 마세요.',
                          '부적절한 발언(타인 비방, 범죄 관련 내용 등)은 금지됩니다.',
                          '녹음이 업로드되면 서버에 저장될 수 있습니다.',
                        ],
                      ),
                      SizedBox(height: 16),
                      _WarningCard(
                        title: 'NFT 생성 및 공개 범위',
                        lines: [
                          '녹음된 음성으로 생성된 결과물은 NFT 형태로 발행될 수 있습니다.',
                          'NFT는 제3자에게 공개되거나 전송될 수 있습니다.',
                          'NFT 발행 후에는 완전한 삭제가 어려울 수 있습니다.',
                          '본인 목소리를 외부에 공개하고 싶지 않다면 계속 진행하지 마세요.',
                          '서비스 이용은 위 내용을 이해하고 동의한 것으로 간주됩니다.',
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // 하단 버튼
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/recording');
              },
              child: const Text("확인하기"),
            ),
          ),
        ),
      ),
    );
  }
}

// 카드 위젯
class _WarningCard extends StatelessWidget {
  const _WarningCard({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // 항목 리스트
          ...List.generate(
            lines.length,
                (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 숫자 동그라미 대신 단순 번호 "1."
                  Text(
                    '${i + 1}. ',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  // 내용
                  Expanded(
                    child: Text(
                      lines[i],
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
