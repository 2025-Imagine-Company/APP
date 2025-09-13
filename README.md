# Audion 🎙️ → NFT 프로젝트

Flutter 기반 음성 녹음 → AI 학습 → NFT 민팅 앱
- **Flutter**: 모바일 앱 프론트엔드
- **Web3dart**: 블록체인 연동
- **WalletConnect/MetaMask**: 지갑 연결
- **백엔드**: 음성 모델 학습 및 NFT 민팅 처리

---
```
## 📂 프로젝트 구조
APP/
├─ android/               # 안드로이드 네이티브 코드
├─ ios/                   # iOS 네이티브 코드
├─ lib/                   # Flutter 앱 핵심 소스코드
│   ├─ core/              # 공통 기능 (모든 도메인에서 재사용)
│   │   ├─ constants/      # 앱 전역 상수 (API 엔드포인트, 공통 문자열 키)
│   │   ├─ utils/          # 유틸리티 함수 (날짜/시간 포맷터, 이메일, 비밀번호 체크)
│   │   ├─ services/       # 공통 서비스 (API, 네트워크 등)
│   │   ├─ themes/         # 앱 테마, 스타일
│   │   ├─ errors/         # 오류 처리 관련 코드
│   │   └─ widgets/        # 공용 UI 위젯들 (버튼, 카드 등)
│   │
│   ├─ features/           # 각 도메인 별 주요 기능 (도메인 단위)
│   │   ├─ authentication/ # 인증 도메인
│   │   │   ├─ data/        # 데이터 계층 (API 호출, 로컬 DB)
│   │   │   ├─ domain/      # 도메인 모델 (비즈니스 로직)
│   │   │   ├─ presentation/ # UI 계층 (화면, 상태 관리)
│   │   │   └─ authentication_bloc.dart # 상태 관리
│   │   │
│   │   ├─ user_profile/    # 사용자 프로필 도메인
│   │   │   ├─ data/
│   │   │   ├─ domain/
│   │   │   └─ presentation/
│   │   │
│   │   ├─ product/         # 상품 도메인
│   │   │   ├─ data/
│   │   │   ├─ domain/
│   │   │   └─ presentation/
│   │   │
│   │   └─ wallet/          # 지갑 관련 도메인
│   │       ├─ data/
│   │       ├─ domain/
│   │       └─ presentation/
│   │
│   └─ screens/            # 화면 단위 UI 구성 
│
├─ test/                   # 단위 테스트 코드
├─ pubspec.yaml            # 의존성 정의
├─ pubspec.lock            # 의존성 버전 고정
└─ analysis_options.yaml   # 코드 스타일 규칙

```
---
