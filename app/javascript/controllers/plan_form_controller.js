import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  clampLevel(event) {
    const input = event.target
    let value = parseInt(input.value)

    if (value > 90) input.value = 90
    if (value < 1) input.value = 1

    this.ensureValidRange()
  }

  clampAscensionRank(event) {
    const input = event.target
    let value = parseInt(input.value)

    if (value > 6) input.value = 6
    if (value < 0) input.value = 0

    this.ensureValidRange()
  }

  // Ensures Target is always >= Current
  ensureValidRange() {
    const currentLvl = this.element.querySelector('input[name*="current_level"]')
    const targetLvl = this.element.querySelector('input[name*="target_level"]')
    const currentAsc = this.element.querySelector('input[name*="current_ascension_rank"]')
    const targetAsc = this.element.querySelector('input[name*="target_ascension_rank"]')

    if (parseInt(targetLvl.value) < parseInt(currentLvl.value)) {
      targetLvl.value = currentLvl.value
    }

    if (parseInt(targetAsc.value) < parseInt(currentAsc.value)) {
      targetAsc.value = currentAsc.value
    }
  }
}
