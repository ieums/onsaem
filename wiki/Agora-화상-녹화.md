# Agora 화상·녹화 연동

## 문제 상황

실시간 화상 강의를 위해 Agora RTC를 붙였는데, 입장에 필요한 **RTC 토큰 생성이 초기에 동작하지 않아** 채널 접속이 막혔다. 또한 복습용 녹화는 단순 카메라 영상이 아니라 **강사·학생이 함께 쓰던 화이트보드 화면**을 그대로 담아야 했고, 녹화 시작 타이밍·업로드 지연·영상 포맷·화면 비율 등 실제 운영에서 불안정한 지점이 많았다.

## 해결 방법

- Agora **공식 RTC 토큰 생성 알고리즘을 서버(백엔드)에 직접 포팅**해 토큰 발급 문제를 해결했다.
- 수업 녹화는 화이트보드 화면을 그대로 캡처하는 **Web Page Recording 방식**으로 구현해, 별도 영상 합성 없이 그 결과물을 그대로 복습(전사·요약)의 입력으로 재활용했다.
- 반복 디버깅으로 다음을 안정화했다:
  - **녹화 시작 타이밍** — 비트레이트가 올라온 것을 확인한 뒤 녹화 시작
  - **S3 업로드 지연** — 폴링 시간을 연장해 늦게 올라오는 파일까지 확보
  - **영상 포맷** — mp4 우선, 실패 시 m3u8 폴백
  - **세로 화면 비율** — 강사 화면 방향에 맞춰 대응

## 핵심 포인트

- 외부 SDK가 막혔을 때 공식 토큰 알고리즘을 서버에 직접 포팅해 우회.
- Web Page Recording으로 화이트보드 화면을 그대로 녹화 → 복습 파이프라인 입력으로 재사용하는 연결 설계.
- 실서비스 관점의 녹화 안정화(시작 타이밍·업로드 지연·포맷 폴백·화면 비율) 디버깅 경험.

## 관련 코드/도메인

- `backend/.../global/agora/` — `AgoraRecordingService`(녹화 acquire/start/stop, mp4 URL resolve), RTC 토큰 생성
- `backend/.../domain/lesson/` — `LessonController`(`/recording/start`·`/recording/stop`), `Lesson`(resource_id/recording_sid/recording_url)
- 녹화봇 페이지: `backend/src/main/resources/static/recorder.html`
- 설정: `agora.*` (`application.yml`)
