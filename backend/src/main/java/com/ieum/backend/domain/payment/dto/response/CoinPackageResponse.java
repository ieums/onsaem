package com.ieum.backend.domain.payment.dto.response;

import com.ieum.backend.domain.payment.entity.CoinPackage;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@AllArgsConstructor
public class CoinPackageResponse {

    private Long id;
    private String name;
    private Integer price;
    private Integer coinAmount;
    private Integer bonusAmount;
    private Integer totalCoin;

    public static CoinPackageResponse from(CoinPackage pkg) {
        return CoinPackageResponse.builder()
                .id(pkg.getId())
                .name(pkg.getName())
                .price(pkg.getPrice())
                .coinAmount(pkg.getCoinAmount())
                .bonusAmount(pkg.getBonusAmount())
                .totalCoin(pkg.getTotalCoin())
                .build();
    }
}