import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

FloatingWindow {
  id: win
  required property var cfg
  property bool shown: false
  property string page: "welcome"
  property string q: ""
  property string fq: ""
  property int taps: 0
  property real zoom: 1.0
  property var fonts: []
  property var mons: []
  property var walls: []

  property string cpuInfo: "detecting..."
  property string gpuInfo: "detecting..."
  property string ramInfo: "detecting..."
  property string diskInfo: "detecting..."
  property string osInfo: "detecting..."
  property string kernelInfo: "detecting..."
  property string deInfo: "detecting..."
  property string wmInfo: "detecting..."
  property string qsInfo: "detecting..."
  property string hostInfo: "detecting..."

  signal dismissed

  readonly property string version: "1.4.0"

  visible: shown
  onVisibleChanged: if (!visible) dismissed()
  onShownChanged: if (shown) refresh()
  Component.onCompleted: refresh()
  title: "Quickshell Settings"
  implicitWidth: 1040
  implicitHeight: 720
  color: base

  readonly property color base: cfg.bg
  readonly property color side: Qt.lighter(cfg.bg, 1.5)
  readonly property color card: cfg.pill
  readonly property color acc: cfg.accent
  readonly property color onAcc: (acc.r * 0.299 + acc.g * 0.587 + acc.b * 0.114) > 0.55 ? "#141218" : "#ffffff"
  readonly property color txt: "#e6e6e6"
  readonly property color dim: "#99e6e6e6"
  readonly property string ff: cfg.fontFamily
  readonly property string ifont: cfg.iconFont
  readonly property int r: Math.min(cfg.pillRadius + 6, 22)

  readonly property var nav: {
    const n = [
      { k: "welcome", icon: "home", label: "Welcome" },
      { k: "theme", icon: "palette", label: "Theme" },
      { k: "display", icon: "monitor", label: "Display" },
      { k: "bar", icon: "dock_to_bottom", label: "Bar" },
      { k: "dock", icon: "apps", label: "Dock" },
      { k: "layout", icon: "view_quilt", label: "Layout" },
      { k: "widgets", icon: "widgets", label: "Widgets" },
      { k: "audio", icon: "equalizer", label: "Audio" },
      { k: "cc", icon: "tune", label: "Control center" },
      { k: "notif", icon: "notifications", label: "Notifications" },
      { k: "launcher", icon: "rocket_launch", label: "Launcher" },
      { k: "general", icon: "settings", label: "General" },
      { k: "about", icon: "info", label: "About" }
    ]
    if (cfg.devMode) n.push({ k: "dev", icon: "developer_mode", label: "Developer" })
    return n
  }

  onPageChanged: if (!nav.some(n => n.k === page)) page = "welcome"

  property var entries: [
    { icon: "auto_awesome", label: "Styles", desc: "One-click looks for bar and window", kw: "preset glass flat neon material", page: "theme", rec: true },
    { icon: "wallpaper", label: "Wallpaper", desc: "Pick a background image", kw: "background picture image", page: "theme", rec: true },
    { icon: "text_fields", label: "Fonts", desc: "Font family and size", kw: "typeface text size", page: "theme", rec: true },
    { icon: "palette", label: "Accent color", desc: "Hex colors for the theme", kw: "colour theme hex", page: "theme", rec: false },
    { icon: "monitor", label: "Display scale", desc: "Zoom and UI size", kw: "zoom scale dpi hidpi magnifier", page: "display", rec: true },
    { icon: "aspect_ratio", label: "Resolution", desc: "Screen resolution and refresh rate", kw: "monitor hz refresh", page: "display", rec: true },
    { icon: "opacity", label: "Bar opacity", desc: "Bar transparency", kw: "transparent see through", page: "bar", rec: true },
    { icon: "widgets", label: "Bar widgets", desc: "Weather, media, tray, vitals, clock", kw: "module toggle show hide wifi battery volume", page: "bar", rec: true },
    { icon: "view_quilt", label: "Bar layout", desc: "Add and move widgets", kw: "widgets order move add remove left center right", page: "layout", rec: true },
    { icon: "widgets", label: "Widget settings", desc: "Configure each bar widget", kw: "launcher workspaces media apps tray cpu ram weather status control center clock wallpaper slideshow notifications compact", page: "widgets", rec: true },
    { icon: "dock_to_bottom", label: "Bar position", desc: "Top or bottom, floating margin", kw: "edge float margin top bottom", page: "bar", rec: false },
    { icon: "apps", label: "Dock", desc: "Running apps and icon size", kw: "taskbar icons", page: "dock", rec: false },
    { icon: "equalizer", label: "Equalizer", desc: "Bass, treble and presets", kw: "eq audio sound music", page: "audio", rec: true },
    { icon: "volume_up", label: "On-screen display", desc: "Volume popup", kw: "osd popup", page: "audio", rec: false },
    { icon: "tune", label: "Control center", desc: "Choose what the panel shows", kw: "quick settings panel", page: "cc", rec: false },
    { icon: "notifications", label: "Notifications", desc: "Toasts and Do Not Disturb", kw: "toast dnd alerts", page: "notif", rec: true },
    { icon: "rocket_launch", label: "Launcher", desc: "Size and results", kw: "apps search", page: "launcher", rec: false },
    { icon: "settings", label: "Icon font", desc: "Font used for icons", kw: "material symbols", page: "general", rec: false },
    { icon: "info", label: "About", desc: "System information", kw: "version system specs cpu gpu ram kernel", page: "about", rec: false },
    { icon: "developer_mode", label: "Developer options", desc: "Reload, reset, debug outline", kw: "dev debug reload reset", page: "dev", rec: false, dev: true }
  ]

  readonly property var filtered: {
    const s = q.toLowerCase().trim()
    return entries.filter(e => (!e.dev || cfg.devMode) && (s === "" ? e.rec : (e.label + " " + e.desc + " " + e.kw).toLowerCase().includes(s)))
  }

  readonly property var fontsShown: fonts.filter(f => f.toLowerCase().includes(fq.toLowerCase())).slice(0, 200)

  property var styles: [
    { n: "Material You", a: "#cfbcff", b: "#141218", p: "#2b2930", al: 0.9, rad: 16, h: 48 },
    { n: "Glass", a: "#8ab4f8", b: "#0b1220", p: "#25324a", al: 0.55, rad: 16, h: 46 },
    { n: "Flat", a: "#e6e6e6", b: "#101010", p: "#1c1c1c", al: 1.0, rad: 4, h: 40 },
    { n: "Neon", a: "#39ff88", b: "#06090a", p: "#101d17", al: 0.95, rad: 10, h: 44 },
    { n: "Rosé", a: "#f5a6c8", b: "#1a1016", p: "#3a2230", al: 0.9, rad: 16, h: 46 },
    { n: "Everforest", a: "#a7c080", b: "#2d353b", p: "#3d484d", al: 0.92, rad: 16, h: 46 },
    { n: "Gruvbox", a: "#fabd2f", b: "#282828", p: "#3c3836", al: 0.92, rad: 8, h: 46 },
    { n: "Nord", a: "#88c0d0", b: "#2e3440", p: "#3b4252", al: 0.92, rad: 12, h: 46 },
    { n: "Catppuccin", a: "#cba6f7", b: "#1e1e2e", p: "#313244", al: 0.92, rad: 16, h: 46 },
    { n: "Tokyo Night", a: "#7aa2f7", b: "#1a1b26", p: "#24283b", al: 0.92, rad: 12, h: 46 },
    { n: "Rosé Pine", a: "#c4a7e7", b: "#191724", p: "#26233a", al: 0.92, rad: 16, h: 46 },
    { n: "Dracula", a: "#bd93f9", b: "#282a36", p: "#383a4a", al: 0.92, rad: 10, h: 46 },
    { n: "Kanagawa", a: "#7e9cd8", b: "#1f1f28", p: "#2a2a37", al: 0.92, rad: 12, h: 46 }
  ]

  property string wsel: "launcher"
  property string popId: ""
  readonly property var popInfo: wlist.find(w => w.k === popId) ?? { icon: "widgets", label: "" }

  property var wlist: [
    { k: "launcher", icon: "rocket_launch", label: "Launcher" },
    { k: "workspaces", icon: "grid_view", label: "Workspaces" },
    { k: "media", icon: "music_note", label: "Media" },
    { k: "apps", icon: "apps", label: "Running apps" },
    { k: "tray", icon: "inventory_2", label: "Tray" },
    { k: "vitals", icon: "memory", label: "CPU / RAM" },
    { k: "weather", icon: "partly_cloudy_day", label: "Weather" },
    { k: "status", icon: "network_wifi", label: "Status" },
    { k: "cc", icon: "tune", label: "Control Center" },
    { k: "settings", icon: "settings", label: "Settings" },
    { k: "clock", icon: "schedule", label: "Clock" },
    { k: "wallpaper", icon: "wallpaper", label: "Wallpaper" },
    { k: "notif", icon: "notifications", label: "Notifications" }
  ]

  property var accents: ["#cfbcff", "#8ab4f8", "#8fd694", "#f5a6c8", "#ffb74d", "#39ff88", "#e6e6e6"]

  function refresh() {
    fontP.running = true
    monP.running = true
    wallP.running = true
    cpuP.running = true
    gpuP.running = true
    ramP.running = true
    diskP.running = true
    osP.running = true
    kernelP.running = true
    deP.running = true
    wmP.running = true
    qsP.running = true
    hostP.running = true
  }

  function apply(st) {
    cfg.accent = st.a
    cfg.bg = st.b
    cfg.pill = st.p
    cfg.alpha = st.al
    cfg.pillRadius = st.rad
    cfg.barHeight = st.h
  }

  function setHex(key, t) {
    let h = t.trim()
    if (!h.startsWith("#")) h = "#" + h
    if (/^#[0-9a-fA-F]{6}$/.test(h) && cfg[key] !== h) cfg[key] = h
  }

  function rescanWalls() { wallP.running = true }

  // Normalises a layout-editor widget id to a Widgets-page key ("" if unknown).
  function widgetKey(id) {
    const alias = {
      dock: "apps", running: "apps", runningapps: "apps", taskbar: "apps",
      cpu: "vitals", ram: "vitals", sysmon: "vitals", stats: "vitals",
      wifi: "status", bt: "status", bluetooth: "status", volume: "status", battery: "status",
      controlcenter: "cc", notifications: "notif", notification: "notif",
      ws: "workspaces", workspace: "workspaces", date: "clock", time: "clock",
      wall: "wallpaper"
    }
    const raw = String(id).toLowerCase().replace(/[^a-z]/g, "")
    const k = alias[raw] || raw
    return wlist.some(w => w.k === k) ? k : ""
  }

  // Layout editor gear calls this: pops the widget's settings over the window.
  function openWidget(id) {
    const k = widgetKey(id)
    if (k !== "") {
      popId = k
      wsel = k
    } else {
      page = "widgets"
    }
    shown = true
  }

  function resetAll() {
    apply(styles[0])
    cfg.barTop = false
    cfg.barMargin = 0
    cfg.showWeather = true
    cfg.showMedia = true
    cfg.showTray = true
    cfg.showVitals = true
    cfg.showWifi = true
    cfg.showBt = true
    cfg.showVolume = true
    cfg.showBattery = true
    cfg.showDate = true
    cfg.clock24 = false
    cfg.fontSize = 13
    cfg.wallpaper = ""
    cfg.fontFamily = "Google Sans"
    cfg.iconFont = "Material Symbols Rounded"
    cfg.dockIcon = 22
    cfg.showDock = true
    cfg.osdOn = true
    cfg.osdMs = 1400
    cfg.toastMs = 6000
    cfg.toastLeft = false
    cfg.ccPower = true
    cfg.ccMic = true
    cfg.ccApps = true
    cfg.ccConfirm = true
    cfg.lauMax = 60
    cfg.lauWidth = 680

    cfg.luDisplay = "icon"
    cfg.luCompact = false
    cfg.luGrid = false
    cfg.wsStyle = "dots"
    cfg.wsEmpty = true
    cfg.wsSpacing = 12
    cfg.mediaArt = true
    cfg.mediaInfo = true
    cfg.mediaControls = true
    cfg.mediaEq = true
    cfg.mediaCompact = false
    cfg.appsMode = "icons"
    cfg.appsCompact = false
    cfg.appsMax = 8
    cfg.trayIcons = true
    cfg.trayLabels = false
    cfg.trayIcon = 18
    cfg.traySpacing = 8
    cfg.vitalsShow = "both"
    cfg.vitalsFmt = "pct"
    cfg.vitalsCompact = false
    cfg.wxIcon = true
    cfg.wxTemp = true
    cfg.wxCond = false
    cfg.wxLoc = false
    cfg.weatherF = false
    cfg.weatherCity = ""
    cfg.volPct = true
    cfg.batPct = true
    cfg.ccWifi = true
    cfg.ccBt = true
    cfg.ccVol = true
    cfg.ccBright = true
    cfg.ccCompact = false
    cfg.setClick = "full"
    cfg.qkDnd = true
    cfg.qkAccent = true
    cfg.qkZoom = false
    cfg.qkWall = false
    cfg.clockSec = false
    cfg.wpMode = "picker"
    cfg.wpInterval = 30
    cfg.wpShuffle = true
    cfg.ntMode = "count"
    cfg.capsules = true
  }

  function recScale(m) {
    return m.width >= 3840 ? 2 : m.width >= 2880 ? 1.75 : m.width >= 2560 ? 1.5 : 1
  }

  function modes(m) {
    const out = []

    for (const s of (m.availableModes || [])) {
      const mt = /^(\d+)x(\d+)@([\d.]+)Hz$/.exec(s)
      if (!mt) continue

      out.push({
        w: +mt[1],
        h: +mt[2],
        hz: +mt[3]
      })
    }

    return out
  }

  function setMon(m, w, h, hz, sc) {
    const cmd =
      "hl.monitor({ output = \"" + m.name +
      "\", mode = \"" + w + "x" + h + "@" + Number(hz).toFixed(2) +
      "\", position = \"" + m.x + "x" + m.y +
      "\", scale = " + Number(sc) + " })"

    Quickshell.execDetached([
      "hyprctl",
      "eval",
      cmd
    ])

    monTimer.restart()
  }

  function setZoom(v) {
    zoom = v
    Quickshell.execDetached([
      "hyprctl",
      "keyword",
      "cursor:zoom_factor",
      String(v)
    ])
  }

  component Ico: Text {
    property string name
    text: name
    color: win.txt
    font.family: win.ifont
    font.pixelSize: 20
  }

  component Lbl: Text {
    color: win.txt
    font.family: win.ff
    font.pixelSize: 14
  }

  component Card: Rectangle {
    default property alias content: cl.data

    Layout.fillWidth: true
    implicitHeight: cl.implicitHeight + 28
    radius: win.r
    color: win.card

    ColumnLayout {
      id: cl
      anchors {
        fill: parent
        margins: 14
      }
      spacing: 14
    }
  }

  component Opt: RowLayout {
    id: o
    property string label
    property string hint
    Layout.fillWidth: true
    spacing: 12
    ColumnLayout {
      Layout.fillWidth: true
      Layout.minimumWidth: 100
      spacing: 2
      Lbl { text: o.label; Layout.fillWidth: true; elide: Text.ElideRight }
      Lbl { visible: o.hint !== ""; text: o.hint; font.pixelSize: 12; color: win.dim; Layout.fillWidth: true; wrapMode: Text.WordWrap }
    }
  }

  component Toggle: Rectangle {
    id: tg

    property bool on
    signal flip

    implicitWidth: 44
    implicitHeight: 24
    radius: 12

    color: on ? win.acc : "#44ffffff"

    Rectangle {
      width: 18
      height: 18
      radius: 9
      y: 3
      x: tg.on ? 23 : 3
      color: tg.on ? win.onAcc : "#fff"

      Behavior on x {
        NumberAnimation {
          duration: 120
        }
      }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: tg.flip()
    }
  }

  component RBtn: Rectangle {
    id: rb

    property string icon
    signal clicked

    implicitWidth: 30
    implicitHeight: 30
    radius: 15

    color: ma.containsMouse ? "#33ffffff" : "#1affffff"

    Ico {
      anchors.centerIn: parent
      name: rb.icon
      font.pixelSize: 18
    }

    MouseArea {
      id: ma
      anchors.fill: parent
      hoverEnabled: true
      onClicked: rb.clicked()
    }
  }

  component TBtn: Rectangle {
    id: tb

    property string label
    property string icon
    signal clicked

    Layout.fillWidth: true
    implicitHeight: 42
    radius: win.r

    color: tma.containsMouse ? "#33ffffff" : "#1affffff"

    RowLayout {
      anchors.centerIn: parent
      spacing: 8

      Ico {
        name: tb.icon
        font.pixelSize: 18
      }

      Lbl {
        text: tb.label
      }
    }

    MouseArea {
      id: tma
      anchors.fill: parent
      hoverEnabled: true
      onClicked: tb.clicked()
    }
  }

  component Step: RowLayout {   // slider-step
    id: st
    property real value
    property real from
    property real to
    property real step
    property int dec: 0
    property bool live: true
    property bool dragging: false
    property real cur: value
    signal moved(real v)
    onValueChanged: if (!dragging) cur = value
    spacing: 10
    Layout.minimumWidth: 150
    Layout.preferredWidth: 230
    Layout.maximumWidth: 260
    Rectangle {
      id: trk
      Layout.fillWidth: true
      Layout.minimumWidth: 90
      Layout.alignment: Qt.AlignVCenter
      implicitHeight: 6; radius: 3
      color: "#33ffffff"
      readonly property real frac: Math.max(0, Math.min(1, (st.cur - st.from) / (st.to - st.from)))
      Rectangle { width: 9 + trk.frac * (trk.width - 18); height: parent.height; radius: 3; color: win.acc }
      Rectangle { width: 18; height: 18; radius: 9; color: win.acc; anchors.verticalCenter: parent.verticalCenter; x: trk.frac * (trk.width - 18) }
      MouseArea {
        anchors { fill: parent; topMargin: -12; bottomMargin: -12 }
        preventStealing: true
        function setFrom(m) {
          const f = Math.max(0, Math.min(1, (m.x - 9) / (trk.width - 18)))
          const c = Math.max(st.from, Math.min(st.to, st.from + Math.round(f * (st.to - st.from) / st.step) * st.step))
          if (c === st.cur) return
          st.cur = c
          if (st.live) st.moved(c)
        }
        onPressed: m => { st.dragging = true; setFrom(m) }
        onPositionChanged: m => { if (pressed) setFrom(m) }
        onReleased: { st.dragging = false; if (!st.live) st.moved(st.cur); else st.cur = st.value }
        onCanceled: { st.dragging = false; st.cur = st.value }
      }
    }
    Lbl { text: st.cur.toFixed(st.dec); Layout.preferredWidth: 48; horizontalAlignment: Text.AlignRight }
  }

  component Field: Rectangle {
    id: fld

    property string value
    property string placeholder

    signal edited(string t)
    signal typed(string t)

    onValueChanged: if (ti.text !== value) ti.text = value

    Component.onCompleted: ti.text = value

    implicitWidth: 200
    implicitHeight: 34
    radius: 10
    color: win.base

    MouseArea {
      anchors.fill: parent

      onPressed: m => {
        ti.forceActiveFocus()
        m.accepted = false
      }
    }

    TextInput {
      id: ti

      anchors {
        fill: parent
        margins: 8
      }

      verticalAlignment: TextInput.AlignVCenter
      color: win.txt
      font.family: win.ff
      font.pixelSize: 13
      clip: true
      selectByMouse: true

      onEditingFinished: fld.edited(text)
      onTextChanged: fld.typed(text)

      Lbl {
        visible: ti.text === ""
        text: fld.placeholder
        color: win.dim
        font.pixelSize: 13
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }

  component Seg: Row {   // segmented choice
    id: sg
    property var options: []
    property string value
    signal picked(string k)
    spacing: 6
    Layout.alignment: Qt.AlignVCenter
    Repeater {
      model: sg.options
      Rectangle {
        required property var modelData
        readonly property bool cur: sg.value === modelData.k
        implicitWidth: sgl.implicitWidth + 22
        implicitHeight: 30
        radius: 15
        color: cur ? win.acc : (sgm.containsMouse ? "#33ffffff" : "#1affffff")
        Lbl {
          id: sgl
          anchors.centerIn: parent
          text: modelData.label
          font.pixelSize: 12
          color: parent.cur ? win.onAcc : win.txt
        }
        MouseArea {
          id: sgm
          anchors.fill: parent
          hoverEnabled: true
          onClicked: sg.picked(modelData.k)
        }
      }
    }
  }

  component Sel: Opt {   // option row with a Seg
    id: sl
    property var options: []
    property string value
    signal picked(string k)
    Seg {
      options: sl.options
      value: sl.value
      onPicked: k => sl.picked(k)
    }
  }

  component Num: Opt {   // option row with a Step slider
    id: nmr
    property real value
    property real from
    property real to
    property real step
    property int dec: 0
    signal moved(real v)
    Step {
      value: nmr.value
      from: nmr.from
      to: nmr.to
      step: nmr.step
      dec: nmr.dec
      onMoved: v => nmr.moved(v)
    }
  }

  component Sw: Opt {   // option row with a built-in toggle
    id: sw
    property bool on
    signal flip
    Toggle {
      on: sw.on
      onFlip: sw.flip()
    }
  }

  component WidgetPanel: ColumnLayout {   // the settings card for one widget
    id: panel
    property string sel: ""
    Layout.fillWidth: true
    spacing: 14

    readonly property var radiusKeys: ({
      launcher: "launcherRadius", workspaces: "workspaceRadius", media: "mediaRadius",
      apps: "appsRadius", tray: "trayRadius", vitals: "vitalsRadius", weather: "weatherRadius",
      status: "statusRadius", cc: "ccRadius", settings: "settingsRadius", clock: "clockRadius",
      wallpaper: "wallpaperRadius", notif: "notifsRadius"
    })
    readonly property string rk: radiusKeys[sel] ?? ""

          // Launcher
          Card {
            visible: panel.sel === "launcher"

            Sel {
              label: "Display"
              hint: "What the launcher button shows in the bar"
              options: [{ k: "icon", label: "Icon" }, { k: "text", label: "Text" }, { k: "both", label: "Both" }]
              value: win.cfg.luDisplay
              onPicked: k => win.cfg.luDisplay = k
            }
            Sw {
              label: "Compact"
              hint: "Tighter padding on the bar button"
              on: win.cfg.luCompact
              onFlip: win.cfg.luCompact = !win.cfg.luCompact
            }
            Num {
              label: "Max results"
              value: win.cfg.lauMax; from: 20; to: 100; step: 10
              onMoved: v => win.cfg.lauMax = v
            }
            Sw {
              label: "Grid view"
              hint: "Show results as a grid of icons instead of a list"
              on: win.cfg.luGrid
              onFlip: win.cfg.luGrid = !win.cfg.luGrid
            }
            Num {
              label: "Width"
              value: win.cfg.lauWidth; from: 480; to: 900; step: 40
              onMoved: v => win.cfg.lauWidth = v
            }
            TBtn {
              label: "Open launcher"
              icon: "rocket_launch"
              onClicked: Quickshell.execDetached(["qs", "ipc", "call", "launcher", "toggle"])
            }
          }

          // Workspaces
          Card {
            visible: panel.sel === "workspaces"

            Sel {
              label: "Style"
              options: [{ k: "dots", label: "Dots" }, { k: "numbers", label: "Numbers" }, { k: "icons", label: "Symbols" }]
              value: win.cfg.wsStyle
              onPicked: k => win.cfg.wsStyle = k
            }
            Sw {
              label: "Show empty workspaces"
              hint: "Off shows only workspaces that have windows"
              on: win.cfg.wsEmpty
              onFlip: win.cfg.wsEmpty = !win.cfg.wsEmpty
            }
            Num {
              label: "Spacing"
              value: win.cfg.wsSpacing; from: 2; to: 16; step: 2
              onMoved: v => win.cfg.wsSpacing = v
            }
          }

          // Media
          Card {
            visible: panel.sel === "media"

            Sw {
              label: "Show in bar"
              on: win.cfg.showMedia
              onFlip: win.cfg.showMedia = !win.cfg.showMedia
            }
            Sw {
              label: "Artwork"
              on: win.cfg.mediaArt
              onFlip: win.cfg.mediaArt = !win.cfg.mediaArt
            }
            Sw {
              label: "Track info"
              hint: "Title and artist"
              on: win.cfg.mediaInfo
              onFlip: win.cfg.mediaInfo = !win.cfg.mediaInfo
            }
            Sw {
              label: "Playback controls"
              hint: "Previous, play/pause, next"
              on: win.cfg.mediaControls
              onFlip: win.cfg.mediaControls = !win.cfg.mediaControls
            }
            Sw {
              label: "Equalizer button"
              on: win.cfg.mediaEq
              onFlip: win.cfg.mediaEq = !win.cfg.mediaEq
            }
            Sw {
              label: "Compact"
              on: win.cfg.mediaCompact
              onFlip: win.cfg.mediaCompact = !win.cfg.mediaCompact
            }
            Sw {
              label: "Equalizer enabled"
              hint: "Off bypasses all bands"
              on: win.cfg.eqOn
              onFlip: win.cfg.eqOn = !win.cfg.eqOn
            }
          }

          // Running apps
          Card {
            visible: panel.sel === "apps"

            Sw {
              label: "Show running apps"
              on: win.cfg.showDock
              onFlip: win.cfg.showDock = !win.cfg.showDock
            }
            Sel {
              label: "Show"
              options: [{ k: "icons", label: "Icons" }, { k: "names", label: "Names" }, { k: "both", label: "Both" }]
              value: win.cfg.appsMode
              onPicked: k => win.cfg.appsMode = k
            }
            Num {
              label: "Icon size"
              value: win.cfg.dockIcon; from: 16; to: 34; step: 2
              onMoved: v => win.cfg.dockIcon = v
            }
            Sw {
              label: "Compact"
              on: win.cfg.appsCompact
              onFlip: win.cfg.appsCompact = !win.cfg.appsCompact
            }
            Num {
              label: "Max apps"
              hint: "Extra apps are hidden"
              value: win.cfg.appsMax; from: 3; to: 20; step: 1
              onMoved: v => win.cfg.appsMax = v
            }
          }

          // Tray
          Card {
            visible: panel.sel === "tray"

            Sw {
              label: "Show in bar"
              on: win.cfg.showTray
              onFlip: win.cfg.showTray = !win.cfg.showTray
            }
            Sw {
              label: "Icons"
              on: win.cfg.trayIcons
              onFlip: win.cfg.trayIcons = !win.cfg.trayIcons
            }
            Num {
              label: "Icon size"
              visible: win.cfg.trayIcons
              value: win.cfg.trayIcon; from: 14; to: 28; step: 2
              onMoved: v => win.cfg.trayIcon = v
            }
            Sw {
              label: "Labels"
              hint: "Show each app's name next to its icon"
              on: win.cfg.trayLabels
              onFlip: win.cfg.trayLabels = !win.cfg.trayLabels
            }
            Num {
              label: "Spacing"
              value: win.cfg.traySpacing; from: 2; to: 16; step: 2
              onMoved: v => win.cfg.traySpacing = v
            }
          }

          // CPU / RAM
          Card {
            visible: panel.sel === "vitals"

            Sw {
              label: "Show in bar"
              on: win.cfg.showVitals
              onFlip: win.cfg.showVitals = !win.cfg.showVitals
            }
            Sel {
              label: "Show"
              options: [{ k: "cpu", label: "CPU" }, { k: "ram", label: "RAM" }, { k: "both", label: "Both" }]
              value: win.cfg.vitalsShow
              onPicked: k => win.cfg.vitalsShow = k
            }
            Sel {
              label: "Format"
              options: [{ k: "pct", label: "Percentage" }, { k: "graph", label: "Graph" }]
              value: win.cfg.vitalsFmt
              onPicked: k => win.cfg.vitalsFmt = k
            }
            Sw {
              label: "Compact"
              on: win.cfg.vitalsCompact
              onFlip: win.cfg.vitalsCompact = !win.cfg.vitalsCompact
            }
          }

          // Weather
          Card {
            visible: panel.sel === "weather"

            Sw {
              label: "Show in bar"
              on: win.cfg.showWeather
              onFlip: win.cfg.showWeather = !win.cfg.showWeather
            }
            Sw {
              label: "Icon"
              on: win.cfg.wxIcon
              onFlip: win.cfg.wxIcon = !win.cfg.wxIcon
            }
            Sw {
              label: "Temperature"
              on: win.cfg.wxTemp
              onFlip: win.cfg.wxTemp = !win.cfg.wxTemp
            }
            Sw {
              label: "Condition"
              hint: "Text like \"Cloudy\""
              on: win.cfg.wxCond
              onFlip: win.cfg.wxCond = !win.cfg.wxCond
            }
            Sw {
              label: "Location"
              on: win.cfg.wxLoc
              onFlip: win.cfg.wxLoc = !win.cfg.wxLoc
            }
            Sw {
              label: "Use Fahrenheit"
              hint: "Off shows Celsius"
              on: win.cfg.weatherF
              onFlip: win.cfg.weatherF = !win.cfg.weatherF
            }
            Opt {
              label: "City"
              hint: "Leave empty to detect automatically. Press Enter to apply"

              Field {
                value: win.cfg.weatherCity
                placeholder: "e.g. Singapore"
                onEdited: t => win.cfg.weatherCity = t.trim()
              }
            }
          }

          // Status
          Card {
            visible: panel.sel === "status"

            Sw {
              label: "Wi-Fi"
              on: win.cfg.showWifi
              onFlip: win.cfg.showWifi = !win.cfg.showWifi
            }
            Sw {
              label: "Bluetooth"
              on: win.cfg.showBt
              onFlip: win.cfg.showBt = !win.cfg.showBt
            }
            Sw {
              label: "Volume"
              on: win.cfg.showVolume
              onFlip: win.cfg.showVolume = !win.cfg.showVolume
            }
            Sw {
              label: "Volume percentage"
              visible: win.cfg.showVolume
              on: win.cfg.volPct
              onFlip: win.cfg.volPct = !win.cfg.volPct
            }
            Sw {
              label: "Battery"
              on: win.cfg.showBattery
              onFlip: win.cfg.showBattery = !win.cfg.showBattery
            }
            Sw {
              label: "Battery percentage"
              visible: win.cfg.showBattery
              on: win.cfg.batPct
              onFlip: win.cfg.batPct = !win.cfg.batPct
            }
          }

          // Control Center
          Card {
            visible: panel.sel === "cc"

            Sw {
              label: "Wi-Fi toggle"
              on: win.cfg.ccWifi
              onFlip: win.cfg.ccWifi = !win.cfg.ccWifi
            }
            Sw {
              label: "Bluetooth toggle"
              on: win.cfg.ccBt
              onFlip: win.cfg.ccBt = !win.cfg.ccBt
            }
            Sw {
              label: "Volume slider"
              on: win.cfg.ccVol
              onFlip: win.cfg.ccVol = !win.cfg.ccVol
            }
            Sw {
              label: "Brightness slider"
              on: win.cfg.ccBright
              onFlip: win.cfg.ccBright = !win.cfg.ccBright
            }
            Sw {
              label: "Microphone slider"
              on: win.cfg.ccMic
              onFlip: win.cfg.ccMic = !win.cfg.ccMic
            }
            Sw {
              label: "Per-app volume"
              on: win.cfg.ccApps
              onFlip: win.cfg.ccApps = !win.cfg.ccApps
            }
            Sw {
              label: "Power profiles"
              on: win.cfg.ccPower
              onFlip: win.cfg.ccPower = !win.cfg.ccPower
            }
            Sw {
              label: "Confirm restart and shutdown"
              hint: "Needs a second tap"
              on: win.cfg.ccConfirm
              onFlip: win.cfg.ccConfirm = !win.cfg.ccConfirm
            }
            Sw {
              label: "Compact"
              hint: "Smaller tiles and tighter spacing"
              on: win.cfg.ccCompact
              onFlip: win.cfg.ccCompact = !win.cfg.ccCompact
            }
          }

          // Settings button
          Card {
            visible: panel.sel === "settings"

            Sel {
              label: "On click"
              options: [{ k: "quick", label: "Quick settings" }, { k: "full", label: "Full settings" }]
              value: win.cfg.setClick
              onPicked: k => win.cfg.setClick = k
            }
            Sw {
              label: "Do Not Disturb"
              hint: "Quick settings item"
              on: win.cfg.qkDnd
              onFlip: win.cfg.qkDnd = !win.cfg.qkDnd
            }
            Sw {
              label: "Accent colors"
              hint: "Quick settings item"
              on: win.cfg.qkAccent
              onFlip: win.cfg.qkAccent = !win.cfg.qkAccent
            }
            Sw {
              label: "Screen magnifier"
              hint: "Quick settings item"
              on: win.cfg.qkZoom
              onFlip: win.cfg.qkZoom = !win.cfg.qkZoom
            }
            Sw {
              label: "Wallpaper"
              hint: "Quick settings item"
              on: win.cfg.qkWall
              onFlip: win.cfg.qkWall = !win.cfg.qkWall
            }
          }

          // Clock
          Card {
            visible: panel.sel === "clock"

            Sel {
              label: "Time format"
              options: [{ k: "12", label: "12-hour" }, { k: "24", label: "24-hour" }]
              value: win.cfg.clock24 ? "24" : "12"
              onPicked: k => win.cfg.clock24 = (k === "24")
            }
            Sw {
              label: "Show seconds"
              on: win.cfg.clockSec
              onFlip: win.cfg.clockSec = !win.cfg.clockSec
            }
            Sw {
              label: "Date under the clock"
              on: win.cfg.showDate
              onFlip: win.cfg.showDate = !win.cfg.showDate
            }
          }

          // Wallpaper
          Card {
            visible: panel.sel === "wallpaper"

            Sel {
              label: "Mode"
              options: [{ k: "picker", label: "Picker" }, { k: "slideshow", label: "Slideshow" }]
              value: win.cfg.wpMode
              onPicked: k => win.cfg.wpMode = k
            }
            Num {
              label: "Change every (min)"
              visible: win.cfg.wpMode === "slideshow"
              value: win.cfg.wpInterval; from: 1; to: 120; step: 1
              onMoved: v => win.cfg.wpInterval = v
            }
            Sw {
              label: "Shuffle"
              visible: win.cfg.wpMode === "slideshow"
              on: win.cfg.wpShuffle
              onFlip: win.cfg.wpShuffle = !win.cfg.wpShuffle
            }
            Opt {
              label: "Wallpaper folder"
              hint: "Press Enter to apply"

              Field {
                value: win.cfg.wallDir
                placeholder: "~/Pictures"
                onEdited: t => {
                  win.cfg.wallDir = t
                  win.rescanWalls()
                }
              }
            }
          }

          // Notifications
          Card {
            visible: panel.sel === "notif"

            Sel {
              label: "Bar display"
              options: [{ k: "count", label: "Count" }, { k: "latest", label: "Latest" }, { k: "full", label: "Full preview" }]
              value: win.cfg.ntMode
              onPicked: k => win.cfg.ntMode = k
            }
            Sw {
              label: "Do Not Disturb"
              hint: "Hides toasts, keeps them in the list"
              on: win.cfg.dnd
              onFlip: win.cfg.dnd = !win.cfg.dnd
            }
            Num {
              label: "Toast duration (ms)"
              value: win.cfg.toastMs; from: 2000; to: 15000; step: 1000
              onMoved: v => win.cfg.toastMs = v
            }
            Sw {
              label: "Toasts on the left"
              on: win.cfg.toastLeft
              onFlip: win.cfg.toastLeft = !win.cfg.toastLeft
            }
          }

    Card {
      visible: panel.rk !== ""

      Num {
        label: "Corner radius"
        hint: "Roundness of this widget's pill in the bar"
        value: panel.rk !== "" ? win.cfg[panel.rk] : 0
        from: 0
        to: 32
        step: 2
        onMoved: v => { if (panel.rk !== "") win.cfg[panel.rk] = v }
      }
    }
  }

  Rectangle {
    id: sidebar

    width: 240

    anchors {
      left: parent.left
      top: parent.top
      bottom: parent.bottom
    }

    color: win.side

    Process {
      id: fontP
      command: ["sh", "-c", "fc-list : family | sed 's/,.*//' | sort -u"]

      stdout: StdioCollector {
        onStreamFinished: win.fonts = this.text.split("\n").filter(x => x.trim() !== "")
      }
    }

    Process {
      id: monP
      command: ["hyprctl", "monitors", "-j"]

      stdout: StdioCollector {
        onStreamFinished: {
          try {
            win.mons = JSON.parse(this.text)
          } catch (e) {
            win.mons = []
          }
        }
      }
    }

    Process {
      id: wallP

      command: [
        "sh",
        "-c",
        'd=$(printf %s "$1" | sed "s|^~|$HOME|"); find -L "$d" -maxdepth 2 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \\) | sort | head -60',
        "x",
        win.cfg.wallDir
      ]

      stdout: StdioCollector {
        onStreamFinished: win.walls = this.text.split("\n").filter(x => x.trim() !== "")
      }
    }

    Process {
      id: cpuP

      command: [
        "sh",
        "-c",
        "lscpu | awk -F: '/Model name/ {gsub(/^[ \\t]+/, \"\", $2); print $2; exit}'"
      ]

      stdout: StdioCollector {
        onStreamFinished: win.cpuInfo = this.text.trim() || "not detected"
      }
    }

    Process {
      id: gpuP

      command: [
        "sh",
        "-c",
        "lspci 2>/dev/null | grep -Ei 'vga|3d|display' | sed 's/.*: //' | head -1"
      ]

      stdout: StdioCollector {
        onStreamFinished: win.gpuInfo = this.text.trim() || "not detected"
      }
    }

    Process {
      id: ramP

      command: [
        "sh",
        "-c",
        "free -h | awk '/^Mem:/ {print $3 \" / \" $2; exit}'"
      ]

      stdout: StdioCollector {
        onStreamFinished: win.ramInfo = this.text.trim() || "not detected"
      }
    }

    Process {
      id: diskP

      command: [
        "sh",
        "-c",
        "df -h / | awk 'NR==2 {print $3 \" / \" $2 \" used\"}'"
      ]

      stdout: StdioCollector {
        onStreamFinished: win.diskInfo = this.text.trim() || "not detected"
      }
    }

    Process {
      id: osP

      command: [
        "sh",
        "-c",
        ". /etc/os-release && printf '%s' \"$PRETTY_NAME\""
      ]

      stdout: StdioCollector {
        onStreamFinished: win.osInfo = this.text.trim() || "linux"
      }
    }

    Process {
      id: kernelP
      command: ["uname", "-r"]

      stdout: StdioCollector {
        onStreamFinished: win.kernelInfo = this.text.trim() || "not detected"
      }
    }

    Process {
      id: deP

      command: [
        "sh",
        "-c",
        "printf '%s' \"${XDG_CURRENT_DESKTOP:-${XDG_SESSION_DESKTOP:-unknown}}\""
      ]

      stdout: StdioCollector {
        onStreamFinished: win.deInfo = this.text.trim() || "unknown"
      }
    }

    Process {
      id: wmP

      command: [
        "sh",
        "-c",
        "hyprctl version 2>/dev/null | head -1"
      ]

      stdout: StdioCollector {
        onStreamFinished: win.wmInfo = this.text.trim() || "unknown"
      }
    }

    Process {
      id: qsP

      command: [
        "sh",
        "-c",
        "qs --version 2>/dev/null | head -1"
      ]

      stdout: StdioCollector {
        onStreamFinished: win.qsInfo = this.text.trim() || "Quickshell"
      }
    }

    Process {
      id: hostP

      command: [
        "sh",
        "-c",
        "cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null"
      ]

      stdout: StdioCollector {
        onStreamFinished: win.hostInfo = this.text.trim() || "unknown device"
      }
    }

    Timer {
      id: monTimer
      interval: 800
      onTriggered: monP.running = true
    }

    Timer {
      id: tapTimer
      interval: 2500
      onTriggered: win.taps = 0
    }

    ColorMatch {
      id: cm
      cfg: win.cfg
    }

    ColumnLayout {
      anchors {
        fill: parent
        margins: 10
      }

      spacing: 2

      Lbl {
        text: "Settings"
        font.pixelSize: 18
        font.bold: true
        Layout.margins: 8
      }

      Repeater {
        model: win.nav

        Rectangle {
          id: item

          required property var modelData

          readonly property bool cur: win.page === modelData.k

          Layout.fillWidth: true
          implicitHeight: 42
          radius: win.r

          color: cur ? win.acc : (nm.containsMouse ? "#22ffffff" : "transparent")

          RowLayout {
            anchors {
              fill: parent
              leftMargin: 8
              rightMargin: 8
            }

            spacing: 12

            Rectangle {
              implicitWidth: 30
              implicitHeight: 30
              radius: Math.min(win.r, 15)

              color: item.cur ? "#33000000" : "#14ffffff"

              Ico {
                anchors.centerIn: parent
                name: item.modelData.icon
                font.pixelSize: 17
                color: item.cur ? win.onAcc : win.txt
              }
            }

            Lbl {
              text: item.modelData.label
              font.bold: item.cur
              color: item.cur ? win.onAcc : win.txt
              Layout.fillWidth: true
            }
          }

          MouseArea {
            id: nm
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
      if (win.page === item.modelData.k)
        return

      win.page = item.modelData.k
    }
          }
        }
      }

      Item {
        Layout.fillHeight: true
      }
    }
  }

  Item {
    id: contentArea

    property int pageDirection: 1
    property string previousPage: win.page

    anchors {
      left: sidebar.right
      right: parent.right
      top: parent.top
      bottom: parent.bottom
      margins: 28
    }

    Connections {
      target: win

      function onPageChanged() {
        const oldIndex = win.nav.findIndex(n => n.k === contentArea.previousPage)
        const newIndex = win.nav.findIndex(n => n.k === win.page)

        contentArea.pageDirection = newIndex >= oldIndex ? 1 : -1
        contentArea.previousPage = win.page

        pageAnim.restart()
      }
    }

    ParallelAnimation {
      id: pageAnim

      NumberAnimation {
        target: pg
        property: "x"
        from: contentArea.pageDirection * 22
        to: 0
        duration: 260
        easing.type: Easing.OutCubic
      }

      NumberAnimation {
        target: pg
        property: "opacity"
        from: 0.0
        to: 1.0
        duration: 220
        easing.type: Easing.OutCubic
      }
    }

    Lbl {
      id: title

      visible: win.page !== "welcome"
      height: visible ? implicitHeight : 0

      text: {
        const e = win.nav.find(n => n.k === win.page)
        return e ? e.label : ""
      }

      font.pixelSize: 26
      font.bold: true
    }

    Flickable {
      id: fl

      anchors {
        left: parent.left
        right: parent.right
        top: title.bottom
        topMargin: win.page !== "welcome" ? 16 : 0
        bottom: parent.bottom
      }

      contentWidth: width
      contentHeight: pg.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      ColumnLayout {
        id: pg

        width: fl.width
        spacing: 14

        ColumnLayout {
          visible: win.page === "welcome"
          Layout.fillWidth: true
          spacing: 16

          Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 170
            clip: true

            Rectangle {
              anchors.fill: parent
              radius: win.r
              color: win.card

              Image {
                anchors.fill: parent
                source: win.cfg.wallpaper
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
              }

              Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                  GradientStop { position: 0.0; color: "#55000000" }
                  GradientStop { position: 0.45; color: "#99000000" }
                  GradientStop { position: 1.0; color: "#ee000000" }
                }
              }

              Column {
                anchors {
                  left: parent.left
                  bottom: parent.bottom
                  leftMargin: 22
                  bottomMargin: 20
                }

                spacing: 3

                Lbl {
                  id: welcomeIdentity
                  text: Quickshell.env("USER") + "@thinkpad"
                  color: "#ffffff"
                  font.pixelSize: 22
                  font.bold: true

                  Process {
                    id: welcomeHostnameProcess
                    command: ["sh", "-c", "cat /etc/hostname 2>/dev/null || uname -n"]

                    stdout: StdioCollector {
                      onStreamFinished: welcomeIdentity.text =
                        Quickshell.env("USER") + "@" + this.text.trim()
                    }
                  }

                  Component.onCompleted: welcomeHostnameProcess.running = true
                }

                Lbl {
                  id: welcomeUptime
                  text: "uptime unavailable"
                  color: "#d9ffffff"
                  font.pixelSize: 13

                  Process {
                    id: welcomeUptimeProcess
                    command: ["sh", "-c", "uptime -p"]

                    stdout: StdioCollector {
                      onStreamFinished: welcomeUptime.text = this.text.trim()
                    }
                  }

                  Component.onCompleted: welcomeUptimeProcess.running = true
                }
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 50
            radius: win.r
            color: win.card

            RowLayout {
              anchors {
                fill: parent
                leftMargin: 14
                rightMargin: 10
              }

              spacing: 10

              Ico {
                name: "search"
                color: win.dim
              }

              TextInput {
                id: sq

                Layout.fillWidth: true
                Layout.fillHeight: true

                verticalAlignment: TextInput.AlignVCenter
                color: win.txt
                font.family: win.ff
                font.pixelSize: 15
                clip: true
                selectByMouse: true

                onTextChanged: win.q = text

                Lbl {
                  visible: sq.text === ""
                  text: "Search settings"
                  color: win.dim
                  font.pixelSize: 15
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              RBtn {
                visible: sq.text !== ""
                icon: "close"
                onClicked: sq.text = ""
              }
            }
          }

          Lbl {
            text: win.q.trim() === "" ? "Most used" : "Results"
            font.pixelSize: 18
            font.bold: true
          }

          GridLayout {
            Layout.fillWidth: true

            columns: 3
            columnSpacing: 14
            rowSpacing: 14

            Repeater {
              model: win.filtered

              Rectangle {
                required property var modelData

                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 104
                radius: win.r

                color: tm.containsMouse ? Qt.lighter(win.card, 1.2) : win.card

                ColumnLayout {
                  anchors {
                    fill: parent
                    margins: 14
                  }

                  spacing: 4

                  RowLayout {
                    spacing: 8

                    Rectangle {
                      implicitWidth: 34
                      implicitHeight: 34
                      radius: 17
                      color: Qt.alpha(win.acc, 0.2)

                      Ico {
                        anchors.centerIn: parent
                        name: modelData.icon
                        color: win.acc
                      }
                    }

                    Item {
                      Layout.fillWidth: true
                    }

                  }

                  Lbl {
                    text: modelData.label
                    font.bold: true
                  }

                  Lbl {
                    text: modelData.desc
                    font.pixelSize: 12
                    color: win.dim
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }
                }

                MouseArea {
                  id: tm
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: win.page = modelData.page
                }
              }
            }
          }

          Lbl {
            visible: win.filtered.length === 0
            text: "No matching settings"
            color: win.dim
          }
        }

        GridLayout {
          visible: win.page === "theme"
          Layout.fillWidth: true

          columns: 2
          columnSpacing: 14
          rowSpacing: 14

          Repeater {
            model: win.styles

            Rectangle {
              required property var modelData

              readonly property bool cur: win.cfg.accent === modelData.a && win.cfg.bg === modelData.b

              Layout.fillWidth: true
              Layout.preferredWidth: 1
              implicitHeight: 112
              radius: win.r
              color: win.card

              border.width: cur ? 2 : 0
              border.color: win.acc

              Lbl {
                text: modelData.n
                font.bold: true

                anchors {
                  left: parent.left
                  top: parent.top
                  margins: 14
                }
              }

              Rectangle {
                anchors {
                  left: parent.left
                  right: parent.right
                  bottom: parent.bottom
                  margins: 12
                }

                height: 34
                radius: Math.min(modelData.rad, 12)
                color: Qt.alpha(modelData.b, 1)

                Row {
                  anchors {
                    left: parent.left
                    leftMargin: 8
                    verticalCenter: parent.verticalCenter
                  }

                  spacing: 6

                  Rectangle {
                    width: 40
                    height: 18
                    radius: Math.min(modelData.rad, 9)
                    color: modelData.p
                  }

                  Rectangle {
                    width: 22
                    height: 8
                    radius: 4
                    color: modelData.a
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }
              }

              MouseArea {
                anchors.fill: parent
                onClicked: win.apply(modelData)
              }
            }
          }
        }

        ColumnLayout {
          visible: win.page === "theme"
          Layout.fillWidth: true
          spacing: 14

          Card {
            Opt {
              label: "Accent presets"

              Repeater {
                model: win.accents

                Rectangle {
                  required property string modelData

                  implicitWidth: 24
                  implicitHeight: 24
                  radius: 12
                  color: modelData

                  border.width: win.cfg.accent === modelData ? 2 : 0
                  border.color: "#fff"

                  MouseArea {
                    anchors.fill: parent
                    onClicked: win.cfg.accent = modelData
                  }
                }
              }
            }

            Opt {
              label: "Accent"
              hint: "Applies as you type"

              Rectangle {
                implicitWidth: 26
                implicitHeight: 26
                radius: 13
                color: win.cfg.accent
                border.width: 1
                border.color: "#55ffffff"
              }

              Field {
                value: win.cfg.accent
                placeholder: "#rrggbb"
                onTyped: t => win.setHex("accent", t)
              }
            }

            Opt {
              label: "Background"

              Rectangle {
                implicitWidth: 26
                implicitHeight: 26
                radius: 13
                color: win.cfg.bg
                border.width: 1
                border.color: "#55ffffff"
              }

              Field {
                value: win.cfg.bg
                placeholder: "#rrggbb"
                onTyped: t => win.setHex("bg", t)
              }
            }

            Opt {
              label: "Pills and cards"

              Rectangle {
                implicitWidth: 26
                implicitHeight: 26
                radius: 13
                color: win.cfg.pill
                border.width: 1
                border.color: "#55ffffff"
              }

              Field {
                value: win.cfg.pill
                placeholder: "#rrggbb"
                onTyped: t => win.setHex("pill", t)
              }
            }
          }

          Card {
            Opt {
              label: "Wallpaper"
              hint: "Pick an image from the folder below"

              RBtn {
                icon: "refresh"
                onClicked: wallP.running = true
              }
            }

            Field {
              Layout.fillWidth: true
              value: win.cfg.wallDir
              placeholder: "~/Pictures"

              onEdited: t => {
                win.cfg.wallDir = t
                wallP.running = true
              }
            }

            GridLayout {
              Layout.fillWidth: true

              columns: 4
              columnSpacing: 10
              rowSpacing: 10

              Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 84
                radius: 10
                color: win.base

                border.width: win.cfg.wallpaper === "" ? 2 : 0
                border.color: win.acc

                Ico {
                  anchors.centerIn: parent
                  name: "hide_image"
                  color: win.dim
                }

                MouseArea {
                  anchors.fill: parent
                  onClicked: win.cfg.wallpaper = ""
                }
              }

              Repeater {
                model: win.walls

                Rectangle {
                  required property string modelData

                  Layout.fillWidth: true
                  Layout.preferredWidth: 1
                  implicitHeight: 84
                  radius: 10
                  color: win.base
                  clip: true

                  Image {
                    anchors.fill: parent
                    source: "file://" + modelData
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 260
                  }

                  Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: "transparent"

                    border.width: win.cfg.wallpaper === modelData ? 3 : 0
                    border.color: win.acc
                  }

                  MouseArea {
                    anchors.fill: parent
                    onClicked: win.cfg.wallpaper = modelData
                  }
                }
              }
            }

            Lbl {
              visible: win.walls.length === 0
              text: "No images found in that folder"
              color: win.dim
              font.pixelSize: 12
            }

            TBtn {
              visible: win.cfg.wallpaper !== ""
              label: "Match colors to wallpaper"
              icon: "colorize"
              onClicked: cm.run()
            }
          }

          Card {
            Opt {
              label: "Font size"

              Step {
                value: win.cfg.fontSize
                from: 10
                to: 18
                step: 1
                onMoved: v => win.cfg.fontSize = v
              }
            }

            Opt {
              label: "Font"
              hint: win.cfg.fontFamily
            }

            Field {
              Layout.fillWidth: true
              placeholder: "Search fonts"
              onTyped: t => win.fq = t
            }

            ListView {
              Layout.fillWidth: true
              Layout.preferredHeight: 190
              clip: true
              model: win.fontsShown
              boundsBehavior: Flickable.StopAtBounds

              delegate: Rectangle {
                required property string modelData

                width: ListView.view.width
                height: 34
                radius: 8

                color: win.cfg.fontFamily === modelData
                  ? win.acc
                  : (fm.containsMouse ? "#22ffffff" : "transparent")

                Text {
                  anchors {
                    left: parent.left
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                  }

                  text: modelData
                  font.family: modelData
                  font.pixelSize: 15
                  color: win.cfg.fontFamily === modelData ? win.onAcc : win.txt
                }

                MouseArea {
                  id: fm
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: win.cfg.fontFamily = modelData
                }
              }
            }
          }
        }

        ColumnLayout {
          visible: win.page === "display"
          Layout.fillWidth: true
          spacing: 14

          Repeater {
            model: win.mons

            Card {
              required property var modelData

              Lbl {
                text: modelData.name + "   " + modelData.width + "x" + modelData.height + " @ " + Math.round(modelData.refreshRate) + "Hz"
                font.bold: true
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Lbl {
                  text: "Scale (zoom)"
                  font.bold: true
                  Layout.fillWidth: true
                }

                Lbl {
                  text: "Recommended: " + win.recScale(modelData) + "x"
                  font.pixelSize: 12
                  color: win.dim
                  Layout.fillWidth: true
                }


                Rectangle {
                  id: scaleSlider

                  Layout.fillWidth: true
                  Layout.preferredHeight: 64
                  color: "transparent"

                  property real pendingValue: modelData.scale

                  Rectangle {
                    id: valueBubble

                    width: 30
                    height: 30
                    radius: 15

                    x:
                      thumb.x +
                      (thumb.width - width) / 2

                    y:
                      track.y -
                      height -
                      6

                    color: win.acc

                    Lbl {
                      anchors.centerIn: parent
                      text: scaleSlider.pendingValue.toFixed(2) + "×"
                      color: win.onAcc
                      font.pixelSize: 11
                      font.bold: true
                    }
                  }

                  Rectangle {
                    id: track

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 22
                    anchors.rightMargin: 22

                    height: 12
                    radius: 6
                    color: win.base

                    Rectangle {
                      width:
                        ((scaleSlider.pendingValue - 0.5) / 2.5) *
                        parent.width

                      height: parent.height
                      radius: 6
                      color: win.acc
                    }
                  }

                  Rectangle {
                    id: thumb

                    width: 24
                    height: 24
                    radius: 12

                    x:
                      track.x +
                      ((scaleSlider.pendingValue - 0.5) / 2.5) *
                      (track.width - width)

                    y:
                      track.y +
                      (track.height - height) / 2

                    color: win.acc
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    function updateValue(x) {
                      var ratio = Math.max(
                        0,
                        Math.min(
                          1,
                          (x - track.x) / track.width
                        )
                      )

                      scaleSlider.pendingValue =
                        Math.round((0.5 + ratio * 2.5) * 50) / 50
                    }

                    onPressed: mouse => updateValue(mouse.x)

                    onPositionChanged: mouse => {
                      if (pressed)
                        updateValue(mouse.x)
                    }

                    onReleased: {
                      win.setMon(
                        modelData,
                        modelData.width,
                        modelData.height,
                        modelData.refreshRate,
                        scaleSlider.pendingValue
                      )
                    }
                  }
                }
              }

              Lbl {
                text: "Resolution"
              }

              GridLayout {
                Layout.fillWidth: true

                columns: 4
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                  model: win.modes(modelData)

                  Rectangle {
                    required property var modelData

                    readonly property bool cur:
                      modelData.w === win.mons[0].width &&
                      modelData.h === win.mons[0].height

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: 38
                    radius: 10

                    color: cur ? win.acc : win.base

                    Lbl {
                      anchors.centerIn: parent
                      text: modelData.w + "x" + modelData.h
                      font.pixelSize: 12
                      color: parent.cur ? win.onAcc : win.txt
                    }

                    MouseArea {
                      anchors.fill: parent

                      onClicked: win.setMon(
                        win.mons[0],
                        modelData.w,
                        modelData.h,
                        modelData.hz,
                        win.mons[0].scale
                      )
                    }
                  }
                }
              }
            }
          }

          Lbl {
            visible: win.mons.length === 0
            text: "No monitors found (needs Hyprland and hyprctl)"
            color: win.dim
          }

          Card {
            Opt {
              label: "Screen magnifier"
              hint: "Zooms the whole screen around the cursor"

              Step {
                value: win.zoom
                from: 1
                to: 4
                step: 0.25
                dec: 2
                onMoved: v => win.setZoom(v)
              }
            }

            Lbl {
              text: "Display changes last until Hyprland reloads. Put them in your monitor config to keep them."
              color: win.dim
              font.pixelSize: 12
              wrapMode: Text.WordWrap
              Layout.fillWidth: true
            }
          }
        }

        ColumnLayout {
          visible: win.page === "bar"
          Layout.fillWidth: true
          spacing: 14

          Card {
            Lbl {
              text: "Appearance"
              font.bold: true
            }

            Sw {
              label: "Capsule around every widget"
              hint: "Gives each widget its own rounded background. Use a widget's Corner radius to make it fully round"
              on: win.cfg.capsules
              onFlip: win.cfg.capsules = !win.cfg.capsules
            }

            Opt {
              label: "Opacity"

              Step {
                value: win.cfg.alpha
                from: 0.3
                to: 1
                step: 0.05
                dec: 2
                onMoved: v => win.cfg.alpha = Math.round(v * 100) / 100
              }
            }

            Opt {
              label: "Height"

              Step {
                value: win.cfg.barHeight
                from: 40
                to: 64
                step: 2
                onMoved: v => win.cfg.barHeight = v
              }
            }

            Opt {
              label: "Roundness"

              Step {
                value: win.cfg.pillRadius
                from: 4
                to: 16
                step: 2
                onMoved: v => win.cfg.pillRadius = v
              }
            }

            Opt {
              label: "Floating margin"
              hint: "0 keeps the bar attached to the edge"

              Step {
                value: win.cfg.barMargin
                from: 0
                to: 16
                step: 2
                onMoved: v => win.cfg.barMargin = v
              }
            }

            Opt {
              label: "Bar on top"
              hint: "Off puts it at the bottom"

              Toggle {
                on: win.cfg.barTop
                onFlip: win.cfg.barTop = !win.cfg.barTop
              }
            }
          }

          Card {
            Lbl {
              text: "Widgets"
              font.bold: true
            }

            Opt {
              label: "Weather"
              Toggle {
                on: win.cfg.showWeather
                onFlip: win.cfg.showWeather = !win.cfg.showWeather
              }
            }

            Opt {
              label: "Media player"
              Toggle {
                on: win.cfg.showMedia
                onFlip: win.cfg.showMedia = !win.cfg.showMedia
              }
            }

            Opt {
              label: "System tray"
              Toggle {
                on: win.cfg.showTray
                onFlip: win.cfg.showTray = !win.cfg.showTray
              }
            }

            Opt {
              label: "CPU and RAM"
              Toggle {
                on: win.cfg.showVitals
                onFlip: win.cfg.showVitals = !win.cfg.showVitals
              }
            }

            Opt {
              label: "Wi-Fi"
              Toggle {
                on: win.cfg.showWifi
                onFlip: win.cfg.showWifi = !win.cfg.showWifi
              }
            }

            Opt {
              label: "Bluetooth"
              Toggle {
                on: win.cfg.showBt
                onFlip: win.cfg.showBt = !win.cfg.showBt
              }
            }

            Opt {
              label: "Volume"
              Toggle {
                on: win.cfg.showVolume
                onFlip: win.cfg.showVolume = !win.cfg.showVolume
              }
            }

            Opt {
              label: "Battery"
              Toggle {
                on: win.cfg.showBattery
                onFlip: win.cfg.showBattery = !win.cfg.showBattery
              }
            }

            Opt {
              label: "Date under the clock"
              Toggle {
                on: win.cfg.showDate
                onFlip: win.cfg.showDate = !win.cfg.showDate
              }
            }

            Opt {
              label: "24-hour clock"
              Toggle {
                on: win.cfg.clock24
                onFlip: win.cfg.clock24 = !win.cfg.clock24
              }
            }
          }
        }

        LayoutEditor {
          visible: win.page === "layout"
          Layout.fillWidth: true
          host: win
        }

        ColumnLayout {
          visible: win.page === "widgets"
          Layout.fillWidth: true
          spacing: 14

          Flow {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
              model: win.wlist

              Rectangle {
                id: chip

                required property var modelData
                readonly property bool cur: win.wsel === modelData.k

                implicitWidth: chipRow.implicitWidth + 24
                implicitHeight: 38
                radius: win.r

                color: cur ? win.acc : (cm2.containsMouse ? "#33ffffff" : win.card)

                Row {
                  id: chipRow
                  anchors.centerIn: parent
                  spacing: 6

                  Ico {
                    name: chip.modelData.icon
                    font.pixelSize: 17
                    color: chip.cur ? win.onAcc : win.txt
                  }

                  Lbl {
                    text: chip.modelData.label
                    font.pixelSize: 13
                    color: chip.cur ? win.onAcc : win.txt
                  }
                }

                MouseArea {
                  id: cm2
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: win.wsel = chip.modelData.k
                }
              }
            }
          }

          WidgetPanel {
            Layout.fillWidth: true
            sel: win.wsel
          }
        }

        ColumnLayout {
          visible: win.page === "dock"
          Layout.fillWidth: true
          spacing: 14

          Card {
            Opt {
              label: "Show running apps"
              hint: "The app pills in the middle of the bar"

              Toggle {
                on: win.cfg.showDock
                onFlip: win.cfg.showDock = !win.cfg.showDock
              }
            }

            Opt {
              label: "Icon size"

              Step {
                value: win.cfg.dockIcon
                from: 16
                to: 34
                step: 2
                onMoved: v => win.cfg.dockIcon = v
              }
            }
          }
        }

        ColumnLayout {
          visible: win.page === "audio"
          Layout.fillWidth: true
          spacing: 14

          Card {
            Lbl {
              text: "Equalizer"
              font.bold: true
            }

            Opt {
              label: "Equalizer enabled"
              hint: "Off bypasses all bands"

              Toggle {
                on: win.cfg.eqOn
                onFlip: win.cfg.eqOn = !win.cfg.eqOn
              }
            }

            TBtn {
              label: "Open equalizer"
              icon: "equalizer"
              onClicked: Quickshell.execDetached([
                "qs",
                "ipc",
                "call",
                "media",
                "toggle"
              ])
            }
          }

          Card {
            Lbl {
              text: "On-screen display"
              font.bold: true
            }

            Opt {
              label: "Volume popup"

              Toggle {
                on: win.cfg.osdOn
                onFlip: win.cfg.osdOn = !win.cfg.osdOn
              }
            }

            Opt {
              label: "Duration (ms)"

              Step {
                value: win.cfg.osdMs
                from: 600
                to: 4000
                step: 200
                onMoved: v => win.cfg.osdMs = v
              }
            }
          }
        }

        ColumnLayout {
          visible: win.page === "cc"
          Layout.fillWidth: true
          spacing: 14

          Card {
            Opt {
              label: "Power profiles"
              Toggle {
                on: win.cfg.ccPower
                onFlip: win.cfg.ccPower = !win.cfg.ccPower
              }
            }

            Opt {
              label: "Microphone slider"
              Toggle {
                on: win.cfg.ccMic
                onFlip: win.cfg.ccMic = !win.cfg.ccMic
              }
            }

            Opt {
              label: "Per-app volume"
              Toggle {
                on: win.cfg.ccApps
                onFlip: win.cfg.ccApps = !win.cfg.ccApps
              }
            }

            Opt {
              label: "Confirm restart and shutdown"
              hint: "Needs a second tap"

              Toggle {
                on: win.cfg.ccConfirm
                onFlip: win.cfg.ccConfirm = !win.cfg.ccConfirm
              }
            }
          }
        }

        ColumnLayout {
          visible: win.page === "notif"
          Layout.fillWidth: true
          spacing: 14

          Card {
            Opt {
              label: "Do Not Disturb"
              hint: "Hides toasts, keeps them in the list"

              Toggle {
                on: win.cfg.dnd
                onFlip: win.cfg.dnd = !win.cfg.dnd
              }
            }

            Opt {
              label: "Toast duration (ms)"

              Step {
                value: win.cfg.toastMs
                from: 2000
                to: 15000
                step: 1000
                onMoved: v => win.cfg.toastMs = v
              }
            }

            Opt {
              label: "Toasts on the left"

              Toggle {
                on: win.cfg.toastLeft
                onFlip: win.cfg.toastLeft = !win.cfg.toastLeft
              }
            }
          }
        }

        ColumnLayout {
          visible: win.page === "launcher"
          Layout.fillWidth: true
          spacing: 14

          Card {
            Opt {
              label: "Width"

              Step {
                value: win.cfg.lauWidth
                from: 480
                to: 900
                step: 40
                onMoved: v => win.cfg.lauWidth = v
              }
            }

            Opt {
              label: "Max app results"

              Step {
                value: win.cfg.lauMax
                from: 20
                to: 100
                step: 10
                onMoved: v => win.cfg.lauMax = v
              }
            }

            Lbl {
              text: "Type = for calculator, : for emoji, > for clipboard, wall for wallpapers."
              color: win.dim
              font.pixelSize: 12
              wrapMode: Text.WordWrap
              Layout.fillWidth: true
            }

            TBtn {
              label: "Open launcher"
              icon: "rocket_launch"

              onClicked: Quickshell.execDetached([
                "qs",
                "ipc",
                "call",
                "launcher",
                "toggle"
              ])
            }
          }
        }

        ColumnLayout {
          visible: win.page === "general"
          Layout.fillWidth: true
          spacing: 14

          Card {
            Opt {
              label: "Font"
              hint: "Press Enter to apply"

              Field {
                value: win.cfg.fontFamily
                onEdited: t => {
                  if (t !== "")
                    win.cfg.fontFamily = t
                }
              }
            }

            Opt {
              label: "Icon font"
              hint: "Needs a Material Symbols font"

              Field {
                value: win.cfg.iconFont

                onEdited: t => {
                  if (t !== "")
                    win.cfg.iconFont = t
                }
              }
            }
          }
        }

        ColumnLayout {
          visible: win.page === "about"
          Layout.fillWidth: true
          spacing: 14

          RowLayout {
    Layout.alignment: Qt.AlignHCenter

    Image {
      source: Qt.resolvedUrl("image.png")
      sourceSize.width: 500
      sourceSize.height: 150
      fillMode: Image.PreserveAspectFit
      Layout.preferredWidth: 500
      Layout.preferredHeight: 150
    }
  }

          GridLayout {
            Layout.fillWidth: true

            columns: 2
            columnSpacing: 14
            rowSpacing: 14

            Card {
              Lbl {
                text: "cpu"
                font.bold: true
                font.pixelSize: 15
              }

              Lbl {
                text: win.cpuInfo
                color: win.dim
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
              }
            }

            Card {
              Lbl {
                text: "gpu"
                font.bold: true
                font.pixelSize: 15
              }

              Lbl {
                text: win.gpuInfo
                color: win.dim
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
              }
            }

            Card {
              Lbl {
                text: "ram"
                font.bold: true
                font.pixelSize: 15
              }

              Lbl {
                text: win.ramInfo
                color: win.dim
                font.pixelSize: 12
              }
            }

            Card {
              Lbl {
                text: "storage"
                font.bold: true
                font.pixelSize: 15
              }

              Lbl {
                text: win.diskInfo
                color: win.dim
                font.pixelSize: 12
              }
            }

            Card {
              Lbl {
                text: "os"
                font.bold: true
                font.pixelSize: 15
              }

              Lbl {
                text: win.osInfo
                color: win.dim
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
              }
            }

            Card {
              Lbl {
                text: "kernel"
                font.bold: true
                font.pixelSize: 15
              }

              Lbl {
                text: win.kernelInfo
                color: win.dim
                font.pixelSize: 12
              }
            }

            Card {
              Lbl {
                text: "desktop"
                font.bold: true
                font.pixelSize: 15
              }

              Lbl {
                text: win.deInfo
                color: win.dim
                font.pixelSize: 12
              }
            }

            Card {
              Lbl {
                text: "display"
                font.bold: true
                font.pixelSize: 15
              }

              Lbl {
                text: win.mons.length > 0
                  ? win.mons[0].width + "x" + win.mons[0].height + " @ " + Math.round(win.mons[0].refreshRate) + "hz"
                  : "not detected"

                color: win.dim
                font.pixelSize: 12
              }
            }

            Card {
              Lbl {
                text: "device"
                font.bold: true
                font.pixelSize: 15
              }

              Lbl {
                text: win.hostInfo
                color: win.dim
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
              }
            }

            Card {
              Lbl {
                text: "quickshell"
                font.bold: true
                font.pixelSize: 15
              }

              Lbl {
                text: win.qsInfo
                color: win.dim
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
              }
            }
          }

          Item {
            Layout.fillHeight: true
          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 58
            radius: 14

            color: vm.containsMouse ? "#14ffffff" : "transparent"

            ColumnLayout {
              anchors.centerIn: parent
              spacing: 2

              Lbl {
                Layout.alignment: Qt.AlignHCenter
                text: win.version
                font.pixelSize: 14
                font.bold: true
              }

              Lbl {
                Layout.alignment: Qt.AlignHCenter

                text: win.cfg.devMode
                  ? "developer mode enabled"
                  : "tap 7 times to enable developer mode"

                color: win.dim
                font.pixelSize: 10
              }
            }

            MouseArea {
              id: vm

              anchors.fill: parent
              hoverEnabled: true

              onClicked: {
                win.taps++
                tapTimer.restart()

                if (win.taps >= 7 && !win.cfg.devMode) {
                  win.cfg.devMode = true
                  win.taps = 0
                }
              }
            }
          }
        }

        ColumnLayout {
          visible: win.page === "dev" && win.cfg.devMode
          Layout.fillWidth: true
          spacing: 14

          Card {
            Opt {
              label: "Bar debug outline"
              hint: "Draws a red border around the bar"

              Toggle {
                on: win.cfg.devOutline
                onFlip: win.cfg.devOutline = !win.cfg.devOutline
              }
            }

            Opt {
              label: "Version"

              Lbl {
                text: win.version
                color: win.dim
              }
            }

            Opt {
              label: "Config folder"
              hint: "~/.config/quickshell"
            }
          }

          GridLayout {
            Layout.fillWidth: true

            columns: 2
            columnSpacing: 10
            rowSpacing: 10

            TBtn {
              label: "Reload shell"
              icon: "refresh"
              onClicked: Quickshell.reload(true)
            }

            TBtn {
              label: "Open config folder"
              icon: "folder_open"

              onClicked: Quickshell.execDetached([
                "xdg-open",
                Quickshell.env("HOME") + "/.config/quickshell"
              ])
            }

            TBtn {
              label: "Reset all settings"
              icon: "restart_alt"
              onClicked: win.resetAll()
            }

            TBtn {
              label: "Disable developer mode"
              icon: "lock"

              onClicked: {
                win.cfg.devMode = false
                win.cfg.devOutline = false
                win.page = "about"
              }
            }
          }
        }
      }
    }
  }

  Rectangle {
    id: popout
    anchors.fill: parent
    z: 1000
    visible: win.popId !== ""
    color: "#99000000"

    MouseArea {
      anchors.fill: parent
      onClicked: win.popId = ""
    }

    Rectangle {
      id: dlg
      anchors.centerIn: parent
      width: Math.min(500, parent.width - 48)
      height: Math.min(parent.height - 64, pnl.implicitHeight + 92)
      radius: win.r + 4
      color: win.base
      border.width: 1
      border.color: "#33ffffff"

      MouseArea { anchors.fill: parent }   // swallow clicks inside the dialog

      RowLayout {
        id: dlgHead
        anchors {
          left: parent.left
          right: parent.right
          top: parent.top
          margins: 16
        }
        spacing: 10

        Ico {
          name: win.popInfo.icon
          color: win.acc
        }

        Lbl {
          text: win.popInfo.label
          font.pixelSize: 18
          font.bold: true
          Layout.fillWidth: true
        }

        RBtn {
          icon: "close"
          onClicked: win.popId = ""
        }
      }

      Flickable {
        id: dlgFlick
        anchors {
          left: parent.left
          right: parent.right
          top: dlgHead.bottom
          bottom: parent.bottom
          margins: 16
          topMargin: 12
        }
        contentWidth: width
        contentHeight: pnl.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        WidgetPanel {
          id: pnl
          sel: win.popId
          width: dlgFlick.width
        }
      }
    }
  }
}
