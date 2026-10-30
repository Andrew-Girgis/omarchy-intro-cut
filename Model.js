// Pure helpers, also exercised under Node. Shared shell sinks never receive markup.
function sharedText(value) {
  return String(value).replace(/&/g, "＆").replace(/</g, "＜").replace(/>/g, "＞").slice(0, 500)
}

// Encode each segment so names with spaces, # or ? still load as images.
function fileUrl(path) {
  if (!path || String(path).charAt(0) !== "/") return ""
  return "file://" + String(path).split("/").map(encodeURIComponent).join("/")
}

function displayName(name) {
  return String(name || "").replace(/[_-]+/g, " ").trim().slice(0, 120)
}

function validStatus(result) {
  return !!result && typeof result === "object" && Array.isArray(result.intros) &&
    result.intros.every(function(row) {
      return row && typeof row.still === "string" && typeof row.intro === "string" &&
        row.still.charAt(0) === "/" && row.intro.charAt(0) === "/"
    })
}

if (typeof module !== "undefined") module.exports = {sharedText, fileUrl, displayName, validStatus}
