import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
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
}
