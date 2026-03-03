import 'package:flutter/material.dart';

class TabChangeNotification extends Notification {
  final int index;
  const TabChangeNotification(this.index);
}
