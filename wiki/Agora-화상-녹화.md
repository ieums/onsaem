# Agora 화상·녹화 연동

> 카메라만 녹화되던 한계를 Web Page Recording으로 전환해, 화이트보드 화면과 음성을 함께 녹화하고 복습 입력으로 재활용.

## 한눈에 보기

| 항목 | 내용 |
|---|---|
| 녹화 방식 | Agora Cloud Recording — Web Page Recording (scene=1) |
| 녹화 대상 | `recorder.html` (STOMP 화이트보드 + Agora Web SDK 음성) |
| RTC 토큰 | Agora 공식 알고리즘 서버 포팅 (HMAC-SHA256) |
| 녹화봇 인가 | 채널 스코프 JWT(`wbToken`)로 화이트보드 구독(읽기 전용) |
| 인프라 | HTTPS 필수 → nginx + Let's Encrypt (도메인 3-35-10-251.sslip.io) |

## 문제 상황

- 기본 녹화는 카메라 스트림만 담겨, **정작 수업의 핵심인 화이트보드 판서가 녹화되지 않음**.
- 화면+음성을 함께 담으려면 별도 영상 합성이 필요 → 복잡·비용.
- 브라우저 미디어(오디오 구독) 권한은 **secure context(HTTPS)** 를 요구 → 생 IP·HTTP로는 녹화봇 페이지가 동작 안 함.
- Agora RTC 토큰 발급이 초기에 동작하지 않아 채널 입장이 막힘.
- 화이트보드 STOMP에 JWT 인가가 도입되면서 튜터/학생이 아닌 **녹화봇은 구독이 거부됨** → 별도 인가 수단 필요.

## 해결 방법

### 인과 사슬 (왜 HTTPS 인프라까지 갔나)

```mermaid
flowchart TB
    A["카메라만 녹화되는 한계"] --> B["Web Page Recording 방식 전환"]
    B --> C["녹화봇이 recorder.html 을 Chrome 으로 로드"]
    C --> D["Agora Web SDK 오디오 구독 = 브라우저 미디어 권한 필요"]
    D --> E["미디어 권한은 secure context(HTTPS) 필수"]
    E --> F["도메인(sslip.io) + Let's Encrypt SSL + nginx TLS 종단 구축"]
    F --> G["recorder.html 이 화이트보드 + 음성 렌더"]
    G --> H["녹화봇이 페이지 전체 녹화 → S3 (mp4)"]
    H --> I["복습 파이프라인 입력 (전사·요약)"]
```

### AgoraRecordingService (Web Page Recording)

- acquire: `clientRequest.scene = 1` (Web Page Recording 모드)
- start: `mode/web/start`, `extensionServices[].serviceName = "web_recorder_service"`, `errorHandlePolicy = "error_abort"`, `maxRecordingHour = 1`
- recorder URL: `{recorderUrlBase}?channel={channelName}&orientation={landscape|portrait}&wbToken={채널 스코프 JWT}`
- **wbToken**: `JwtProvider.createWhiteboardRecorderToken(channelName, ttl)`로 발급하는 STOMP 화이트보드 구독 인가용 토큰(`type=wb-recorder`, subject=채널명, **읽기 전용**). 녹화봇은 수업 참여자가 아니라 이 토큰 없이는 `/topic/lesson/{ch}/draw` 구독이 거부된다. TTL은 Agora RTC 토큰과 동일(수업+버퍼). → [화이트보드 동기화](./화이트보드-동기화.md)
- 해상도: portrait `720×1280`, landscape `1280×720` — start 시점 값이 mp4 해상도로 확정(중간 변경 불가)
- 파일: `avFileType = ["hls", "mp4"]`, 저장 `vendor=1`(S3), `region=10`(ap-northeast-2), prefix `lessons/recordings/{lessonId}`
- 인증: Basic Auth (`customerId:customerSecret` Base64)
- 녹화 토글: `agora.recording.enabled`(기본 false) — 로컬 등 S3 없는 환경에선 녹화·폴링을 전부 생략하고 무해하게 반환
- 공개 메서드: `startRecording()`, `stopRecording()`, `stopRecordingAsync()`(@Async), `resolveRecordingMp4Url()`

### RTC 토큰 서버 포팅 (5개 파일)

| 파일 | 역할 |
|---|---|
| `RtcTokenBuilder2.java` | 진입점. Role PUBLISHER/SUBSCRIBER + PRIVILEGE_JOIN/PUBLISH_AUDIO/VIDEO/DATA 부여 |
| `AccessToken2.java` | VERSION "007", `build()`에서 HMAC-SHA256 서명. `getSign()` 2단계 HMAC (issueTs→appCert, salt→result) |
| `ByteBuf.java` | Little-endian 바이너리 직렬화 |
| `Utils.java` | Deflate 압축 + Base64 + Unix timestamp |

- 발급 API: `POST /api/v1/lesson/token` → `LessonService.generateToken()` (채널명 `problem-{id}`에서 problem_id도 보정)

### recorder.html (녹화봇이 여는 페이지)

- 로드 SDK: SockJS 1.6.1, @stomp/stompjs 7.0.0, AgoraRTC N-4.20.2
- `?channel=`로 채널 수신 → SockJS `/ws` + STOMP `/topic/lesson/{channel}/draw` 구독으로 화이트보드 재현(`requestAnimationFrame`). CONNECT 시 `?wbToken=`을 `Authorization: Bearer` 헤더에 실어 구독 인가를 통과
- Agora `SUBSCRIBER uid=1234567`로 음성만 구독·재생 (강사 userId/학생 userId+10000과 안 겹치는 고정 uid)
- 음성 구독이 실패해도 화면 녹화는 계속

### S3 녹화 폴링 (mp4 우선)

- `stopRecording()` 직후 `stopRecordingAsync()`(@Async) → `findRecordingFromS3()`: **최대 60회 × 10초(≈10분)**
- stop 응답 fileList에 mp4가 있으면 즉시 `recording_url` 확정, m3u8만 있으면 계속 대기(HLS는 전사 불가라 절대 확정 안 함) / 403·401(자격증명 오류)은 즉시 중단
- 스케줄러 연계: `TranscriptScheduler.pollAndProcess()`(기본 5분, `transcript.polling-interval-ms`)가 `resolveRecordingMp4Url()`로 누락 URL 복구 후 전사·PDF로 연결 — 폴링이 재시작으로 유실돼도 여기서 복구됨

## 핵심 포인트

- 외부 SDK 기본 녹화의 한계를 **Web Page Recording**으로 우회해 화이트보드+음성을 한 화면으로 녹화, 복습 입력까지 재활용.
- Agora **공식 RTC 토큰 알고리즘을 서버에 직접 포팅**(HMAC-SHA256 2단계 서명)해 토큰 발급 문제 해결.
- 녹화봇의 브라우저 미디어 권한 요구(secure context)를 근거로 **nginx + Let's Encrypt HTTPS 인프라**를 구축한 인과적 설계.
- 화이트보드 JWT 인가 도입 후에도 녹화봇은 **채널 스코프 읽기 전용 토큰(wbToken)** 으로 최소 권한만 부여받아 동작.

## 관련 코드

<details>
<summary>클래스 · 파일 경로</summary>

- Agora: `backend/.../global/agora/AgoraRecordingService.java`, `RtcTokenBuilder2.java`, `AccessToken2.java`, `ByteBuf.java`, `Utils.java`
- 녹화봇 토큰: `backend/.../domain/auth/jwt/JwtProvider.java` — `createWhiteboardRecorderToken()` / 인가: `backend/.../global/config/StompAuthChannelInterceptor.java`
- 녹화봇 페이지: `backend/src/main/resources/static/recorder.html`
- Lesson: `backend/.../domain/lesson/controller/LessonController.java`(`/token`, `/{id}/recording/start`·`stop` 등 8개), `service/LessonService.java`, `entity/Lesson.java`(recordingUrl·resourceId·recordingSid)
- 복습 연계: `backend/.../domain/lessonreview/service/TranscriptScheduler.java` (기본 5분 폴링)
- 설정: `agora.*` (`application.yml`) — `agora.recording.enabled`, `AGORA_RECORDER_URL_BASE` 등

</details>
