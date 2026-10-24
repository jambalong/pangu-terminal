import { Controller } from "@hotwired/stimulus"

// Copies the text of a read-only field and says so in a live region. If the
// browser blocks clipboard access, the text is selected so Ctrl/Cmd+C works.
export default class extends Controller {
  static targets = ["source", "status"]

  select() {
    this.sourceTarget.select()
  }

  async copy() {
    this.select()

    try {
      await navigator.clipboard.writeText(this.sourceTarget.value)
      this.statusTarget.textContent = "Link copied."
    } catch {
      this.statusTarget.textContent = "Press Ctrl+C (or Cmd+C) to copy the selected link."
    }
  }
}
