import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

Widget renderGoogleButton() {
  return google_web.renderButton(
    configuration: google_web.GSIButtonConfiguration(
      type: google_web.GSIButtonType.icon,
      shape: google_web.GSIButtonShape.pill,
    ),
  );
}