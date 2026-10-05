import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

Scope {
  id: cc

  required property var cfg
  required property var notifs

  property bool shown: false
  property bool wifiOpen: false
  property bool btOpen: false
  property string wifiState: "disabled"
  property var nets: []
  property var knownNets: []
  property string btState: "off"
  property var btDevs: []
  property int brightness: -1
  property string selSsid: ""
  property string armed: ""
  property var audio: Pipewire.defaultAudioSink?.audio

  signal dismissed
  signal openSettings

  readonly property color base: cfg.bg
  readonly property color card: cfg.pill
  readonly property color acc: cfg.accent

  readonly property color onAcc:
    (acc.r * 0.299 + acc.g * 0.587 + acc.b * 0.114) > 0.55
      ? "#141218"
      : "#ffffff"

  readonly property color txt: "#e6e6e6"
  readonly property color dim: "#99e6e6e6"

  readonly property string ff: cfg.fontFamily
  readonly property string ifont: cfg.iconFont

  readonly property int r: Math.min(cfg.ccRadius + 6, 22)

  readonly property bool wifiOn: wifiState === "enabled"
  readonly property bool btOnState: btState === "on"

  readonly property int nCount:
    notifs.server.trackedNotifications.values.length

  readonly property var sessions: [
    {
      k: "lock",
      icon: "lock",
      label: "Lock",
      cmd: ["sh", "-c", "pidof hyprlock || hyprlock"],
      confirm: false
    },
    {
      k: "logout",
      icon: "logout",
      label: "Log out",
      cmd: ["hyprctl", "dispatch", "exit"],
      confirm: true
    },
    {
      k: "sleep",
      icon: "bedtime",
      label: "Sleep",
      cmd: ["systemctl", "suspend"],
      confirm: false
    },
    {
      k: "reboot",
      icon: "restart_alt",
      label: "Restart",
      cmd: ["systemctl", "reboot"],
      confirm: true
    },
    {
      k: "off",
      icon: "power_settings_new",
      label: "Shut down",
      cmd: ["systemctl", "poweroff"],
      confirm: true
    }
  ]

  function refresh() {
    wifiP.running = true
    btP.running = true
    brightP.running = true
    profileP.running = true
  }

  function run(args) {
    Quickshell.execDetached(args)
    afterTimer.restart()
  }

  onShownChanged: {
    if (shown)
      refresh()
  }

  function session(s) {
    if (s.confirm && armed !== s.k) {
      armed = s.k
      armTimer.restart()
      return
    }

    armed = ""
    Quickshell.execDetached(s.cmd)

    if (s.k === "lock")
      dismissed()
  }

  function wifiConnect(n) {
    selSsid = ""

    if (knownNets.includes(n.ssid)) {
      run(["nmcli", "connection", "up", "id", n.ssid])
    } else if (n.sec === "" || n.sec === "--") {
      run(["nmcli", "dev", "wifi", "connect", n.ssid])
    } else {
      selSsid = n.ssid
    }
  }

  function clearAll() {
    for (const n of Array.from(
      notifs.server.trackedNotifications.values
    )) {
      n.dismiss()
    }
  }

  Process {
    id: wifiP

    command: [
      "sh",
      "-c",
      "echo R:$(nmcli radio wifi); nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list 2>/dev/null | sed \"s/^/N:/\"; nmcli -t -f NAME connection show 2>/dev/null | sed \"s/^/K:/\""
    ]

    stdout: StdioCollector {
      onStreamFinished: {
        let st = "disabled"
        const nets = []
        const seen = {}
        const known = []

        for (const l of this.text.split("\n")) {
          if (l.startsWith("R:")) {
            st = l.slice(2).trim()
          } else if (l.startsWith("K:")) {
            known.push(l.slice(2))
          } else if (l.startsWith("N:")) {
            const p = l.slice(2).split(":")
            const ssid = p.slice(3).join(":").replace(/\\:/g, ":")

            if (!ssid || seen[ssid])
              continue

            seen[ssid] = true

            nets.push({
              ssid: ssid,
              signal: +p[1],
              sec: p[2],
              on: p[0] === "*"
            })
          }
        }

        nets.sort(
          (a, b) => (b.on - a.on) || (b.signal - a.signal)
        )

        cc.wifiState = st
        cc.nets = nets.slice(0, 8)
        cc.knownNets = known
      }
    }
  }

  Process {
    id: btP

    command: [
      "sh",
      "-c",
      "bluetoothctl show | grep -q 'Powered: yes' && echo R:on || echo R:off; bluetoothctl devices Paired | sed 's/^Device /P:/'; bluetoothctl devices Connected | sed 's/^Device /C:/'"
    ]

    stdout: StdioCollector {
      onStreamFinished: {
        let st = "off"
        const dev = {}
        const con = {}

        for (const l of this.text.split("\n")) {
          if (l.startsWith("R:")) {
            st = l.slice(2).trim()
          } else if (l.startsWith("P:")) {
            dev[l.slice(2, 19)] = l.slice(20)
          } else if (l.startsWith("C:")) {
            con[l.slice(2, 19)] = true
          }
        }

        const list = Object.keys(dev).map(m => ({
          mac: m,
          name: dev[m],
          on: !!con[m]
        }))

        list.sort(
          (a, b) => (b.on - a.on) || a.name.localeCompare(b.name)
        )

        cc.btState = st
        cc.btDevs = list
      }
    }
  }

  Process {
    id: profileP

    property string current: ""

    command: [
      "sh",
      "-c",
      "powerprofilesctl get 2>/dev/null"
    ]

    stdout: StdioCollector {
      onStreamFinished: {
        profileP.current = this.text.trim()
      }
    }
  }

  Process {
    id: brightP

    command: [
      "sh",
      "-c",
      "brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%'"
    ]

    stdout: StdioCollector {
      onStreamFinished: {
        const v = parseInt(this.text)
        cc.brightness = isNaN(v) ? -1 : v
      }
    }
  }

  Timer {
    id: pollTimer
    interval: 4000
    running: cc.shown
    repeat: true
    onTriggered: cc.refresh()
  }

  Timer {
    id: afterTimer
    interval: 1500
    onTriggered: cc.refresh()
  }

  Timer {
    id: armTimer
    interval: 3000
    onTriggered: cc.armed = ""
  }

  Timer {
    id: brightSet
    interval: 120
    onTriggered: Quickshell.execDetached([
      "brightnessctl",
      "set",
      Math.max(1, cc.brightness) + "%"
    ])
  }

  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink]
  }

  component Ico: Text {
    property string name

    text: name
    color: cc.txt
    font.family: cc.ifont
    font.pixelSize: 20
  }

  component Lbl: Text {
    color: cc.txt
    font.family: cc.ff
    font.pixelSize: 14
  }

  component Tile: Rectangle {
    id: t

    property string icon
    property string label
    property string sub
    property bool on: false
    property bool chevron: false
    property bool open: false

    signal toggled
    signal expand

    Layout.fillWidth: true
    Layout.preferredWidth: 1

    implicitHeight: 64
    radius: cc.r
    color: on ? cc.acc : cc.card

    MouseArea {
      anchors.fill: parent
      onClicked: t.chevron ? t.expand() : t.toggled()
    }

    RowLayout {
      anchors {
        fill: parent
        leftMargin: 10
        rightMargin: 8
      }

      spacing: 10

      Rectangle {
        implicitWidth: 40
        implicitHeight: 40
        radius: 20

        color: t.on
          ? "#33000000"
          : "#1affffff"

        Ico {
          anchors.centerIn: parent
          name: t.icon
          color: t.on ? cc.onAcc : cc.txt
        }

        MouseArea {
          anchors.fill: parent
          onClicked: t.toggled()
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Lbl {
          text: t.label
          font.bold: true
          color: t.on ? cc.onAcc : cc.txt
          Layout.fillWidth: true
          elide: Text.ElideRight
        }

        Lbl {
          text: t.sub
          font.pixelSize: 11
          color: t.on ? cc.onAcc : cc.dim
          Layout.fillWidth: true
          elide: Text.ElideRight
        }
      }

      Ico {
        visible: t.chevron
        name: t.open ? "expand_less" : "expand_more"
        color: t.on ? cc.onAcc : cc.dim
      }
    }
  }

  component ListRow: Rectangle {
    id: lr

    property string icon
    property string label

    // IMPORTANT:
    // "right" is a final/inherited property.
    // Use a different name.
    property string rightText

    property bool hot: false

    signal clicked

    Layout.fillWidth: true

    implicitHeight: 40
    radius: 12

    color: lrm.containsMouse
      ? "#22ffffff"
      : "transparent"

    RowLayout {
      anchors {
        fill: parent
        leftMargin: 8
        rightMargin: 8
      }

      spacing: 10

      Ico {
        name: lr.icon
        font.pixelSize: 18
        color: lr.hot ? cc.acc : cc.txt
      }

      Lbl {
        text: lr.label
        font.bold: lr.hot
        Layout.fillWidth: true
        elide: Text.ElideRight
      }

      Lbl {
        text: lr.rightText
        font.pixelSize: 11
        color: cc.dim
      }
    }

    MouseArea {
      id: lrm
      anchors.fill: parent
      hoverEnabled: true
      onClicked: lr.clicked()
    }
  }

  component Slide: Rectangle {
    id: sl

    property string icon
    property real value

    signal moved(real v)
    signal iconClicked

    Layout.fillWidth: true

    implicitHeight: 40
    radius: 20
    color: cc.card

    Rectangle {
      width: Math.max(
        40,
        sl.width * Math.min(
          1,
          Math.max(0, sl.value)
        )
      )

      height: parent.height
      radius: 20
      color: cc.acc
    }

    MouseArea {
      id: dr

      anchors {
        fill: parent
        leftMargin: 40
      }

      onPressed: m => sl.moved(
        Math.max(
          0,
          Math.min(
            1,
            (m.x + 40) / sl.width
          )
        )
      )

      onPositionChanged: m => {
        if (pressed) {
          sl.moved(
            Math.max(
              0,
              Math.min(
                1,
                (m.x + 40) / sl.width
              )
            )
          )
        }
      }
    }

    Ico {
      x: 10
      anchors.verticalCenter: parent.verticalCenter
      name: sl.icon
      color: cc.onAcc
    }

    MouseArea {
      width: 40
      height: parent.height
      onClicked: sl.iconClicked()
    }
  }

  component Field: Rectangle {
    id: fld

    property string placeholder

    signal accepted(string t)

    implicitHeight: 38
    radius: 10
    color: cc.base

    Layout.fillWidth: true

    TextInput {
      id: ti

      anchors {
        fill: parent
        margins: 8
      }

      verticalAlignment: TextInput.AlignVCenter
      echoMode: TextInput.Password

      color: cc.txt
      font.family: cc.ff
      font.pixelSize: 13

      clip: true

      onAccepted: fld.accepted(text)

      Lbl {
        visible: ti.text === ""

        text: fld.placeholder

        color: cc.dim
        font.pixelSize: 13

        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }

  HyprlandFocusGrab {
    windows: [win]
    active: cc.shown

    onCleared: cc.dismissed()
  }

  PanelWindow {
    id: win

    visible: cc.shown

    anchors {
      right: true
      bottom: !cc.cfg.barTop
      top: cc.cfg.barTop
    }

    margins {
      right: 12 + cc.cfg.barMargin
      bottom: cc.cfg.barHeight + cc.cfg.barMargin + 8
      top: cc.cfg.barHeight + cc.cfg.barMargin + 8
    }

    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.keyboardFocus:
      WlrKeyboardFocus.OnDemand

    implicitWidth: 392

    implicitHeight: Math.min(
      content.implicitHeight + 28,
      Quickshell.screens[0].height
        - cc.cfg.barHeight
        - 56
    )

    color: "transparent"

    Rectangle {
      anchors.fill: parent

      radius: 24

      color: Qt.alpha(
        cc.base,
        0.97
      )

      border.width: 1
      border.color: "#33ffffff"

      Flickable {
        id: fl

        anchors {
          fill: parent
          margins: 14
        }

        contentWidth: width
        contentHeight: content.implicitHeight

        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
          id: content

          width: fl.width
          spacing: 12

          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
              model: cc.sessions

              Rectangle {
                id: sb

                required property var modelData

                readonly property bool arm:
                  cc.armed === modelData.k

                Layout.fillWidth: true
                Layout.preferredWidth: 1

                implicitHeight: 64
                radius: cc.r

                color: arm
                  ? "#c0392b"
                  : (
                      sm.containsMouse
                        ? "#33ffffff"
                        : cc.card
                    )

                ColumnLayout {
                  anchors.centerIn: parent
                  spacing: 2

                  Ico {
                    Layout.alignment: Qt.AlignHCenter

                    name: sb.modelData.icon

                    color:
                      sb.arm
                        ? "#fff"
                        : cc.txt
                  }

                  Lbl {
                    Layout.alignment: Qt.AlignHCenter

                    text:
                      sb.arm
                        ? "Confirm?"
                        : sb.modelData.label

                    font.pixelSize: 10

                    color:
                      sb.arm
                        ? "#fff"
                        : cc.dim
                  }
                }

                MouseArea {
                  id: sm

                  anchors.fill: parent
                  hoverEnabled: true

                  onClicked:
                    cc.session(sb.modelData)
                }
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Tile {
              icon:
                cc.wifiOn
                  ? "wifi"
                  : "wifi_off"

              label: "Wi-Fi"

              sub:
                !cc.wifiOn
                  ? "Off"
                  : (
                      cc.nets.length > 0 &&
                      cc.nets[0].on
                        ? cc.nets[0].ssid
                        : "Not connected"
                    )

              on: cc.wifiOn
              chevron: true
              open: cc.wifiOpen

              onToggled:
                cc.run([
                  "nmcli",
                  "radio",
                  "wifi",
                  cc.wifiOn
                    ? "off"
                    : "on"
                ])

              onExpand: {
                cc.wifiOpen = !cc.wifiOpen
                cc.btOpen = false
              }
            }

            Tile {
              icon:
                cc.btOnState
                  ? "bluetooth"
                  : "bluetooth_disabled"

              label: "Bluetooth"

              sub:
                !cc.btOnState
                  ? "Off"
                  : (
                      cc.btDevs.filter(
                        d => d.on
                      ).length
                      + " connected"
                    )

              on: cc.btOnState
              chevron: true
              open: cc.btOpen

              onToggled:
                cc.run([
                  "bluetoothctl",
                  "power",
                  cc.btOnState
                    ? "off"
                    : "on"
                ])

              onExpand: {
                cc.btOpen = !cc.btOpen
                cc.wifiOpen = false
              }
            }
          }

          Rectangle {
            visible: cc.wifiOpen

            Layout.fillWidth: true

            implicitHeight:
              wl.implicitHeight + 20

            radius: cc.r
            color: cc.card

            ColumnLayout {
              id: wl

              anchors {
                fill: parent
                margins: 10
              }

              spacing: 2

              Lbl {
                visible: !cc.wifiOn
                text: "Wi-Fi is off"
                color: cc.dim
              }

              Repeater {
                model:
                  cc.wifiOn
                    ? cc.nets
                    : []

                ListRow {
                  required property var modelData

                  icon:
                    modelData.sec &&
                    modelData.sec !== "--"
                      ? "wifi_lock"
                      : "wifi"

                  label:
                    modelData.ssid

                  rightText:
                    modelData.on
                      ? "Connected"
                      : modelData.signal + "%"

                  hot: modelData.on

                  onClicked:
                    cc.wifiConnect(modelData)
                }
              }

              Field {
                visible:
                  cc.selSsid !== ""

                placeholder:
                  "Password for "
                  + cc.selSsid
                  + " (Enter)"

                onAccepted: t => {
                  cc.run([
                    "nmcli",
                    "dev",
                    "wifi",
                    "connect",
                    cc.selSsid,
                    "password",
                    t
                  ])

                  cc.selSsid = ""
                }
              }

              ListRow {
                icon: "refresh"
                label: "Rescan"

                onClicked: {
                  cc.run([
                    "nmcli",
                    "dev",
                    "wifi",
                    "rescan"
                  ])
                }
              }
            }
          }

          Rectangle {
            visible: cc.btOpen

            Layout.fillWidth: true

            implicitHeight:
              bl.implicitHeight + 20

            radius: cc.r
            color: cc.card

            ColumnLayout {
              id: bl

              anchors {
                fill: parent
                margins: 10
              }

              spacing: 2

              Lbl {
                visible: !cc.btOnState
                text: "Bluetooth is off"
                color: cc.dim
              }

              Lbl {
                visible:
                  cc.btOnState &&
                  cc.btDevs.length === 0

                text: "No paired devices"
                color: cc.dim
              }

              Repeater {
                model:
                  cc.btOnState
                    ? cc.btDevs
                    : []

                ListRow {
                  required property var modelData

                  icon:
                    modelData.on
                      ? "bluetooth_connected"
                      : "bluetooth"

                  label:
                    modelData.name

                  rightText:
                    modelData.on
                      ? "Connected"
                      : "Tap to connect"

                  hot: modelData.on

                  onClicked:
                    cc.run([
                      "bluetoothctl",
                      modelData.on
                        ? "disconnect"
                        : "connect",
                      modelData.mac
                    ])
                }
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Tile {
              icon:
                cc.cfg.dnd
                  ? "notifications_off"
                  : "notifications"

              label: "Do Not Disturb"

              sub:
                cc.cfg.dnd
                  ? "On"
                  : "Off"

              on: cc.cfg.dnd

              onToggled:
                cc.cfg.dnd = !cc.cfg.dnd
            }

            Tile {
              icon: "settings"
              label: "Settings"
              sub: "Open settings"

              onToggled:
                cc.openSettings()
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Slide {
              Layout.fillWidth: true

              icon:
                !cc.audio ||
                cc.audio.muted ||
                cc.audio.volume === 0
                  ? "volume_off"
                  : (
                      cc.audio.volume < 0.4
                        ? "volume_down"
                        : "volume_up"
                    )

              value:
                cc.audio
                  ? Math.min(
                      1,
                      cc.audio.volume
                    )
                  : 0

              onMoved: v => {
                if (cc.audio)
                  cc.audio.volume = v
              }

              onIconClicked: {
                if (cc.audio)
                  cc.audio.muted =
                    !cc.audio.muted
              }
            }

            Rectangle {
              id: muteButton

              Layout.preferredWidth: 40
              Layout.preferredHeight: 40

              radius: 20

              color:
                cc.audio && cc.audio.muted
                  ? cc.acc
                  : cc.card

              Ico {
                anchors.centerIn: parent

                name:
                  cc.audio && cc.audio.muted
                    ? "volume_off"
                    : "volume_up"

                color:
                  cc.audio && cc.audio.muted
                    ? cc.onAcc
                    : cc.txt

                font.pixelSize: 19
              }

              MouseArea {
                anchors.fill: parent

                onClicked: {
                  if (cc.audio)
                    cc.audio.muted =
                      !cc.audio.muted
                }
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Slide {
              Layout.fillWidth: true

              visible:
                cc.brightness >= 0

              icon: "brightness_6"

              value:
                cc.brightness / 100

              onMoved: v => {
                cc.brightness =
                  Math.round(v * 100)

                brightSet.restart()
              }
            }

            Repeater {
              model: [
                { name: "power-saver", icon: "eco" },
                { name: "balanced", icon: "balance" },
                { name: "performance", icon: "bolt" }
              ]

              Rectangle {
                id: profileButton

                required property var modelData

                Layout.preferredWidth: 40
                Layout.preferredHeight: 40

                radius: 20

                color:
                  profileP.current === modelData.name
                    ? cc.acc
                    : cc.card

                Ico {
                  anchors.centerIn: parent

                  name: profileButton.modelData.icon

                  color:
                    profileP.current === profileButton.modelData.name
                      ? cc.onAcc
                      : cc.txt

                  font.pixelSize: 19
                }

                MouseArea {
                  anchors.fill: parent

                  onClicked: {
                    profileP.current = profileButton.modelData.name

                    Quickshell.execDetached([
                      "powerprofilesctl",
                      "set",
                      profileButton.modelData.name
                    ])
                  }
                }
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true

            Lbl {
              text:
                "Notifications"
                + (
                    cc.nCount > 0
                      ? " (" + cc.nCount + ")"
                      : ""
                  )

              font.bold: true
              Layout.fillWidth: true
            }

            Lbl {
              visible:
                cc.nCount > 0

              text: "Clear all"
              color: cc.acc

              MouseArea {
                anchors.fill: parent

                onClicked:
                  cc.clearAll()
              }
            }
          }

          Lbl {
            visible:
              cc.nCount === 0

            text: "No notifications"
            color: cc.dim
            font.pixelSize: 13
          }

          ListView {
            visible:
              cc.nCount > 0

            Layout.fillWidth: true

            Layout.preferredHeight:
              Math.min(
                contentHeight,
                280
              )

            clip: true
            spacing: 8

            verticalLayoutDirection:
              ListView.BottomToTop

            model:
              cc.notifs.server.trackedNotifications

            boundsBehavior:
              Flickable.StopAtBounds

            delegate: Rectangle {
              id: nd

              required property var modelData

              width:
                ListView.view.width

              height:
                nc.implicitHeight + 20

              radius: cc.r
              color: cc.card

              RowLayout {
                id: nc

                anchors {
                  fill: parent
                  margins: 10
                }

                spacing: 8

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 2

                  Lbl {
                    text:
                      nd.modelData.appName

                    font.pixelSize: 11
                    color: cc.acc

                    Layout.fillWidth: true
                    elide:
                      Text.ElideRight
                  }

                  Lbl {
                    text:
                      nd.modelData.summary

                    font.bold: true

                    Layout.fillWidth: true

                    wrapMode:
                      Text.Wrap

                    maximumLineCount: 2

                    elide:
                      Text.ElideRight
                  }

                  Lbl {
                    visible:
                      text !== ""

                    text:
                      nd.modelData.body

                    font.pixelSize: 12
                    color: cc.dim

                    Layout.fillWidth: true

                    wrapMode:
                      Text.Wrap

                    maximumLineCount: 3

                    elide:
                      Text.ElideRight
                  }
                }

                Rectangle {
                  implicitWidth: 28
                  implicitHeight: 28
                  radius: 14

                  Layout.alignment:
                    Qt.AlignTop

                  color:
                    xm.containsMouse
                      ? "#33ffffff"
                      : "transparent"

                  Ico {
                    anchors.centerIn:
                      parent

                    name: "close"
                    font.pixelSize: 16
                  }

                  MouseArea {
                    id: xm

                    anchors.fill:
                      parent

                    hoverEnabled: true

                    onClicked:
                      nd.modelData.dismiss()
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

