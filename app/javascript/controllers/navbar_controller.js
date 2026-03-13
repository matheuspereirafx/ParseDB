import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="navbar"
export default class extends Controller {
  static targets = ["dropdown", "mobileMenu"]

  // Toggle mobile hamburger menu
  toggleMobile() {
    this.element.classList.toggle("sf-nav-open")
  }

  // Toggle avatar dropdown
  toggleDropdown() {
    this.dropdownTarget.classList.toggle("open")
  }

  // Close dropdown when clicking outside
  closeDropdown(event) {
    if (this.hasDropdownTarget && !this.dropdownTarget.contains(event.target)) {
      this.dropdownTarget.classList.remove("open")
    }
  }

  // Listen for clicks outside (connected automatically)
  connect() {
    this.outsideClick = this.closeDropdown.bind(this)
    document.addEventListener("click", this.outsideClick)
  }

  // Clean up when controller disconnects
  disconnect() {
    document.removeEventListener("click", this.outsideClick)
  }
}
