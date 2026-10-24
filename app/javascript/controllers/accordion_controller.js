import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["content"];

  toggle() {
    const content = this.contentTarget;
    const chevron = this.element.querySelector(".accordion-chevron");
    const header = this.element.querySelector(".accordion-header");

    if (content.style.maxHeight && content.style.maxHeight !== "0px") {
      content.style.maxHeight = "0px";
      chevron?.classList.remove("open");
      content.classList.remove("open");
      header?.setAttribute("aria-expanded", "false");
    } else {
      content.style.maxHeight = content.scrollHeight + "px";
      chevron?.classList.add("open");
      content.classList.add("open");
      header?.setAttribute("aria-expanded", "true");
    }
  }
}
