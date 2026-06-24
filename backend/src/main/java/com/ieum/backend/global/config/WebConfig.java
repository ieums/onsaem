package com.ieum.backend.global.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.nio.file.Paths;

/**
 * 로컬(local 프로파일)에서 저장한 업로드 이미지를 정적으로 서빙한다.
 * LocalImageStorageService가 작업 디렉터리의 uploads/ 에 저장하고 "/uploads/{파일명}" URL을 반환하므로,
 * 그 경로를 실제 파일로 매핑해 준다. (prod는 S3 절대 URL을 쓰므로 이 핸들러를 타지 않는다.)
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String uploadsLocation = Paths.get("uploads").toAbsolutePath().toUri().toString();
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations(uploadsLocation);
    }
}
