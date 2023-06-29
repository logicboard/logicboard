import React from "react"
import { useEffect } from "react"
import { defaultLanguage } from "./utils/languages"
import { atom, useRecoilState, useRecoilValue } from "recoil"
import { PubSub } from "./utils/PubSub"
import { Socket } from "./websocket/socket"
import { repl, run, kill } from "./websocket/messages"

export const languageState = atom({
    key: 'languageState',
    default: defaultLanguage,
});

export const codeState = atom({
    key: 'codeState',
    default: defaultLanguage.example,
});

export const executingState = atom({
    key: 'executingState',
    default: false,
});

export function AppState() {
    const language = useRecoilValue(languageState)
    const source = useRecoilValue(codeState)
    const [_, setRunning] = useRecoilState(executingState)

    Socket.connect()

    useEffect(() => {
        const id = "appstate"
        PubSub.on(id, "local:run", () => {
            setRunning(true)
            Socket.send(run(language, source))
          }
        )
        
        PubSub.on(id, "ws:stop", (message) => {
            setRunning(false)
        })

        PubSub.on(id, "local:repl", () => {
            Socket.send(repl(language, source))
        })

        PubSub.on(id, "local:language-changed", () => {
            Socket.send(kill())
        })
    })

    return (
        <div />
    )
}