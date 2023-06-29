import React from "react"
import { RecoilRoot } from "recoil"
import { createRoot } from "react-dom/client"
import { CodeMirror } from "./editor/CodeMirror"
import { Terminal } from "./Terminal"
import { Menu } from "./Menu"
import { AppState } from "./AppState"

const container = document.getElementById("app")
const root = createRoot(container!)

export function App() {
  return (
    <div className="flex w-screen h-screen font-OpenSans font-regular">
      <CodeMirror />
      <div className="flex flex-col min-w-[43%] border-l-[1px] border-gray-lighter">
        <Menu />
        <Terminal />
      </div>
    </div>
  )
}

root.render(
  <RecoilRoot>
    <AppState />
    <App />
  </RecoilRoot>
)