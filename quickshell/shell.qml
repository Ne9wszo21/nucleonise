import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

Scope {
  id: root
  PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
  SystemClock { id: clock; precision: s.clockSec ? SystemClock.Seconds : SystemClock.Minutes }
 
  property bool settingsOpen: false
  IpcHandler {
  target: "settings"

  function toggle() {
    root.settingsOpen = !root.settingsOpen
  }
}

  property string weather: "--"
  property string weatherCond: ""
  property string weatherLoc: ""
  function weatherText() {
    const out = []
    if (s.wxTemp) out.push(weather)
    if (s.wxCond && weatherCond !== "") out.push(weatherCond)
    if (s.wxLoc && weatherLoc !== "") out.push(weatherLoc)
    return out.join(" \u00b7 ")
  }
  property string ssid: ""
  property bool btOn: false
  property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
  property var audio: Pipewire.defaultAudioSink?.audio

  function zone(str) { return String(str).split(",").filter(x => x !== "") }
  function volIcon() {
    if (!audio || audio.muted || audio.volume === 0) return "volume_off"
    return audio.volume < 0.4 ? "volume_down" : "volume_up"
  }
  function batIcon() {
    const d = UPower.displayDevice
    if (d.state === UPowerDeviceState.Charging) return "battery_charging_full"
    const p = d.percentage
    return p > 0.9 ? "battery_full" : p > 0.7 ? "battery_6_bar" : p > 0.5 ? "battery_4_bar" : p > 0.3 ? "battery_3_bar" : p > 0.15 ? "battery_2_bar" : "battery_alert"
  }
  function comp(k) {
    switch (k) {
      case "launcher": return cLauncher
      case "workspaces": return cWorkspaces
      case "media": return cMedia
      case "apps": return cApps
      case "tray": return cTray
      case "vitals": return cVitals
      case "weather": return cWeather
      case "status": return cStatus
      case "cc": return cCc
      case "settings": return cSettings
      case "wallpaper": return cWallpaper
      case "clock": return cClock
      default: return null
    }
  }

  FileView {
    id: store
    path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()
    onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter() }
    adapter: JsonAdapter {
      id: s
      property string fontFamily: "Google Sans"
      property string iconFont: "Material Symbols Rounded"
      property string accent: "#b9a6f5"
      property string bg: "#141020"
      property string pill: "#2b2640"
      property real alpha: 0.85
      property int barHeight: 46
      property int pillRadius: 16
      property int launcherRadius: 16
      property int workspaceRadius: 16
      property int wallpaperRadius: 16
      property int clockRadius: 16
      property int settingsRadius: 16
      property int ccRadius: 16
      property int statusRadius: 16
      property int weatherRadius: 16
      property int vitalsRadius: 16
      property int trayRadius: 16
      property int appsRadius: 16
      property int mediaRadius: 16
      property int notifsRadius: 16
      property bool barTop: false
      property bool showWeather: true
      property bool showMedia: true
      property bool showTray: true
      property bool clock24: false
      property int fontSize: 13
      property int barMargin: 0
      property string wallpaper: ""
      property string wallDir: "~/Pictures"
      property bool devMode: false
      property bool devOutline: false
      property bool dnd: false
      property bool showVitals: true
      property string eqBands: "0,0,0,0,0,0,0,0,0,0"
      property string eqPreset: "Flat"
      property bool eqOn: true
      property int dockIcon: 22
      property bool showDock: true
      property bool showWifi: true
      property bool showBt: true
      property bool showVolume: true
      property bool showBattery: true
      property bool showDate: true
      property bool ccPower: true
      property bool ccMic: true
      property bool ccApps: true
      property bool ccConfirm: true
      property int toastMs: 6000
      property bool toastLeft: false
      property bool osdOn: true
      property int osdMs: 1400
      property int lauMax: 60
      property int lauWidth: 680
      property string luDisplay: "icon"
      property bool luCompact: false
      property bool luGrid: false
      property string wsStyle: "dots"
      property bool wsEmpty: true
      property int wsSpacing: 12
      property bool mediaArt: true
      property bool mediaInfo: true
      property bool mediaControls: true
      property bool mediaEq: true
      property bool mediaCompact: false
      property string appsMode: "icons"
      property bool appsCompact: false
      property int appsMax: 8
      property bool trayIcons: true
      property bool trayLabels: false
      property int trayIcon: 18
      property int traySpacing: 8
      property string vitalsShow: "both"
      property string vitalsFmt: "pct"
      property bool vitalsCompact: false
      property bool wxIcon: true
      property bool wxTemp: true
      property bool wxCond: false
      property bool wxLoc: false
      property bool weatherF: false
      property string weatherCity: ""
      property bool volPct: true
      property bool batPct: true
      property bool ccWifi: true
      property bool ccBt: true
      property bool ccVol: true
      property bool ccBright: true
      property bool ccCompact: false
      property string setClick: "full"
      property bool qkDnd: true
      property bool qkAccent: true
      property bool qkZoom: false
      property bool qkWall: false
      property bool clockSec: false
      property string wpMode: "picker"
      property int wpInterval: 30
      property bool wpShuffle: true
      property string ntMode: "count"
      property bool capsules: true
      property string layoutLeft: "launcher,workspaces,media"
      property string layoutCenter: "apps"
      property string layoutRight: "tray,vitals,weather,status,cc,clock"
    }
  }

  Process {
    id: wx
    command: ["sh", "-c", "curl -s --max-time 5 'wttr.in/" + encodeURIComponent(s.weatherCity).replace(/'/g, "%27") + "?" + (s.weatherF ? "u" : "m") + "&format=%t%7C%C%7C%l' || echo --"]
    stdout: StdioCollector {
      onStreamFinished: {
        const p = this.text.trim().split("|")
        if (p.length < 3) {
          root.weather = "--"; root.weatherCond = ""; root.weatherLoc = ""
          return
        }
        root.weather = p[0].replace("+", "")
        root.weatherCond = p[1].trim()
        root.weatherLoc = p[2].split(",")[0].trim()
      }
    }
  }
  Process {
    id: net
    command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2 | head -1; echo ---; bluetoothctl show | grep -q 'Powered: yes' && echo on || echo off"]
    stdout: StdioCollector {
      onStreamFinished: {
        const p = this.text.split("---")
        root.ssid = p[0].trim()
        root.btOn = p.length > 1 && p[1].trim() === "on"
      }
    }
  }
  Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: net.running = true }
  Timer { interval: 600000; running: true; repeat: true; triggeredOnStart: true; onTriggered: wx.running = true }
  Timer { id: wxKick; interval: 800; onTriggered: wx.running = true }
  Connections {
    target: s
    function onWeatherFChanged() { wxKick.restart() }
    function onWeatherCityChanged() { wxKick.restart() }
  }

  // wallpaper slideshow (jpg/png only: this Qt build can't decode webp)
  Process {
    id: slideP
    command: [
      "sh", "-c",
      'd=$(printf %s "$1" | sed "s|^~|$HOME|"); find -L "$d" -maxdepth 2 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \\) | sort',
      "x", s.wallDir
    ]
    stdout: StdioCollector {
      onStreamFinished: {
        const l = this.text.split("\n").filter(x => x.trim() !== "")
        if (l.length === 0) return
        let next
        if (s.wpShuffle) {
          do { next = l[Math.floor(Math.random() * l.length)] } while (l.length > 1 && next === s.wallpaper)
        } else {
          next = l[(l.indexOf(s.wallpaper) + 1) % l.length]
        }
        s.wallpaper = next
      }
    }
  }
  Timer {
    interval: Math.max(1, s.wpInterval) * 60000
    running: s.wpMode === "slideshow"
    repeat: true
    onTriggered: slideP.running = true
  }

  component Btn: Rectangle {
    property alias icon: t.text
    property int size: 20
    property bool want: true
    property bool capsule: false
    signal clicked
    implicitWidth: 32; implicitHeight: 32; radius: 16
    color: capsule && s.capsules ? (m.containsMouse ? Qt.lighter(s.pill, 1.4) : s.pill)
                                 : (m.containsMouse ? "#33ffffff" : "transparent")
    Text { id: t; anchors.centerIn: parent; color: "#e6e6e6"; font.family: s.iconFont; font.pixelSize: parent.size }
    MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; onClicked: parent.clicked() }
  }

  component Ico: Text {
    property string name
    text: name
    color: "#e6e6e6"
    font.family: s.iconFont
    font.pixelSize: 18
  }

  component Lbl: Text { color: "#e6e6e6"; font.pixelSize: s.fontSize; font.family: s.fontFamily }

  component IconLbl: RowLayout {
    property string icon
    property string label
    property int maxLabel: 400
    spacing: 5
    Ico { name: parent.icon }
    Lbl { text: parent.label; visible: parent.label !== ""; elide: Text.ElideRight; Layout.maximumWidth: parent.maxLabel }
  }

  component Pill: Rectangle {
    default property alias content: row.data
    property bool want: true
    property int pad: 28
    property bool flat: false
    property alias gap: row.spacing
    implicitHeight: 32
    implicitWidth: row.implicitWidth + (flat ? 0 : pad)
    radius: s.pillRadius
    color: flat ? "transparent" : s.pill
    RowLayout { id: row; anchors.centerIn: parent; spacing: 12 }
  }

  component WLoader: Loader {
    required property string modelData
    Layout.alignment: Qt.AlignVCenter
    sourceComponent: root.comp(modelData)
    visible: item ? (item.want === undefined ? true : item.want) : false
  }

  // ───────── widgets ─────────
  Component {
    id: cLauncher
    Rectangle {
      property bool want: true
      implicitHeight: 32
      implicitWidth: lr.implicitWidth + (s.luCompact ? 8 : 12) + (s.luDisplay === "icon" ? 0 : 8)
      radius: s.launcherRadius
      color: s.capsules || s.luDisplay !== "icon" ? (lm.containsMouse ? Qt.lighter(s.pill, 1.4) : s.pill) : (lm.containsMouse ? "#33ffffff" : "transparent")
      RowLayout {
        id: lr
        anchors.centerIn: parent
        spacing: 6
        Ico { visible: s.luDisplay !== "text"; name: "apps"; font.pixelSize: 20 }
        Lbl { visible: s.luDisplay !== "icon"; text: "Apps" }
      }
      MouseArea { id: lm; anchors.fill: parent; hoverEnabled: true; onClicked: extras.launcherOpen = !extras.launcherOpen }
    }
  }
  Component { id: cCc; Btn { icon: "tune"; capsule: true; radius: s.ccRadius; onClicked: extras.ccOpen = !extras.ccOpen } }
  Component { id: cSettings; Btn { icon: "settings"; capsule: true; radius: s.settingsRadius; onClicked: root.settingsOpen = !root.settingsOpen } }
  Component { id: cWallpaper; Btn { icon: "wallpaper"; capsule: true; radius: s.wallpaperRadius; onClicked: extras.wallOpen = !extras.wallOpen } }
  Component { id: cVitals; Vitals { cfg: s } }

  Component {
    id: cWorkspaces
    Pill {
      radius: s.workspaceRadius
      gap: s.wsSpacing

      Repeater {
        model: Hyprland.workspaces
        Rectangle {
          id: wsd
          required property var modelData
          readonly property bool occupied: (modelData.lastIpcObject?.windows ?? 1) > 0
          visible: modelData.id > 0 && (s.wsEmpty || modelData.focused || occupied)
          implicitWidth: s.wsStyle === "dots" ? (modelData.focused ? 22 : 9) : (s.wsStyle === "numbers" ? 22 : 20)
          implicitHeight: s.wsStyle === "dots" ? 9 : 22
          radius: s.wsStyle === "dots" ? 5 : 11
          color: s.wsStyle === "dots" ? (modelData.focused ? s.accent : "#55ffffff")
               : s.wsStyle === "numbers" ? (modelData.focused ? s.accent : "transparent")
               : "transparent"

          Lbl {
            visible: s.wsStyle === "numbers"
            anchors.centerIn: parent
            text: wsd.modelData.id
            color: wsd.modelData.focused ? "#141218" : "#ccffffff"
            font.bold: wsd.modelData.focused
          }
          Ico {
            visible: s.wsStyle === "icons"
            anchors.centerIn: parent
            name: wsd.modelData.focused ? "radio_button_checked" : (wsd.occupied ? "circle" : "radio_button_unchecked")
            color: wsd.modelData.focused ? s.accent : "#aaffffff"
            font.pixelSize: 14
          }
          MouseArea { anchors.fill: parent; onClicked: wsd.modelData.activate() }
        }
      }
    }
  }

  Component {
    id: cMedia
    Pill {
      want: s.showMedia && root.player !== null
      radius: s.mediaRadius
      pad: s.mediaCompact ? 20 : 28
      gap: s.mediaCompact ? 8 : 12

      ClippingRectangle {
        visible: s.mediaArt && (root.player?.trackArtUrl ?? "") !== ""
        radius: 6
        color: "transparent"
        implicitWidth: 22; implicitHeight: 22
        Image {
          anchors.fill: parent
          source: root.player?.trackArtUrl ?? ""
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
        }
      }
      Lbl { visible: s.mediaInfo; text: root.player ? root.player.trackTitle : ""; elide: Text.ElideRight; Layout.maximumWidth: s.mediaCompact ? 90 : 140 }
      Btn { visible: s.mediaControls && !s.mediaCompact; icon: "skip_previous"; size: 18; implicitWidth: 26; onClicked: root.player?.previous() }
      Btn { visible: s.mediaControls; icon: root.player && root.player.isPlaying ? "pause" : "play_arrow"; size: 20; implicitWidth: 26; onClicked: root.player?.togglePlaying() }
      Btn { visible: s.mediaControls && !s.mediaCompact; icon: "skip_next"; size: 18; implicitWidth: 26; onClicked: root.player?.next() }
      Btn { visible: s.mediaEq; icon: "equalizer"; size: 18; implicitWidth: 26; onClicked: extras.toggleMedia() }
    }
  }

  Component {
    id: cApps
    Pill {
      want: s.showDock
      flat: !s.capsules
      pad: 12
      radius: s.appsRadius
      gap: s.capsules ? 4 : 8
      implicitHeight: s.capsules ? Math.max(32, s.dockIcon + (s.appsCompact ? 4 : 8) + 8)
                                 : Math.max(32, s.dockIcon + (s.appsCompact ? 8 : 16))
      Repeater {
        model: ToplevelManager.toplevels
        Rectangle {
          id: ap
          required property var modelData
          required property int index
          readonly property var entry: DesktopEntries.heuristicLookup(modelData.appId)
          readonly property int ipad: s.capsules ? (s.appsCompact ? 4 : 8) : (s.appsCompact ? 8 : 16)
          visible: index < s.appsMax
          implicitHeight: s.dockIcon + ipad
          implicitWidth: ar.implicitWidth + ipad
          radius: s.capsules ? Math.max(4, s.appsRadius - 4) : s.appsRadius
          color: modelData.activated ? Qt.lighter(s.pill, 1.6) : (s.capsules ? "transparent" : s.pill)
          border.width: modelData.activated ? 1 : 0
          border.color: s.accent
          RowLayout {
            id: ar
            anchors.centerIn: parent
            spacing: 6
            IconImage {
              visible: s.appsMode !== "names"
              implicitSize: s.dockIcon
              source: Quickshell.iconPath(ap.entry?.icon ?? ap.modelData.appId, "application-x-executable")
            }
            Lbl {
              visible: s.appsMode !== "icons"
              text: ap.entry?.name ?? ap.modelData.appId
              elide: Text.ElideRight
              Layout.maximumWidth: 110
            }
          }
          MouseArea { anchors.fill: parent; onClicked: modelData.activate() }
        }
      }
    }
  }

  Component {
    id: cTray
    Pill {
      want: s.showTray
      flat: !s.capsules
      pad: 12
      radius: s.trayRadius
      gap: s.traySpacing
      implicitHeight: Math.max(32, s.trayIcon + 12)
      Repeater {
        model: SystemTray.items
        Rectangle {
          id: ti
          required property var modelData
          readonly property bool showIcon: s.trayIcons || !s.trayLabels
          height: s.capsules ? Math.max(24, s.trayIcon + 6) : 32
          width: tr.implicitWidth + (s.capsules ? 8 : 14)
          radius: s.capsules ? Math.max(4, s.trayRadius - 4) : s.trayRadius
          color: s.capsules ? "transparent" : s.pill
          RowLayout {
            id: tr
            anchors.centerIn: parent
            spacing: 6
            IconImage { visible: ti.showIcon; implicitSize: s.trayIcon; source: ti.modelData.icon }
            Lbl {
              visible: s.trayLabels
              text: ti.modelData.tooltipTitle || ti.modelData.title || ti.modelData.id
              elide: Text.ElideRight
              Layout.maximumWidth: 100
            }
          }
          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => mouse.button === Qt.LeftButton ? modelData.activate() : modelData.secondaryActivate()
          }
        }
      }
    }
  }

  Component {
    id: cWeather
    Pill {
      want: s.showWeather
      radius: s.weatherRadius
      Ico { visible: s.wxIcon; name: "partly_cloudy_day" }
      Lbl { visible: text !== ""; text: root.weatherText() }
    }
  }

  Component {
    id: cStatus
    Pill {
      want: s.showWifi || s.showBt || s.showVolume || s.showBattery
      radius: s.statusRadius
      IconLbl { visible: s.showWifi; icon: root.ssid !== "" ? "wifi" : "wifi_off"; label: root.ssid; maxLabel: 130 }
      Ico { visible: s.showBt; name: root.btOn ? "bluetooth" : "bluetooth_disabled"; opacity: root.btOn ? 1 : 0.4 }
      IconLbl { visible: s.showVolume; icon: root.volIcon(); label: root.audio && s.volPct ? Math.round(root.audio.volume * 100) + "%" : "" }
      IconLbl { visible: s.showBattery; icon: root.batIcon(); label: s.batPct ? Math.round(UPower.displayDevice.percentage * 100) + "%" : "" }
    }
  }

  Component {
    id: cClock
    Pill {
      want: true
      flat: !s.capsules
      pad: 20
      radius: s.clockRadius
      Column {
        Text { anchors.right: parent.right; color: "#fff"; font.pixelSize: 12; font.bold: true; font.family: s.fontFamily
               text: Qt.formatDateTime(clock.date, (s.clock24 ? "HH:mm" : "h:mm") + (s.clockSec ? ":ss" : "") + (s.clock24 ? "" : " AP")) }
        Text { visible: s.showDate; anchors.right: parent.right; color: "#b3ffffff"; font.pixelSize: 11; font.family: s.fontFamily
               text: Qt.formatDateTime(clock.date, "ddd, M/d") }
      }
    }
  }

  // ───────── overlays ─────────

  Notifs { id: notifs; cfg: s }
  Extras { id: extras; cfg: s; onOpenSettings: root.settingsOpen = true }
Wallpaper { cfg: s }
WidgetManager { id: widgetManager }
  Settings { cfg: s; shown: root.settingsOpen; onDismissed: root.settingsOpen = false }
  // ───────── bar ─────────
  Variants {
    model: Quickshell.screens
    PanelWindow {
      required property var modelData
      screen: modelData
      anchors { bottom: !s.barTop; top: s.barTop; left: true; right: true }
      implicitHeight: s.barHeight
      margins { left: s.barMargin; right: s.barMargin; top: s.barTop ? s.barMargin : 0; bottom: s.barTop ? 0 : s.barMargin }
      color: "transparent"

      Rectangle {
        anchors.fill: parent
        color: Qt.alpha(s.bg, s.alpha)
        radius: s.barMargin > 0 ? s.pillRadius + 6 : 0
        border.width: s.devOutline ? 1 : 0
        border.color: "red"

        RowLayout {
          anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
          spacing: 8
          Repeater { model: root.zone(s.layoutLeft); WLoader {} }
        }
        RowLayout {
          anchors.centerIn: parent
          spacing: 8
          Repeater { model: root.zone(s.layoutCenter); WLoader {} }
        }
        RowLayout {
          anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
          spacing: 8
          Repeater { model: root.zone(s.layoutRight); WLoader {} }
        }
      }
    }
  }
}
