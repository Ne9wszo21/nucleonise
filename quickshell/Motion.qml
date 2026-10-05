import QtQuick

QtObject {
  readonly property int fast: 120
  readonly property int normal: 180
  readonly property int smooth: 240
  readonly property int slow: 300

  readonly property int easing: Easing.OutCubic
  readonly property int easingIn: Easing.InCubic
  readonly property int easingInOut: Easing.InOutCubic
}
