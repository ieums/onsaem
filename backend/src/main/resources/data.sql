INSERT INTO coin_packages (name, price, coin_amount, bonus_amount, active, created_at) VALUES ('50코인', 5000, 50, 0, true, NOW());
INSERT INTO coin_packages (name, price, coin_amount, bonus_amount, active, created_at) VALUES ('100코인', 10000, 100, 0, true, NOW());
INSERT INTO coin_packages (name, price, coin_amount, bonus_amount, active, created_at) VALUES ('250코인', 22500, 250, 25, true, NOW());
INSERT INTO coin_packages (name, price, coin_amount, bonus_amount, active, created_at) VALUES ('500코인', 40000, 500, 100, true, NOW());

INSERT INTO subscription_plans (name, price, duration_days, discount_percent, active, created_at) VALUES ('AI 튜터 월간', 9900, 30, 0, true, NOW());
INSERT INTO subscription_plans (name, price, duration_days, discount_percent, active, created_at) VALUES ('AI 튜터 연간', 83160, 365, 30, true, NOW());