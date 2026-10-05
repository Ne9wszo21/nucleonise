import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Scope {
  id: ln
  required property var cfg
  property bool shown: false
  property string query: ""
  property int sel: 0
  property var emojis: []
  property var clips: []
  property var walls: []
  property string calcOut: ""
  signal dismissed

  readonly property color base: cfg.bg
  readonly property color card: cfg.pill
  readonly property color acc: cfg.accent
  readonly property color txt: "#e6e6e6"
  readonly property color dim: "#99e6e6e6"
  readonly property string ff: cfg.fontFamily
  readonly property string ifont: cfg.iconFont
  readonly property int r: Math.min(cfg.launcherRadius + 8, 24)

  readonly property string mode: query.startsWith("=") ? "calc" : query.startsWith(":") ? "emoji" : query.startsWith(">") ? "clip" : /^wall(\s|$)/i.test(query) ? "wall" : "apps"
  readonly property string arg: mode === "apps" ? query.trim() : mode === "wall" ? query.slice(4).trim() : query.slice(1).trim()

  onModeChanged: {
    if (mode === "emoji" && emojis.length === 0) emojiP.running = true
    else if (mode === "clip") clipP.running = true
    else if (mode === "wall") wallP.running = true
  }
  onArgChanged: if (mode === "calc") calcTimer.restart()

  readonly property var results: {
    const s = arg.toLowerCase()
    if (mode === "calc") {
      return calcOut !== ""
        ? [{ t: calcOut, s: "Enter to copy", g: "calculate", act: "copy", v: calcOut }]
        : [{ t: "Type an expression", s: "e.g. = 15% of 80   or   = 5 usd to eur", g: "calculate", act: "none" }]
    }
    if (mode === "emoji") return emojis.filter(e => s === "" || e.n.includes(s)).slice(0, 80).map(e => ({ t: e.n, s: "Enter to copy", e: e.c, act: "copy", v: e.c }))
    if (mode === "clip") return clips.filter(c => s === "" || c.p.toLowerCase().includes(s)).slice(0, 50).map(c => ({ t: c.p, s: "Enter to copy", g: "content_paste", act: "clip", v: c.id }))
    if (mode === "wall") return walls.filter(w => s === "" || w.toLowerCase().includes(s)).slice(0, 50).map(w => ({ t: w.split("/").pop(), s: w, img: w, act: "wall", v: w }))
    const rank = a => a.name.toLowerCase().startsWith(s) ? 0 : 1
    return DesktopEntries.applications.values
      .filter(a => !a.noDisplay && (s === "" || (a.name + " " + a.genericName + " " + a.keywords.join(" ")).toLowerCase().includes(s)))
      .sort((x, y) => (rank(x) - rank(y)) || x.name.localeCompare(y.name))
      .slice(0, 60)
      .map(a => ({ t: a.name, s: a.genericName || a.comment, entry: a, act: "app" }))
  }

  function activate(i) {
    const r = results[i]
    if (!r || r.act === "none") return
    if (r.act === "app") r.entry.execute()
    else if (r.act === "copy") Quickshell.execDetached(["wl-copy", "--", r.v])
    else if (r.act === "clip") Quickshell.execDetached(["sh", "-c", "cliphist decode " + r.v + " | wl-copy"])
    else if (r.act === "wall") cfg.wallpaper = r.v
    dismissed()
  }

  Process {
    id: emojiP
    command: ["sh", "-c", "grep fully-qualified /usr/share/unicode/emoji/emoji-test.txt | sed 's/.*# \\(\\S*\\) E[0-9.]* /\\1\\t/'"]
    stdout: StdioCollector {
      onStreamFinished: ln.emojis = this.text.split("\n").filter(l => l.includes("\t")).map(l => { const p = l.split("\t"); return { c: p[0], n: p[1].toLowerCase() } })
    }
  }
  Process {
    id: clipP
    command: ["sh", "-c", "cliphist list 2>/dev/null | head -80"]
    stdout: StdioCollector {
      onStreamFinished: ln.clips = this.text.split("\n").filter(l => l.includes("\t")).map(l => { const i = l.indexOf("\t"); return { id: l.slice(0, i), p: l.slice(i + 1) } })
    }
  }
  Process {
    id: wallP
    command: ["sh", "-c", 'd=$(printf %s "$1" | sed "s|^~|$HOME|"); find -L "$d" -maxdepth 2 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \\) | sort | head -60', "x", ln.cfg.wallDir]
    stdout: StdioCollector { onStreamFinished: ln.walls = this.text.split("\n").filter(x => x.trim() !== "") }
  }
  Process {
    id: calcP
    command: ["qalc", "-t", ln.arg]
    stdout: StdioCollector { onStreamFinished: ln.calcOut = this.text.trim() }
  }
  Timer { id: calcTimer; interval: 250; onTriggered: { if (ln.arg === "") ln.calcOut = ""; else calcP.running = true } }

  PanelWindow {
    id: win
    visible: ln.shown
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ln.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "#88000000"
    onVisibleChanged: if (visible) { sq.text = ""; ln.sel = 0; sq.forceActiveFocus() }

    MouseArea { anchors.fill: parent; onClicked: ln.dismissed() }

    Rectangle {
      id: launcherCard
      width: Math.min(680, parent.width - 40)
      height: Math.min(520, parent.height - 80)
      anchors.horizontalCenter: parent.horizontalCenter
      y: parent.height * 0.14
      radius: ln.r
      opacity: ln.shown ? 1 : 0
      scale: ln.shown ? 1 : 0.96

      Behavior on opacity {
        NumberAnimation {
          duration: 220
          easing.type: Easing.OutCubic
        }
      }

      Behavior on scale {
        NumberAnimation {
          duration: 260
          easing.type: Easing.OutBack
          easing.overshoot: 1.02
        }
      }
      color: Qt.alpha(ln.base, 0.97)
      border.width: 1
      border.color: "#33ffffff"

      MouseArea { anchors.fill: parent }

      ColumnLayout {
        anchors { fill: parent; margins: 16 }
        spacing: 12

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 52; radius: ln.r - 4; color: ln.card
          RowLayout {
            anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
            spacing: 10
            Text {
              text: ln.mode === "calc" ? "calculate" : ln.mode === "emoji" ? "mood" : ln.mode === "clip" ? "content_paste" : ln.mode === "wall" ? "wallpaper" : "search"
              color: ln.acc; font.family: ln.ifont; font.pixelSize: 22
            }
            TextInput {
              id: sq
              Layout.fillWidth: true; Layout.fillHeight: true
              verticalAlignment: TextInput.AlignVCenter
              color: ln.txt; font.family: ln.ff; font.pixelSize: 17
              clip: true; selectByMouse: true
              onTextChanged: { ln.query = text; ln.sel = 0 }
              Keys.onPressed: e => {
                if (e.key === Qt.Key_Down) { ln.sel = Math.min(ln.sel + 1, ln.results.length - 1); lv.positionViewAtIndex(ln.sel, ListView.Contain); e.accepted = true }
                else if (e.key === Qt.Key_Up) { ln.sel = Math.max(ln.sel - 1, 0); lv.positionViewAtIndex(ln.sel, ListView.Contain); e.accepted = true }
                else if (e.key === Qt.Key_Escape) { ln.dismissed(); e.accepted = true }
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { ln.activate(ln.sel); e.accepted = true }
              }
              Text { visible: sq.text === ""; text: "Search apps   =  calc   :  emoji   >  clipboard   wall"; color: ln.dim; font.family: ln.ff; font.pixelSize: 15; anchors.verticalCenter: parent.verticalCenter }
            }
          }
        }

        ListView {
          id: lv
          Layout.fillWidth: true; Layout.fillHeight: true
          clip: true; spacing: 4
          model: ln.results
          boundsBehavior: Flickable.StopAtBounds
          delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            readonly property bool cur: ln.sel === index
            width: ListView.view.width
            height: 56; radius: ln.r - 6
            color: cur ? Qt.alpha(ln.acc, 0.22) : (rm.containsMouse ? "#14ffffff" : "transparent")
            border.width: cur ? 1 : 0
            border.color: ln.acc
            RowLayout {
              anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
              spacing: 14
              IconImage {
                visible: !!row.modelData.entry
                implicitSize: 34
                source: row.modelData.entry ? Quickshell.iconPath(row.modelData.entry.icon, "application-x-executable") : ""
              }
              Text { visible: !!row.modelData.g; text: row.modelData.g || ""; color: ln.acc; font.family: ln.ifont; font.pixelSize: 28; Layout.preferredWidth: 34 }
              Text { visible: !!row.modelData.e; text: row.modelData.e || ""; font.pixelSize: 26; Layout.preferredWidth: 34 }
              Image {
                visible: !!row.modelData.img
                source: row.modelData.img ? "file://" + row.modelData.img : ""
                sourceSize.width: 120
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                Layout.preferredWidth: 56; Layout.preferredHeight: 36
              }
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text { text: row.modelData.t; color: ln.txt; font.family: ln.ff; font.pixelSize: 15; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
                Text { visible: text !== ""; text: row.modelData.s || ""; color: ln.dim; font.family: ln.ff; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
              }
            }
            MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; onClicked: ln.activate(row.index) }
          }
        }

        Text { visible: ln.results.length === 0; text: "Nothing found"; color: ln.dim; font.family: ln.ff; font.pixelSize: 14; Layout.alignment: Qt.AlignHCenter }
      }
    }
  }
}
