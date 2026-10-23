import { Controller } from "@hotwired/stimulus"

// Submits its form when a field fires the wired event, for example
// data-action="change->auto-submit#submit". Replaces inline onchange handlers,
// which the content security policy blocks.
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
