import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

ColumnLayout {
  id: ex
  required property var ctl
  spacing: 12

  property string power: ""
  property var apps: []
  property string lastApps: ""
  property bool idleOn: false
  property bool calOpen: false
  property date month: new Date()
  property var mic: Pipewire.defaultAudioSource?.audio
  readonly property bool airplane: !ctl.wifiOn && !ctl.btOnState

  PwObjectTracker { objects: [Pipewire.defaultAudioSource] }

  Process {
    id: pwrP
    command: ["sh", "-c", "powerprofilesctl get 2>/dev/null"]
    stdout: StdioCollector { onStreamFinished: ex.power = this.text.trim() }
  }
  Process {
    id: appsP
    command: ["sh", "-c", "pactl -f json list sink-inputs 2>/dev/null"]
    stdout: StdioCollector {
      onStreamFinished: {
        let list = []
        try {
          list = JSON.parse(this.text).map(a => {
            const v = Object.values(a.volume || {})
            const pr = a.properties || {}
            return { id: a.index, name: pr["application.name"] || pr["media.name"] || "App", vol: v.length ? parseInt(v[0].value_percent) : 0 }
          })
        } catch (e) {}
        const s = JSON.stringify(list)
        if (s !== ex.lastApps) { ex.lastApps = s; ex.apps = list }
      }
    }
  }
  Process {
    id: idleP
    running: ex.idleOn
    command: ["systemd-inhibit", "--what=idle", "--who=Quickshell", "--why=Idle inhibitor", "sleep", "infinity"]
  }
  Timer { interval: 4000; running: ex.ctl.shown; repeat: true; triggeredOnStart: true; onTriggered: { pwrP.running = true; appsP.running = true } }

  component Ico: Text { property string name; text: name; color: ex.ctl.txt; font.family: ex.ctl.ifont; font.pixelSize: 20 }
  component Lbl: Text { color: ex.ctl.txt; font.family: ex.ctl.ff; font.pixelSize: 14 }

  component Tile: Rectangle {
    id: t
    property string icon
    property string label
    property string sub
    property bool on: false
    signal clicked
    Layout.fillWidth: true; Layout.preferredWidth: 1
    implicitHeight: 64; radius: ex.ctl.r
    color: on ? ex.ctl.acc : ex.ctl.card
    RowLayout {
      anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
      spacing: 10
      Rectangle {
        implicitWidth: 40; implicitHeight: 40; radius: 20
        color: t.on ? "#33000000" : "#1affffff"
        Ico { anchors.centerIn: parent; name: t.icon; color: t.on ? ex.ctl.onAcc : ex.ctl.txt }
      }
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        Lbl { text: t.label; font.bold: true; color: t.on ? ex.ctl.onAcc : ex.ctl.txt; Layout.fillWidth: true; elide: Text.ElideRight }
        Lbl { text: t.sub; font.pixelSize: 11; color: t.on ? ex.ctl.onAcc : ex.ctl.dim; Layout.fillWidth: true; elide: Text.ElideRight }
      }
    }
    MouseArea { anchors.fill: parent; onClicked: t.clicked() }
  }

  component Slide: Rectangle {
    id: sl
    property string icon
    property string label
    property real value
    signal moved(real v)
    signal iconClicked
    Layout.fillWidth: true
    implicitHeight: 40; radius: 20; color: ex.ctl.card
    Rectangle { width: Math.max(40, sl.width * Math.min(1, Math.max(0, sl.value))); height: parent.height; radius: 20; color: ex.ctl.acc }
    MouseArea {
      anchors { fill: parent; leftMargin: 40 }
      onPressed: m => sl.moved(Math.max(0, Math.min(1, (m.x + 40) / sl.width)))
      onPositionChanged: m => { if (pressed) sl.moved(Math.max(0, Math.min(1, (m.x + 40) / sl.width))) }
    }
    Ico { x: 10; anchors.verticalCenter: parent.verticalCenter; name: sl.icon; color: ex.ctl.onAcc }
    Lbl { anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter } width: sl.width - 90; horizontalAlignment: Text.AlignRight; text: sl.label; font.pixelSize: 12; elide: Text.ElideRight }
    MouseArea { width: 40; height: parent.height; onClicked: sl.iconClicked() }
  }

  component RBtn: Rectangle {
    id: rb
    property string icon
    signal clicked
    implicitWidth: 30; implicitHeight: 30; radius: 15
    color: rm.containsMouse ? "#33ffffff" : "#1affffff"
    Ico { anchors.centerIn: parent; name: rb.icon; font.pixelSize: 18 }
    MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; onClicked: rb.clicked() }
  }

  // airplane + idle inhibitor
  RowLayout {
    Layout.fillWidth: true
    spacing: 10
    Tile {
      icon: "flight"
      label: "Airplane mode"
      sub: ex.airplane ? "On" : "Off"
      on: ex.airplane
      onClicked: ex.ctl.run(["sh", "-c", ex.airplane ? "nmcli radio wifi on; bluetoothctl power on" : "nmcli radio all off; bluetoothctl power off"])
    }
    Tile {
      icon: "coffee"
      label: "Stay awake"
      sub: ex.idleOn ? "Idle blocked" : "Off"
      on: ex.idleOn
      onClicked: ex.idleOn = !ex.idleOn
    }
  }

  // power profile
  Rectangle {
    visible: ex.power !== ""
    Layout.fillWidth: true
    implicitHeight: 52; radius: ex.ctl.r; color: ex.ctl.card
    RowLayout {
      anchors { fill: parent; margins: 6 }
      spacing: 6
      Repeater {
        model: [
          { k: "power-saver", icon: "energy_savings_leaf", label: "Saver" },
          { k: "balanced", icon: "balance", label: "Balanced" },
          { k: "performance", icon: "bolt", label: "Performance" }
        ]
        Rectangle {
          id: pb
          required property var modelData
          readonly property bool cur: ex.power === modelData.k
          Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1
          radius: ex.ctl.r - 4
          color: cur ? ex.ctl.acc : "transparent"
          RowLayout {
            anchors.centerIn: parent
            spacing: 6
            Ico { name: pb.modelData.icon; font.pixelSize: 18; color: pb.cur ? ex.ctl.onAcc : ex.ctl.txt }
            Lbl { text: pb.modelData.label; font.pixelSize: 12; color: pb.cur ? ex.ctl.onAcc : ex.ctl.txt }
          }
          MouseArea { anchors.fill: parent; onClicked: { ex.power = pb.modelData.k; Quickshell.execDetached(["powerprofilesctl", "set", pb.modelData.k]) } }
        }
      }
    }
  }

  // mic
  Slide {
    visible: ex.mic !== null && ex.mic !== undefined
    icon: ex.mic && ex.mic.muted ? "mic_off" : "mic"
    label: "Microphone"
    value: ex.mic ? Math.min(1, ex.mic.volume) : 0
    onMoved: v => { if (ex.mic) ex.mic.volume = v }
    onIconClicked: { if (ex.mic) ex.mic.muted = !ex.mic.muted }
  }

  // per-app volume
  Repeater {
    model: ex.apps
    Slide {
      id: sa
      required property var modelData
      property real local: modelData.vol / 100
      icon: "graphic_eq"
      label: modelData.name
      value: local
      onMoved: v => { local = v; dt.restart() }
      onIconClicked: Quickshell.execDetached(["pactl", "set-sink-input-mute", String(sa.modelData.id), "toggle"])
      Timer { id: dt; interval: 120; onTriggered: Quickshell.execDetached(["pactl", "set-sink-input-volume", String(sa.modelData.id), Math.round(sa.local * 100) + "%"]) }
    }
  }

  // calendar
  Tile {
    icon: "calendar_month"
    label: Qt.formatDate(new Date(), "dddd, MMM d")
    sub: ex.calOpen ? "Tap to collapse" : "Tap to expand"
    on: ex.calOpen
    onClicked: ex.calOpen = !ex.calOpen
  }
  Rectangle {
    visible: ex.calOpen
    Layout.fillWidth: true
    implicitHeight: cal.implicitHeight + 24
    radius: ex.ctl.r; color: ex.ctl.card
    ColumnLayout {
      id: cal
      anchors { fill: parent; margins: 12 }
      spacing: 8
      RowLayout {
        Layout.fillWidth: true
        RBtn { icon: "chevron_left"; onClicked: ex.month = new Date(ex.month.getFullYear(), ex.month.getMonth() - 1, 1) }
        Lbl { text: Qt.formatDate(ex.month, "MMMM yyyy"); font.bold: true; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
        RBtn { icon: "chevron_right"; onClicked: ex.month = new Date(ex.month.getFullYear(), ex.month.getMonth() + 1, 1) }
      }
      GridLayout {
        Layout.fillWidth: true
        columns: 7; columnSpacing: 2; rowSpacing: 2
        Repeater {
          model: ["S", "M", "T", "W", "T", "F", "S"]
          Lbl { required property string modelData; text: modelData; font.pixelSize: 11; color: ex.ctl.dim; Layout.fillWidth: true; Layout.preferredWidth: 1; horizontalAlignment: Text.AlignHCenter }
        }
        Repeater {
          model: 42
          Rectangle {
            id: dc
            required property int index
            readonly property int first: new Date(ex.month.getFullYear(), ex.month.getMonth(), 1).getDay()
            readonly property int last: new Date(ex.month.getFullYear(), ex.month.getMonth() + 1, 0).getDate()
            readonly property int day: index - first + 1
            readonly property bool valid: day >= 1 && day <= last
            readonly property bool today: valid && day === new Date().getDate() && ex.month.getMonth() === new Date().getMonth() && ex.month.getFullYear() === new Date().getFullYear()
            Layout.fillWidth: true; Layout.preferredWidth: 1
            implicitHeight: 28; radius: 14
            color: today ? ex.ctl.acc : "transparent"
            Lbl { anchors.centerIn: parent; visible: dc.valid; text: dc.day; font.pixelSize: 12; color: dc.today ? ex.ctl.onAcc : ex.ctl.txt }
          }
        }
      }
    }
  }
}
