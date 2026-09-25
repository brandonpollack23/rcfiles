import QtQuick
import Quickshell
import Quickshell.Io

// Keystroke's side of the Omarchy menu's Meme Maker: every meme-maker template
// as a row, fuzzy-matched by the host on its name and id and by word on its
// tags and category, with the template's thumbnail in the preview pane. Enter
// runs bin/meme-menu with the template, which asks for each text slot in the
// menu, then saves the meme in the Save folder setting and copies it.
QtObject {
  id: root
  property var shell: null
  property var extension: null
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  readonly property string key: extension && extension.id ? extension.id : "meme"
  readonly property string icon: "󰋩"
  // meme-maker's installer puts the app here; its templates come with it.
  readonly property string templates: (Quickshell.env("MEME_MAKER_HOME") || Quickshell.env("HOME") + "/.meme-maker") + "/assets/templates"
  readonly property string script: decodeURIComponent(String(Qt.resolvedUrl("bin/meme-menu")).replace(/^file:\/\//, ""))
  readonly property string defaultDir: "~/Pictures/memes"
  property var rows: []
  property bool loaded: false

  readonly property var provider: ({
    apiVersion: 1, name: "Meme Maker", icon: root.icon, color: "#e5c07b",
    description: "Caption a meme template and copy it",
    settings: [
      { key: "saveDir", type: "string", label: "Save folder", "default": root.defaultDir,
        description: "Where memes are saved; ~ is your home folder" }
    ],
    query: function(ctx) { return root.query(ctx) },
    // Rows are built once, so the folder is read from the settings here.
    activate: function(row, ctx) {
      if (row.action.type !== "meme") return row.action
      var dir = String((ctx.settings && ctx.settings.saveDir) || "").trim() || root.defaultDir
      return { type: "exec", argv: [root.script, "--dir", dir, row.action.id] }
    }
  })

  // The installer rewrites the catalog on an update; watching picks that up.
  readonly property FileView manifest: FileView {
    path: root.templates + "/manifest.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.build(text())
    onLoadFailed: { root.rows = []; root.loaded = true }
  }

  function build(text) {
    var list = []
    try { list = JSON.parse(text).templates || [] } catch (e) { list = [] }
    var built = []
    for (var i = 0; i < list.length; i++) built.push(row(list[i], i))
    rows = built
    loaded = true
  }

  function row(t, i) {
    var slots = t.slots || []
    var names = slots.map(function(s) { return s.name })
    var hints = slots.map(function(s) { return s.hint ? s.name + ": " + s.hint : s.name })
    var tags = (t.tags || []).join(" ")
    return {
      id: String(t.id), title: String(t.name || t.id),
      subtitle: (t.type === "gif" ? "GIF · " : "") + names.join(" · "),
      icon: root.icon, section: "Memes", verb: "Caption", tier: "item", order: i, remember: true,
      keywords: String(t.id),
      description: [tags, t.category || "", t.type === "gif" ? "gif animated" : ""].join(" "),
      previewImage: root.templates + "/thumbs/" + t.id + ".webp", previewLabel: "MEME",
      previewDetail: hints.join(" · "),
      action: { type: "meme", id: String(t.id) }
    }
  }

  // Only with the `meme` prefix or on this screen: 600-odd templates would
  // crowd every search at the root. The Omarchy menu's Meme Maker row opens
  // this screen.
  function query(ctx) {
    if (ctx.scope && ctx.scope !== root.key) return []
    if (!ctx.command && ctx.scope !== root.key) return []
    if (loaded && !rows.length) {
      return [{ id: "missing", title: "meme-maker isn't installed", subtitle: "mise run deps tools",
                icon: root.icon, section: "Memes", tier: "item", score: 1, disabled: true, action: { type: "noop" } }]
    }
    return rows
  }
}
