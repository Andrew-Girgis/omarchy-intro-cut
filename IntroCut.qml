import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "girgie.intro-cut"
  ipcTarget: moduleName
  manageIpc: false
  property string fixedEdge: "end"
  readonly property bool vertical: bar ? bar.vertical : false
  property var info: null
  property bool failed: false
  readonly property bool busy: helper.running
  readonly property var intros: info ? info.intros : []

  Commons.Translations { id: catalog; directory: Qt.resolvedUrl("i18n") }

  function helperPath() { return decodeURIComponent(Qt.resolvedUrl("intro-cut.sh").toString().replace(/^file:\/\//, "")) }
  function refresh() {
    if (helper.running) return
    helper.command = [helperPath(), "status"]
    helper.running = true
    helperTimeout.restart()
  }
  function receive(raw) {
    try {
      if (raw.length > 1048576) { failed = true; return }
      var result = JSON.parse(raw)
      if (!Model.validStatus(result)) { failed = true; return }
      info = result
      failed = false
    } catch (e) {
      failed = true
      console.warn("Intro Cut: invalid helper response")
    }
  }
  // Close first so the intro plays over a clear desktop.
  function preview(row) {
    close()
    Quickshell.execDetached(["owe", "intro", "--start", "first-frame", row.intro])
  }
  function use(row) {
    Quickshell.execDetached(["omarchy-theme-bg-set", row.still])
    refreshSoon.restart()
  }
  function openMpv() {
    close()
    Quickshell.execDetached(["mpv", "--player-operation-mode=pseudo-gui", "--force-window=yes"])
  }

  onOpenedChanged: if (opened) refresh()
  Component.onCompleted: refresh()
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  ShellIpc {
    target: root.moduleName
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): void { root.refresh() }
    function status(): string { return JSON.stringify(root.info || {}) }
  }
  Process {
    id: helper
    stdout: StdioCollector { onStreamFinished: root.receive(text) }
    onExited: function(exitCode) { helperTimeout.stop(); if (exitCode !== 0) root.failed = true }
  }
  Timer { id: helperTimeout; interval: 30000; onTriggered: helper.running = false }
  Timer { id: refreshSoon; interval: 600; onTriggered: root.refresh() }

  WidgetButton {
    id: button
    bar: root.bar
    anchors.fill: parent
    text: "󰕧"
    tooltipText: Model.sharedText(catalog.t("bar.tooltip"))
    onPressed: function(b) { if (b === Qt.MiddleButton || b === Qt.RightButton) root.openMpv(); else root.toggle() }
  }

  component Heading: PlainText { font.pixelSize: Style.font.title; font.bold: true }
  component Note: PlainText { width: parent.width; wrapMode: Text.WordWrap; elide: Text.ElideNone; font.pixelSize: Style.font.bodySmall; opacity: 0.65 }
  component Rule: Rectangle { width: parent.width; height: 1; color: Qt.alpha(Commons.Color.popups.text, 0.1) }

  KeyboardPanel {
    id: panel
    bar: root.bar
    anchorItem: button
    owner: root
    open: root.opened
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(560))
    contentHeight: panel.cappedContentHeight(Style.space(640))

    content: PanelKeyCatcher {
      anchors.fill: parent
      onCloseRequested: root.close()
      onMoveRequested: function(dx, dy) {
        if (dy) scroll.contentY = Math.max(0, Math.min(scroll.contentHeight - scroll.height, scroll.contentY + dy * Style.space(110)))
      }
      onTextKey: function(t) {
        if (t === "r") root.refresh()
        if (t === "m") root.openMpv()
      }

      Column {
        id: top
        width: parent.width
        spacing: Style.space(10)
        Row {
          width: parent.width
          spacing: Style.space(6)
          Heading { text: catalog.t("title"); width: parent.width - mpvButton.width - refreshButton.width - closeButton.width - Style.space(18); anchors.verticalCenter: parent.verticalCenter }
          Button { id: mpvButton; text: catalog.t("openMpv"); enabled: !root.info || root.info.mpv !== "no-mpv"; onClicked: root.openMpv() }
          Button { id: refreshButton; text: root.busy ? catalog.t("loading") : catalog.t("refresh"); enabled: !root.busy; onClicked: root.refresh() }
          Button { id: closeButton; text: "×"; tooltipText: Model.sharedText(catalog.t("close")); onClicked: root.close() }
        }
        Note { text: catalog.t("howto") }
        Note { text: root.info && root.info.theme ? catalog.t("exportTo").arg(root.info.theme) : catalog.t("noTheme"); visible: root.info !== null }
        Note {
          visible: !!root.info && (root.info.mpv !== "linked" || !root.info.introsEnabled)
          color: Commons.Color.urgent; opacity: 1
          text: !root.info ? "" : root.info.mpv === "conflict" ? catalog.t("mpv.conflict") : root.info.mpv === "no-mpv" ? catalog.t("mpv.missing") : catalog.t("introsOff")
        }
        Rule {}
      }

      Flickable {
        id: scroll
        anchors.top: top.bottom
        anchors.topMargin: Style.space(12)
        anchors.bottom: footer.top
        anchors.bottomMargin: Style.space(10)
        width: parent.width
        contentWidth: width
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: list
          width: scroll.width - Style.space(8)
          spacing: Style.space(10)
          Note { visible: root.intros.length === 0; text: root.failed ? catalog.t("error") : root.info ? catalog.t("empty") : catalog.t("loading") }

          Repeater {
            model: root.intros
            Row {
              id: row
              required property var modelData
              width: list.width
              spacing: Style.space(12)

              Rectangle {
                width: Style.space(160); height: Style.space(90)
                radius: Style.space(4)
                color: Qt.alpha(Commons.Color.popups.text, 0.06)
                border.width: row.modelData.current ? 2 : 0
                border.color: Commons.Color.accent
                clip: true
                Image {
                  anchors.fill: parent
                  anchors.margins: parent.border.width
                  source: Model.fileUrl(row.modelData.still)
                  sourceSize.width: Style.space(320)
                  fillMode: Image.PreserveAspectCrop
                  asynchronous: true
                  cache: false
                }
              }

              Column {
                width: parent.width - Style.space(172)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(6)
                PlainText { width: parent.width; text: Model.displayName(row.modelData.name); font.bold: true }
                PlainText {
                  width: parent.width; font.pixelSize: Style.font.bodySmall; opacity: 0.65
                  text: [row.modelData.duration !== null ? catalog.t("seconds").arg(Commons.I18n.formatNumber(row.modelData.duration, 1)) : "",
                         row.modelData.current ? catalog.t("badge.current") : "",
                         row.modelData.user ? catalog.t("badge.yours") : ""].filter(function(s) { return s !== "" }).join(" · ")
                }
                Row {
                  spacing: Style.space(6)
                  Button { text: catalog.t("preview"); onClicked: root.preview(row.modelData) }
                  Button { text: catalog.t("use"); enabled: !row.modelData.current; onClicked: root.use(row.modelData) }
                }
              }
            }
          }
        }
      }

      Column {
        id: footer
        anchors.bottom: parent.bottom
        width: parent.width
        spacing: Style.space(5)
        Rule {}
        Note { text: catalog.tn("intros.count", root.intros.length).arg(Commons.I18n.formatNumber(root.intros.length, 0)) + " · " + catalog.t("footer.keys") }
      }
    }
  }
}
