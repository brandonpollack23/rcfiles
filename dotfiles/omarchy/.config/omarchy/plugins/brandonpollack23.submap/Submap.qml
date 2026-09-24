import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui

// The active Hyprland submap's name in a pill, the theme's red with its
// background for text, as a locked group's tabs are (hypr/looknfeel.lua).
// Hidden outside a submap. Hyprland sends `submap>>NAME` on entering one and
// `submap>>` on leaving; `hyprctl submap` reads the one active at startup.
BarWidget {
  id: root
  moduleName: "brandonpollack23.submap"

  property string submap: ""

  readonly property color fill: Color.urgent
  readonly property int pillInset: Math.max(2, Math.round(root.barSize * 0.16))

  visible: root.submap !== "" && !root.vertical
  implicitWidth: visible ? label.implicitWidth + Style.spacing.controlPaddingX * 2 : 0
  implicitHeight: root.barSize

  Component.onCompleted: query.running = true

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event && event.name === "submap") root.submap = String(event.data || "")
    }
  }

  Process {
    id: query
    command: ["hyprctl", "submap"]
    stdout: StdioCollector {
      onStreamFinished: {
        const name = this.text.trim()
        root.submap = name === "default" ? "" : name
      }
    }
  }

  Rectangle {
    anchors.fill: parent
    anchors.topMargin: root.pillInset
    anchors.bottomMargin: root.pillInset
    radius: height / 2
    color: root.fill

    Text {
      id: label
      anchors.centerIn: parent
      textFormat: Text.PlainText
      text: root.submap
      color: Color.background
      font.family: root.bar && root.bar.fontFamily !== "" ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.body
      font.bold: true
    }
  }
}
