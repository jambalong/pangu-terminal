import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["item"];
  static classes = ["hidden"];

  toggle(event) {
    const show = event.target.checked;
    this.itemTargets.forEach((item) => {
      item.classList.toggle("hidden", !show);
    });
  }
}
