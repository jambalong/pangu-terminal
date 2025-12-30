import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "label"]

  connect() {
    this.update()
  }

  update() {
    const min = parseInt(this.inputTarget.min) || 1
    const max = parseInt(this.inputTarget.max) || 10
    const val = parseInt(this.inputTarget.value)

    // Calculate percentage for CSS variable
    const percent = Math.round(((val - min) / (max - min)) * 100)
    this.inputTarget.style.setProperty('--value', `${percent}%`)

    // Update the linked external label
    if (this.hasLabelTarget) {
      const externalId = this.labelTarget.dataset.linkId
      const externalLabel = document.getElementById(externalId)
      if (externalLabel) {
        externalLabel.innerText = val
      }
    }
  }
}
