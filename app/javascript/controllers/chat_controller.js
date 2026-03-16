import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chat"
export default class extends Controller {
  static targets = ["sidebar", "openBtn", "messages"]

  connect() {
    this.scrollMessages()
    this.outsideClick = this.closeMenus.bind(this)
    document.addEventListener("click", this.outsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClick)
  }

  // Scroll messages to bottom
  scrollMessages() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }

  // Sidebar toggle
  closeSidebar() {
    this.sidebarTarget.classList.add("collapsed")
    this.openBtnTarget.classList.add("visible")
  }

  openSidebar() {
    this.sidebarTarget.classList.remove("collapsed")
    this.openBtnTarget.classList.remove("visible")
  }

  // Toggle menu dos 3 pontos
  toggleMenu(event) {
    event.preventDefault()
    event.stopPropagation()
    const chatId = event.currentTarget.dataset.chatId
    // Close all other menus
    document.querySelectorAll(".chat-menu-dropdown.open").forEach(el => {
      if (el.id !== `chatMenu-${chatId}`) el.classList.remove("open")
    })
    document.getElementById(`chatMenu-${chatId}`).classList.toggle("open")
  }

  // Close all menus when clicking outside
  closeMenus(event) {
    if (!event.target.closest(".chat-item-menu")) {
      document.querySelectorAll(".chat-menu-dropdown.open").forEach(el => el.classList.remove("open"))
    }
  }

  // Rename chat
  rename(event) {
    event.preventDefault()
    event.stopPropagation()
    const chatId = event.currentTarget.dataset.chatId
    const currentTitle = event.currentTarget.dataset.chatTitle
    const basePath = this.element.querySelector(".sidebar-chats").dataset.basePath
    const newTitle = prompt("Novo título:", currentTitle)

    if (newTitle && newTitle !== currentTitle) {
      const form = document.createElement("form")
      form.method = "POST"
      form.action = `${basePath}/${chatId}`

      const method = document.createElement("input")
      method.type = "hidden"
      method.name = "_method"
      method.value = "patch"
      form.appendChild(method)

      const token = document.createElement("input")
      token.type = "hidden"
      token.name = "authenticity_token"
      token.value = document.querySelector('meta[name="csrf-token"]').content
      form.appendChild(token)

      const title = document.createElement("input")
      title.type = "hidden"
      title.name = "chat[title]"
      title.value = newTitle
      form.appendChild(title)

      document.body.appendChild(form)
      form.submit()
    }
  }
}
