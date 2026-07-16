package com.ieum.backend.domain.auth.dto;

/** 정산 계좌 등록·수정 요청 */
public record SettlementAccountRequest(String bank, String account, String holder) {}
