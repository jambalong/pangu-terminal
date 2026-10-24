import { Controller } from "@hotwired/stimulus"

const FOCUSABLE = [
  "a[href]",
  "button:not([disabled])",
  "input:not([disabled]):not([type=hidden])",
  "select:not([disabled])",
  "textarea:not([disabled])",
  "[tabindex]:not([tabindex='-1'])"
].join(",")

// Accessible dialog behavior for the shared modal shell: names the dialog after
// its first heading, moves focus inside, keeps Tab within the dialog, and
// returns focus to whatever opened it when the dialog goes away (closed here,
// or replaced by a Turbo response).
export default class extends Controller {
  static targets = ["dialog"]

  connect() {
    this.opener = document.activeElement
    this.nameFromHeading()
    // Wait a frame so content that autofocuses (or arrives late) settles first.
    requestAnimationFrame(() => this.moveFocusIn())
  }

  disconnect() {
    const opener = this.opener
    if (opener && opener.isConnected && typeof opener.focus === "function") {
      opener.focus()
    }
  }

  close(event) {
    if (event) event.preventDefault()

    this.element.remove()

    const frame = document.getElementById('modal')
    if (frame) {
      frame.removeAttribute("src")
      frame.innerHTML = ""
    }
  }

  closeOutside(event) {
    if (event.target === this.element) {
      this.close(event)
    }
  }

  trapFocus(event) {
    if (event.key !== "Tab") return

    const items = this.focusableItems()
    if (items.length === 0) {
      event.preventDefault()
      this.dialogTarget.focus()
      return
    }

    const first = items[0]
    const last = items[items.length - 1]
    const active = document.activeElement

    if (event.shiftKey && (active === first || active === this.dialogTarget)) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && active === last) {
      event.preventDefault()
      first.focus()
    }
  }

  focusableItems() {
    return Array.from(this.dialogTarget.querySelectorAll(FOCUSABLE)).filter((el) => el.offsetParent !== null)
  }

  nameFromHeading() {
    const heading = this.dialogTarget.querySelector("h1, h2, h3")
    if (!heading) return

    if (!heading.id) heading.id = `modal-title-${Math.random().toString(36).slice(2, 8)}`
    this.dialogTarget.setAttribute("aria-labelledby", heading.id)
    this.dialogTarget.removeAttribute("aria-label")
  }

  moveFocusIn() {
    if (this.dialogTarget.contains(document.activeElement)) return

    const items = this.focusableItems().filter((el) => !el.classList.contains("modal-close-btn"))
    const target = items[0] || this.dialogTarget
    target.focus()
  }
}
