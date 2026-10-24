import { Controller } from "@hotwired/stimulus"

// Puts keyboard focus on its element when it appears, for content that Turbo
// swaps in (for example the move button a person just used, after the list re-renders).
export default class extends Controller {
  connect() {
    this.element.focus()
  }
}
