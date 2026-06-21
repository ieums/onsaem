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