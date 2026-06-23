# Problem API ↔ 프론트 연동 정리

> 백엔드 problem 도메인(문제 등록/조회)을 Flutter 프론트에 연결.
> 기존 `matching` 기능과 동일한 패턴(dio + repository + riverpod) 사용.

---

## 1. 프론트 구조 (관련 부분)

```
lib/
  core/
    network/dio_client.dart        ← 전역 Dio (baseUrl, 타임아웃)
    constants/api_constants.dart   ← baseUrl 결정 (local/prod, web/ios/android)
    providers/current_user_provider.dart ← 로그인 세션(UserSession.id = studentId/tutorId)
  features/student/
    models/student_problem_model.dart       ← (신규) 응답 모델
    repositories/problem_repository.dart     ← (신규) problem API 클라이언트
    providers/problem_provider.dart          ← (신규) repository 프로바이더
    screens/student_problem_upload_screen.dart ← 업로드 화면(연결됨)
```

- **HTTP**: `dio` 전역 인스턴스(`dioClient`). baseUrl은 `api_constants.dart`가
  실행 환경별로 결정 (안드 에뮬 `10.0.2.2`, iOS/web `localhost`, prod 서버 IP).
- **응답 언래핑**: 백엔드 `ApiResponse{success,message,data}` → `res.data['data']`.
  단, problem은 일부 엔드포인트가 **raw**라 주의(아래).

---

## 2. 응답 래핑 — `ApiResponse`로 통일 완료 ✅

problem 컨트롤러의 모든 엔드포인트(POST/GET{id}/PATCH/DELETE 포함)를 `ApiResponse`로
통일했다. 이제 프론트는 **전부 `res.data['data']`** 로 일관 파싱.
(이전엔 POST·GET{id}·PATCH·DELETE가 raw라 섞여 있었음.)

---

## 3. 연결한 것

### 문제 등록 (핵심) — 여러 이미지 지원
`student_problem_upload_screen.dart`의 "매칭 요청하기" →
이미지 **1~N장** + studentId + 설명을 **multipart로 `POST /problems`** 호출.

```
images: 파일 파트 (image/jpeg) × N  ← 같은 'images' 키에 여러 파트
data:   application/json 파트 { studentId, studentDescription }
```
- 업로드 화면: 썸네일 가로 스크롤 + "추가" 타일 + 개별 삭제(×). 최대 5장.
- 갤러리는 다중 선택(`pickMultiImage`), 카메라는 1장씩 누적.
- 백엔드 `createProblem(List<MultipartFile>)`이 이미 다중 이미지를 받음.
- studentId는 `currentUserProvider`(로그인 세션)에서. 없으면 "로그인 필요" 안내.
- 성공 → 기존 매칭 흐름 진행 / 실패 → 스낵바 안내 후 중단.
- 과목/난이도는 **백엔드 AI가 판정**하므로 보내지 않음(화면의 과목 선택은 데모 매칭용).

### repository에 준비된 API (바로 쓸 수 있음)
- `createProblem(imageBytes, studentId, studentDescription?, selectedProblemIndex?)`
- `getStudentProblems(studentId)` → 내 문제 목록
- `cancelProblem(problemId)`

---

## 4. 연결한 것 (추가) — 여러 문제 감지(OCR) 선택

한 사진에 여러 문제가 감지되면(`needsSelection=true`) 백엔드가 `allDetected`(감지된
문제 후보들: summary/extractedText/subject/difficulty)를 준다. 업로드 화면이:
1. `POST /problems` → `needsSelection=true`면
2. **선택 바텀시트**(`_pickDetectedProblem`)로 후보 목록을 보여주고
3. 학생이 고른 `selectedProblemIndex`로 **재요청** → 단일 문제로 확정 등록.

모델: `ProblemCreateResult.allDetected` (`DetectedProblem`: summary/extractedText/
subject/difficulty + `preview` 미리보기 텍스트).

## 5. 남은 작업 (다음 단계)

- **내 문제 목록 화면 연결**: `student_questions_screen`에 `getStudentProblems` 연동.
- **문제 상세**: `GET /problems/{id}` 모델/연동(필요 시).
- **매칭 흐름 실연동**: 현재 학생측 매칭은 더미/타이머. `/matching/**`로 교체는 별도 작업.
- **인증 헤더**: 로그인 JWT가 붙으면 dio 인터셉터로 Authorization 자동 첨부 +
  studentId는 서버가 토큰에서 추출(파라미터 제거).
