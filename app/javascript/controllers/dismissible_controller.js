import { Controller } from "@hotwired/stimulus"

// Removes its element when dismissed and remembers that. By default the memory
// lasts for the browser session (the sync banner); set
// data-dismissible-persist-value="true" to keep it across sessions, and
// data-dismissible-key-value to give each dismissible thing its own key.
export default class extends Controller {
  static values = {
    key: { type: String, default: "sync_banner_dismissed" },
    persist: { type: Boolean, default: false }
  }

  connect() {
    if (this.read() === "true") {
      this.element.remove()
    }
  }

  dismiss(event) {
    if (event) event.preventDefault()

    this.element.classList.add("is-dismissing")

    setTimeout(() => {
      this.element.remove()
      this.write("true")
    }, 300)
  }

  get storage() {
    return this.persistValue ? window.localStorage : window.sessionStorage
  }

  // Storage can throw (private windows, blocked site data); the banner then
  // simply comes back next time.
  read() {
    try {
      return this.storage.getItem(this.keyValue)
    } catch {
      return null
    }
  }

  write(value) {
    try {
      this.storage.setItem(this.keyValue, value)
    } catch {
      // ignore
    }
  }
}
