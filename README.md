# Audion 🎙️ → NFT 프로젝트

Flutter 기반 음성 녹음 → AI 학습 → NFT 민팅 앱
- **Flutter**: 모바일 앱 프론트엔드
- **Web3dart**: 블록체인 연동
- **WalletConnect/MetaMask**: 지갑 연결
- **백엔드**: 음성 모델 학습 및 NFT 민팅 처리

---

## 📂 프로젝트 구조
APP/
├─ android/ # 안드로이드 네이티브 코드
├─ ios/ # iOS 네이티브 코드
├─ lib/ # Flutter 앱 핵심 소스코드
│ ├─ screens/ # 화면(UI) 단위 구성
│ ├─ services/ # API/지갑/NFT/오디오 서비스
│ ├─ models/ # 데이터 모델 정의
│ ├─ providers/ # 상태 관리 (Provider/Bloc)
│ └─ widgets/ # 공용 위젯
├─ test/ # 단위 테스트 코드
├─ pubspec.yaml # 의존성 정의
├─ pubspec.lock # 의존성 버전 고정
└─ analysis_options.yaml # 코드 스타일 규칙

---

## 🚀 실행 방법
MacOS 버전

### 1. 레포지토리 클론
```bash
git clone https://github.com/2025-Imagine-Company/APP.git
cd audion/APP

### 2. 패키지 클린 설치 스크립트
```bash
sh setup.sh


### 3. 앱 실행
flutter run
