# Audion APP (Flutter Web)

## 실행 방법

개발/데모는 백엔드 HTTPS가 필요합니다. 현재 백엔드: https://audion.site

### 릴리스 빌드 생성

```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://audion.site
```

### 로컬 정적 서버로 서빙(예: 8083)

```bash
python3 -m http.server 8083 --directory build/web
```

### Cloudflare Tunnel로 공개 URL 발급(선택)

```bash
cloudflared tunnel --url http://localhost:8083
```

발급된 `https://*.trycloudflare.com` 주소를 MetaMask 인앱브라우저에서 열어 데모합니다.

## 로그인(웹3)
- MetaMask personal_sign(EIP‑191)만 사용합니다.
- 서버에 전송 시:
  - walletAddress: 소문자
  - message: "Sign this message to login"
  - signature: 0x + 130 hex(65 bytes)

## 주의사항
- build/ 등 생성물은 커밋하지 않습니다.
- API_BASE_URL은 배포/환경에 맞게 `--dart-define`으로 주입하세요.
