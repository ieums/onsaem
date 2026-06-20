package com.ieum.backend.domain.matching.entity;

public enum ApplicationStatus {
    PENDING,      // 강사가 신청했고 학생이 아직 선택 안 한 상태
    CONFIRMING,   // 학생이 수락 클릭, 강사·학생 양측 확인 대기 중
    ACCEPTED,     // 양측 모두 확인 → 매칭 확정
    REJECTED,     // 다른 강사가 수락되어 자동으로 탈락된 상태
    UNAVAILABLE,  // 이 강사가 다른 수업에 들어가서 임시로 숨겨진 상태
                  // 수업 끝나면 다시 PENDING으로 복구됨
    EXPIRED       // 탐색 시간 만료로 소멸된 상태 (스케줄러 연동 후 사용)
}