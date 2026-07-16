package com.ieum.backend;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles({"local", "test"})   // H2 인메모리 컨텍스트로 스모크 테스트 (운영 MySQL/외부 자격증명 불필요)
class BackendApplicationTests {

    @Test
    void contextLoads() {
    }

}
