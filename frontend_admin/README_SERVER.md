# 관리자 대시보드 실행 방법

## CORS 에러 해결

HTML 파일을 직접 열면 (`file://` 프로토콜) CORS 에러가 발생합니다. 
로컬 서버를 통해 실행해야 합니다.

## 방법 1: Python HTTP 서버 사용 (권장)

### Windows:
```bash
# frontend_admin 폴더에서 실행
start-server.bat
```

또는 직접 실행:
```bash
cd frontend_admin
python -m http.server 8001
```

### Mac/Linux:
```bash
# frontend_admin 폴더에서 실행
chmod +x start-server.sh
./start-server.sh
```

또는 직접 실행:
```bash
cd frontend_admin
python3 -m http.server 8001
```

브라우저에서 `http://localhost:8001` 접속

## 방법 2: VS Code Live Server 확장 사용

1. VS Code에서 `Live Server` 확장 설치
2. `index.html` 파일에서 우클릭 → `Open with Live Server`

## 방법 3: Node.js http-server 사용

```bash
# 전역 설치 (한 번만)
npm install -g http-server

# 실행
cd frontend_admin
http-server -p 8001
```

## 백엔드 서버 확인

관리자 대시보드가 작동하려면 백엔드 서버가 실행 중이어야 합니다:

```bash
# backend 폴더에서
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

또는 Docker Compose 사용:
```bash
docker-compose up
```

## 접속 주소

- 프론트엔드 (관리자 대시보드): http://localhost:8001
- 백엔드 API: http://localhost:8000
- API Health Check: http://localhost:8000/health

## 문제 해결

### CORS 에러가 계속 발생하는 경우:

1. 백엔드 서버가 실행 중인지 확인
2. `backend/app/main.py`에서 CORS 설정 확인:
   ```python
   app.add_middleware(
       CORSMiddleware,
       allow_origins=["*"],  # 개발용
       allow_credentials=True,
       allow_methods=["*"],
       allow_headers=["*"],
   )
   ```
3. 브라우저 콘솔에서 정확한 에러 메시지 확인
4. 네트워크 탭에서 요청이 실제로 전송되는지 확인
