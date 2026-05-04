import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["content"];

  toggle() {
    const content = this.contentTarget;
    const chevron = this.element.querySelector(".accordion-chevron");

    if (content.style.maxHeight && content.style.maxHeight !== "0px") {
      content.style.maxHeight = "0px";
      chevron?.classList.remove("open");
      content.classList.remove("open");
    } else {
      content.style.maxHeight = content.scrollHeight + "px";
      chevron?.classList.add("open");
      content.classList.add("open");
    }
  }
}
