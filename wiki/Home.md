# 온샘 (ONSAEM) Wiki

온샘 프로젝트의 도메인별 설계·구현 문서입니다. 각 페이지는 담당자가 채워 넣습니다.

## 도메인 문서

| 도메인 | 문서 | 담당 |
|---|---|---|
| 인증 / 계정 | [인증-계정](https://github.com/ieums/onsaem/wiki/인증-계정) | <!-- TODO --> |
| 문제 등록 / OCR | [문제-등록-OCR](https://github.com/ieums/onsaem/wiki/문제-등록-OCR) | <!-- TODO --> |
| 강사 매칭 | [매칭-시스템](https://github.com/ieums/onsaem/wiki/매칭-시스템) | <!-- TODO --> |
| 실시간 화상 강의 | [화상강의](https://github.com/ieums/onsaem/wiki/화상강의) | <!-- TODO --> |
| 코인 결제 / 구독 | [결제-코인](https://github.com/ieums/onsaem/wiki/결제-코인) | <!-- TODO --> |
| 정산 | [정산](https://github.com/ieums/onsaem/wiki/정산) | <!-- TODO --> |
| AI 튜터 / 복습 | [AI-튜터-복습](https://github.com/ieums/onsaem/wiki/AI-튜터-복습) | <!-- TODO --> |
| 리뷰 / 신고 | [리뷰-신고](https://github.com/ieums/onsaem/wiki/리뷰-신고) | <!-- TODO --> |

## 기술적 도전 / 트러블슈팅

주요 기술 난제와 해결 과정을 정리한 문서입니다. (README의 "기술적 도전" 섹션과 연결)

| 주제 | 문서 |
|---|---|
| 실시간 화이트보드 동기화 | [화이트보드-동기화](https://github.com/ieums/onsaem/wiki/화이트보드-동기화) |
| 결제·정산 데이터 무결성 | [결제-정산-무결성](https://github.com/ieums/onsaem/wiki/결제-정산-무결성) |
| AI 문제 인식 폴백 | [AI-폴백-처리](https://github.com/ieums/onsaem/wiki/AI-폴백-처리) |
| 복습 자동화 파이프라인 | [복습-자동화](https://github.com/ieums/onsaem/wiki/복습-자동화) |
| Agora 화상·녹화 연동 | [Agora-화상-녹화](https://github.com/ieums/onsaem/wiki/Agora-화상-녹화) |
| 매칭 상태 머신·스케줄러 | [매칭-상태머신](https://github.com/ieums/onsaem/wiki/매칭-상태머신) |

## 참고 링크

- 저장소: https://github.com/ieums/onsaem
- README: [프로젝트 개요·기술스택·시작하기](https://github.com/ieums/onsaem/blob/main/README.md)
- ERD: <!-- TODO: ERDCloud 링크 -->

## 문서 작성 규칙

- 각 도메인 페이지는 공통 뼈대(개요 / 주요 기능 / 핵심 로직·플로우 / 관련 API / 관련 테이블 / 트러블슈팅)를 따릅니다.
- 다이어그램은 GitHub에서 렌더링되는 ```mermaid``` 코드블록을 사용합니다.
- 코드 참조는 `파일경로:라인` 형식으로 남기면 추적이 쉽습니다.
