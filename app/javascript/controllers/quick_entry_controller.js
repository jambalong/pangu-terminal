import { Controller } from "@hotwired/stimulus"

// Keyboard movement for the quick entry form: Enter or the down arrow goes to
// the next field, Shift+Enter or the up arrow to the previous one, and
// Ctrl/Cmd+Enter saves. Focusing a field selects its content so typing replaces it.
export default class extends Controller {
  static targets = ["field"]

  // Start in the first box, except on a touch screen, where that would
  // pop the on-screen keyboard over the page, so wait for a tap. A box that needs
  // fixing already has autofocus from the server.
  connect() {
    const alreadyFocused = this.fieldTargets.some((field) => field === document.activeElement)
    if (!alreadyFocused && this.hasFieldTarget && !window.matchMedia("(hover: none) and (pointer: coarse)").matches) {
      this.fieldTargets[0].focus()
    }
  }

  navigate(event) {
    if (event.ctrlKey || event.metaKey || event.altKey) return

    const index = this.fieldTargets.indexOf(event.target)
    if (index === -1) return

    let next = null
    if (event.key === "ArrowDown" || (event.key === "Enter" && !event.shiftKey)) next = index + 1
    if (event.key === "ArrowUp" || (event.key === "Enter" && event.shiftKey)) next = index - 1
    if (next === null) return

    event.preventDefault()
    this.fieldTargets[next]?.focus()
  }

  select(event) {
    event.target.select()
  }

  submitShortcut(event) {
    if (event.key === "Enter" && (event.ctrlKey || event.metaKey)) {
      event.preventDefault()
      event.currentTarget.requestSubmit()
    }
  }
}
