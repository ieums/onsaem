package com.ieum.backend.domain.lesson.controller;

import com.ieum.backend.domain.lesson.dto.DrawEventDto;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.stereotype.Controller;

@Controller
@RequiredArgsConstructor
public class LessonWebSocketController {

    /**
     * 화이트보드 드로우 이벤트 브로드캐스트
     *
     * 전송: /app/lesson/{channelName}/draw
     * 구독: /topic/lesson/{channelName}/draw
     */
    @MessageMapping("/lesson/{channelName}/draw")
    @SendTo("/topic/lesson/{channelName}/draw")
    public DrawEventDto handleDraw(
            @DestinationVariable String channelName,
            DrawEventDto event) {
        return event;
    }
}
