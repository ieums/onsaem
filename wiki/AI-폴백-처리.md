# AI 문제 인식 폴백 처리

## 문제 상황

학생이 올린 사진 한 장에 여러 문제가 섞여 있거나, 지문이 여러 페이지에 걸쳐 있는 경우가 많아 단순 OCR만으로는 정확한 문제 인식이 어려웠다. 또한 외부 AI(Gemini) API는 과부하(429)나 일시 장애(5xx)로 실패할 수 있는데, 이때 문제 등록 흐름 전체가 끊기면 사용자 경험이 크게 나빠진다.

## 해결 방법

- **OCR과 분류를 분리 호출**해 각 단계의 실패를 독립적으로 다룰 수 있게 했다.
- 오류(5xx·429) 발생 시 **백오프(backoff) 재시도** 후에도 실패하면 **폴백 모델로 전환**해, 기본 모델 과부하 시 부하를 분산하고 성공률을 높였다. (기본 모델과 폴백 모델을 서로 다르게 구성)
- 분류가 끝내 실패하더라도 **기본값으로 등록되는 graceful degradation** 을 적용해, AI가 실패해도 문제 등록 자체는 끊기지 않도록 했다.

## 핵심 포인트

- OCR·분류 단계 분리로 실패 지점을 격리하고 재시도/폴백 전략을 각각 적용.
- "기본 모델 → 백오프 재시도 → 폴백 모델" 단계적 폴백으로 외부 API 불안정성 흡수.
- AI 실패가 사용자 흐름을 막지 않도록 기본값 등록(graceful degradation)으로 설계.

## 관련 코드/도메인

- `backend/.../domain/problem/` — 문제 등록·OCR·분류 서비스
- `backend/.../domain/aitutor/service/` — `GeminiClient`, `GeminiProperties`(모델/폴백 설정)
- 설정: `application-prod.yml` — `gemini.api.ocr-model` / `ocr-fallback-model` / `model` / `classify-fallback-model`
