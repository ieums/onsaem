-- =====================================================================
-- 기초 계정 시드 (ddl-auto=create + sql.init.mode=always 로 1회 기동 시 주입)
-- 로그인: 이메일 / 비밀번호 = test1234  (BCrypt 해시)
--   학생1 : student1@test.com
--   강사1 : tutor1@test.com  (5과목 전부 보유 → 어떤 과목 질문이든 매칭)
-- 과목은 enum 키(KOREAN/MATH/...)로 저장 — Problem.subject·매칭 쿼리와 동일한 형태.
-- =====================================================================
INSERT INTO student
(id, name, email, password, provider, provider_user_id, status, created_at, updated_at)
VALUES
(1, '학생1', 'student1@test.com', '$2a$10$Nd1ugBbhyYndGXI9DNwyh.5oqFdmruCtXfAGOkYZZVipAmJcdXTsq',
 'LOCAL', NULL, 'ACTIVE', NOW(), NOW());

INSERT INTO tutor
(id, name, email, password, provider, provider_user_id, status,
 grade, verification_status, review_count, lesson_count, is_available,
 school, major, bio, education_status, experience_years, rating_avg,
 created_at, updated_at)
VALUES
(1, '강사1', 'tutor1@test.com', '$2a$10$Nd1ugBbhyYndGXI9DNwyh.5oqFdmruCtXfAGOkYZZVipAmJcdXTsq',
 'LOCAL', NULL, 'ACTIVE',
 'ROOKIE', 'VERIFIED', 0, 0, 1,
 '온샘대학교', '국어교육과', '안녕하세요, 온샘 강사1입니다.', 'GRADUATED', 3, NULL,
 NOW(), NOW());

INSERT INTO tutor_subject (tutor_id, subject) VALUES
(1, 'KOREAN'), (1, 'MATH'), (1, 'ENGLISH'), (1, 'SOCIAL'), (1, 'SCIENCE');

-- =====================================================================
-- 기존 시드 (코인 패키지 / 구독 플랜 / 정산 샘플)
-- =====================================================================
INSERT INTO coin_packages (name, price, coin_amount, bonus_amount, active, created_at) VALUES ('50코인', 5000, 50, 0, true, NOW());
INSERT INTO coin_packages (name, price, coin_amount, bonus_amount, active, created_at) VALUES ('100코인', 10000, 100, 0, true, NOW());
INSERT INTO coin_packages (name, price, coin_amount, bonus_amount, active, created_at) VALUES ('250코인', 22500, 250, 25, true, NOW());
INSERT INTO coin_packages (name, price, coin_amount, bonus_amount, active, created_at) VALUES ('500코인', 40000, 500, 100, true, NOW());

INSERT INTO subscription_plans (name, price, duration_days, discount_percent, active, created_at) VALUES ('AI 튜터 월간', 9900, 30, 0, true, NOW());
INSERT INTO subscription_plans (name, price, duration_days, discount_percent, active, created_at) VALUES ('AI 튜터 연간', 83160, 365, 30, true, NOW());

INSERT INTO settlements
(tutor_id, lesson_id, total_coin, platform_fee_coin, tutor_coin, tutor_amount, status, created_at)
VALUES
    (1, 1, 40, 8, 32, 3200, 'CALCULATED', NOW()),
    (1, 2, 52, 10, 42, 4200, 'PENDING', NOW() - INTERVAL 1 DAY),
    (1, 3, 60, 12, 48, 4800, 'TRANSFERRED', NOW() - INTERVAL 2 DAY);
