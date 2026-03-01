import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "icon", "planner", "inventory", "dashboard"]

  connect() {
    this.createBackdrop()
    this.boundUpdateActiveLinks = this.updateActiveLinks.bind(this)
    this.updateActiveLinks()
    document.addEventListener("turbo:load", this.boundUpdateActiveLinks)
  }

  disconnect() {
    document.body.classList.remove("no-scroll")
    if (this.backdrop) {
      this.backdrop.remove()
    }
    document.removeEventListener("turbo:load", this.boundUpdateActiveLinks)
  }

  updateActiveLinks() {
    const path = window.location.pathname
    this.plannerTarget.classList.toggle("active-state", path.startsWith("/app/planner"))
    this.inventoryTarget.classList.toggle("active-state", path.startsWith("/app/inventory"))
    if (this.hasDashboardTarget) {
      this.dashboardTarget.classList.toggle("active-state", path === "/app")
    }
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
}