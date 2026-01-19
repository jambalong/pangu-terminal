import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "icon"]

  connect() {
    this.createBackdrop()
  }

  toggle() {
    const isActive = this.menuTarget.classList.toggle("is-active")
    this.iconTarget.classList.toggle("is-open")
    document.body.classList.toggle("no-scroll", isActive)
    
    if (this.backdrop) {
      this.backdrop.classList.toggle("is-visible", isActive)
    }
  }

  close() {
    this.menuTarget.classList.remove("is-active")
    this.iconTarget.classList.remove("is-open")
    document.body.classList.remove("no-scroll")
    
    if (this.backdrop) {
      this.backdrop.classList.remove("is-visible")
    }
  }

  createBackdrop() {
    if (window.innerWidth <= 768 && !this.backdrop) {
      this.backdrop = document.createElement('div')
      this.backdrop.className = 'mobile-menu-backdrop'
      this.backdrop.addEventListener('click', () => this.close())
      document.body.appendChild(this.backdrop)
    }
  }

  disconnect() {
    document.body.classList.remove("no-scroll")
    if (this.backdrop) {
      this.backdrop.remove()
    }
  }
}