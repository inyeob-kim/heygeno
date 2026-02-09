# HeyGeno Landing 배포 가이드

## 문제 해결

현재 빈 페이지가 나오는 이유는 `heygeno-landing`에 빌드된 파일이 없기 때문입니다.

## 배포 방법

### 1. heygeno-landing-figma 빌드

```bash
cd heygeno-landing-figma
npm install  # 처음 한 번만
npm run build
```

### 2. 빌드된 파일을 heygeno-landing으로 복사

**Windows:**
```bash
xcopy /E /I /Y build\* ..\heygeno-landing\
```

**Mac/Linux:**
```bash
cp -r build/* ../heygeno-landing/
```

또는 자동화 스크립트 사용:
- Windows: `build-and-deploy.bat` 실행
- Mac/Linux: `./build-and-deploy.sh` 실행

### 3. Wrangler로 배포

```bash
cd ../heygeno-landing
wrangler pages deploy
```

## MIME 타입 문제 해결

`_headers` 파일을 추가하여 JavaScript 파일이 올바른 MIME 타입으로 서빙되도록 설정했습니다.

## 자동화 (선택사항)

`package.json`에 `build:deploy` 스크립트를 추가했습니다:

```bash
cd heygeno-landing-figma
npm run build:deploy
cd ../heygeno-landing
wrangler pages deploy
```
