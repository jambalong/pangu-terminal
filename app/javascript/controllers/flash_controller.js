import { Controller } from "@hotwired/stimulus"

// Notices fade out after a few seconds. Errors stay until dismissed (set
// data-flash-persist-value="true"), because people need time to read them.
export default class extends Controller {
  static values = { persist: Boolean, delay: { type: Number, default: 6000 } }

  connect() {
    if (this.persistValue) return

    this.timer = setTimeout(() => this.dismiss(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  dismiss() {
    this.element.style.transition = "opacity 0.5s ease"
    this.element.style.opacity = "0"
    setTimeout(() => this.element.remove(), 500)
  }
}
