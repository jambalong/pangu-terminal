import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  show(e) {
    const text = e.currentTarget.dataset.tooltip;
    if (!text) return;

    const tooltip = document.createElement("div");
    tooltip.id = "floating-tooltip";
    tooltip.textContent = text;
    tooltip.style.cssText = `
      position: fixed;
      background: var(--ctp-crust);
      color: var(--ctp-text);
      font-size: 0.7rem;
      padding: 0.25rem 0.5rem;
      border-radius: 0.25rem;
      border: 1px solid var(--ctp-surface1);
      pointer-events: none;
      z-index: 9999;
    `;
    document.body.appendChild(tooltip);

    const rect = e.currentTarget.getBoundingClientRect();
    tooltip.style.left = `${rect.left + rect.width / 2 - tooltip.offsetWidth / 2}px`;
    tooltip.style.top = `${rect.top - tooltip.offsetHeight - 6}px`;
  }

  hide() {
    document.getElementById("floating-tooltip")?.remove();
  }
}
