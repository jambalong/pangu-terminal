import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["sidebar", "overlay"];

  connect() {
    const navLinks = document.querySelectorAll(".manual-nav a");
    const ids = Array.from(navLinks)
      .map((l) => l.getAttribute("href")?.slice(1))
      .filter(Boolean);
    const targets = ids.map((id) => document.getElementById(id)).filter(Boolean);

    const setActive = () => {
      const scrollY = window.scrollY + window.innerHeight * 0.25;

      let current = targets[0];
      for (const target of targets) {
        if (target.getBoundingClientRect().top + window.scrollY <= scrollY) {
          current = target;
        }
      }

      navLinks.forEach((link) => {
        link.classList.toggle("active", link.getAttribute("href") === "#" + current?.id);
      });
    };

    this.handleScroll = setActive;
    window.addEventListener("scroll", this.handleScroll, { passive: true });
    setActive();
  }

  disconnect() {
    window.removeEventListener("scroll", this.handleScroll);
  }

  toggleMenu() {
    this.sidebarTarget.classList.toggle("open");
    this.overlayTarget.classList.toggle("open");
  }

  closeMenu(event) {
    if (!event.target.closest("a")) return;
    this.sidebarTarget.classList.remove("open");
    this.overlayTarget.classList.remove("open");
  }

  toggleFaq(event) {
    const q = event.currentTarget;
    q.classList.toggle("open");
    q.nextElementSibling.classList.toggle("open");
  }
}
