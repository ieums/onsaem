import 'package:flutter/material.dart';

// ─── API 응답 모델 ─────────────────────────────────────────────────────────────

class TokenResponse {
  final int lessonId;
  final String token;
  final String channelName;
  final String appId;
  final int expireAt;

  TokenResponse({
    required this.lessonId,
    required this.token,
    required this.channelName,
    required this.appId,
    required this.expireAt,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) => TokenResponse(
        lessonId: (json['lessonId'] as num).toInt(),
        token: json['token'] as String,
        channelName: json['channelName'] as String,
        appId: json['appId'] as String,
        expireAt: (json['expireAt'] as num).toInt(),
      );
}

class RecordingStartResponse {
  final int lessonId;
  final String resourceId;
  final String sid;
  final String channelName;

  RecordingStartResponse({
    required this.lessonId,
    required this.resourceId,
    required this.sid,
    required this.channelName,
  });

  factory RecordingStartResponse.fromJson(Map<String, dynamic> json) =>
      RecordingStartResponse(
        lessonId: (json['lessonId'] as num).toInt(),
        resourceId: json['resourceId'] as String,
        sid: json['sid'] as String,
        channelName: json['channelName'] as String,
      );
}

class RecordingStopResponse {
  final int lessonId;
  final String? recordingUrl;
  final String uploadingStatus;

  RecordingStopResponse({
    required this.lessonId,
    this.recordingUrl,
    required this.uploadingStatus,
  });

  factory RecordingStopResponse.fromJson(Map<String, dynamic> json) =>
      RecordingStopResponse(
        lessonId: (json['lessonId'] as num).toInt(),
        recordingUrl: json['recordingUrl'] as String?,
        uploadingStatus: json['uploadingStatus'] as String,
      );
}

class ImageUploadResponse {
  final String imageUrl;

  ImageUploadResponse({required this.imageUrl});

  factory ImageUploadResponse.fromJson(Map<String, dynamic> json) =>
      ImageUploadResponse(imageUrl: json['imageUrl'] as String);
}

// ─── 화이트보드 모델 ───────────────────────────────────────────────────────────

enum DrawType {
  draw,
  erase,
  clear,
  imageAdd,
  undo,
  redo,
  cameraOn,
  cameraOff,
  zoom,
  imageMove,
  lessonEnd,
  micOn,
  micOff;

  String get value {
    switch (this) {
      case DrawType.draw:
        return 'DRAW';
      case DrawType.erase:
        return 'ERASE';
      case DrawType.clear:
        return 'CLEAR';
      case DrawType.imageAdd:
        return 'IMAGE_ADD';
      case DrawType.undo:
        return 'UNDO';
      case DrawType.redo:
        return 'REDO';
      case DrawType.cameraOn:
        return 'CAMERA_ON';
      case DrawType.cameraOff:
        return 'CAMERA_OFF';
      case DrawType.zoom:
        return 'ZOOM';
      case DrawType.imageMove:
        return 'IMAGE_MOVE';
      case DrawType.lessonEnd:
        return 'LESSON_END';
      case DrawType.micOn:
        return 'MIC_ON';
      case DrawType.micOff:
        return 'MIC_OFF';
    }
  }

  static DrawType fromString(String s) {
    switch (s.toUpperCase()) {
      case 'DRAW':
        return DrawType.draw;
      case 'ERASE':
        return DrawType.erase;
      case 'CLEAR':
        return DrawType.clear;
      case 'IMAGE_ADD':
        return DrawType.imageAdd;
      case 'UNDO':
        return DrawType.undo;
      case 'REDO':
        return DrawType.redo;
      case 'CAMERA_ON':
        return DrawType.cameraOn;
      case 'CAMERA_OFF':
        return DrawType.cameraOff;
      case 'ZOOM':
        return DrawType.zoom;
      case 'IMAGE_MOVE':
        return DrawType.imageMove;
      case 'LESSON_END':
        return DrawType.lessonEnd;
      case 'MIC_ON':
        return DrawType.micOn;
      case 'MIC_OFF':
        return DrawType.micOff;
      default:
        return DrawType.draw;
    }
  }
}

class DrawEvent {
  final String senderId;
  final DrawType type;
  final double? x;
  final double? y;
  final String? color;
  final double? strokeWidth;
  final String? imageUrl;
  final bool? isStart;    // 새 스트로크 시작 여부 (원격 스트로크 끊김 버그 수정용)
  final String? strokeId; // Undo 동기화용 스트로크 고유 ID
  final double? scale;    // 줌 동기화 — 배율
  final double? offsetX;  // 줌 동기화 — pan offset X
  final double? offsetY;  // 줌 동기화 — pan offset Y
  final double? width;    // 이미지 너비 (imageAdd / imageMove)
  final double? height;   // 이미지 높이

  DrawEvent({
    required this.senderId,
    required this.type,
    this.x,
    this.y,
    this.color,
    this.strokeWidth,
    this.imageUrl,
    this.isStart,
    this.strokeId,
    this.scale,
    this.offsetX,
    this.offsetY,
    this.width,
    this.height,
  });

  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'type': type.value,
        if (x != null) 'x': x,
        if (y != null) 'y': y,
        if (color != null) 'color': color,
        if (strokeWidth != null) 'strokeWidth': strokeWidth,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (isStart == true) 'isStart': true,
        if (strokeId != null) 'strokeId': strokeId,
        if (scale != null) 'scale': scale,
        if (offsetX != null) 'offsetX': offsetX,
        if (offsetY != null) 'offsetY': offsetY,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      };

  factory DrawEvent.fromJson(Map<String, dynamic> json) => DrawEvent(
        senderId: json['senderId'] as String? ?? '',
        type: DrawType.fromString(json['type'] as String? ?? 'DRAW'),
        x: (json['x'] as num?)?.toDouble(),
        y: (json['y'] as num?)?.toDouble(),
        color: json['color'] as String?,
        strokeWidth: (json['strokeWidth'] as num?)?.toDouble(),
        imageUrl: json['imageUrl'] as String?,
        isStart: json['isStart'] as bool?,
        strokeId: json['strokeId'] as String?,
        scale: (json['scale'] as num?)?.toDouble(),
        offsetX: (json['offsetX'] as num?)?.toDouble(),
        offsetY: (json['offsetY'] as num?)?.toDouble(),
        width: (json['width'] as num?)?.toDouble(),
        height: (json['height'] as num?)?.toDouble(),
      );
}

class DrawingStroke {
  final String id;       // Undo 동기화용 고유 ID
  final List<Offset> points;
  final Color color;
  final double width;
  final bool isEraser;   // WhiteboardPainter에서 BlendMode.clear 적용 여부

  const DrawingStroke({
    required this.id,
    required this.points,
    required this.color,
    required this.width,
    this.isEraser = false,
  });

  DrawingStroke copyWithPoints(List<Offset> points) => DrawingStroke(
        id: id,
        points: points,
        color: color,
        width: width,
        isEraser: isEraser,
      );
}

// ─── Undo/Redo 히스토리 아이템 ────────────────────────────────────────────────

sealed class CanvasAction {}

class StrokeAction extends CanvasAction {
  final DrawingStroke stroke;
  StrokeAction(this.stroke);
}

class ImageAction extends CanvasAction {
  final String? prevUrl; // undo 시 복원할 이전 URL
  ImageAction({required this.prevUrl});
}

// ─── 색상 유틸 ────────────────────────────────────────────────────────────────

Color colorFromHex(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

String colorToHex(Color color) =>
    '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
