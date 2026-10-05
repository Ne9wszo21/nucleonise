import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Rectangle {
  id: v
  required property var cfg
  property int cpu: 0
  property int mem: 0
  property bool want: cfg.showVitals
  visible: cfg.showVitals
  implicitHeight: 32
  implicitWidth: row.implicitWidth + 28
  radius: Math.min(cfg.vitalsRadius, 16)
  color: cfg.pill

  Process {
    id: p
    command: ["sh", "-c", 'read -r _ u1 n1 s1 i1 w1 q1 z1 _ < /proc/stat; sleep 1; read -r _ u2 n2 s2 i2 w2 q2 z2 _ < /proc/stat; t=$((u2+n2+s2+i2+w2+q2+z2-u1-n1-s1-i1-w1-q1-z1)); d=$((i2-i1)); [ $t -gt 0 ] || t=1; echo $((100*(t-d)/t)); while read k x _; do case $k in MemTotal:) mt=$x;; MemAvailable:) ma=$x;; esac; done < /proc/meminfo; echo $((100*(mt-ma)/mt))']
    stdout: StdioCollector {
      onStreamFinished: {
        const l = this.text.trim().split("\n")
        v.cpu = parseInt(l[0]) || 0
        v.mem = parseInt(l[1]) || 0
      }
    }
  }
  Timer { interval: 3000; running: v.visible; repeat: true; triggeredOnStart: true; onTriggered: p.running = true }

  RowLayout {
    id: row
    anchors.centerIn: parent
    spacing: 10
    RowLayout {
      spacing: 4
      Text { text: "speed"; color: "#e6e6e6"; font.family: v.cfg.iconFont; font.pixelSize: 18 }
      Text { text: v.cpu + "%"; color: "#e6e6e6"; font.family: v.cfg.fontFamily; font.pixelSize: v.cfg.fontSize }
    }
    RowLayout {
      spacing: 4
      Text { text: "memory"; color: "#e6e6e6"; font.family: v.cfg.iconFont; font.pixelSize: 18 }
      Text { text: v.mem + "%"; color: "#e6e6e6"; font.family: v.cfg.fontFamily; font.pixelSize: v.cfg.fontSize }
    }
  }
}
