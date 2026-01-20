import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (sessionStorage.getItem("sync_banner_dismissed") === "true") {
      this.element.remove()
    }
  }

  dismiss(event) {
    if (event) event.preventDefault()

    this.element.classList.add("is-dismissing")

    setTimeout(() => {
      this.element.remove()
      sessionStorage.setItem("sync_banner_dismissed", "true")
    }, 300)
  }
}