import React from "react"
import { useEffect, useRef } from "react"
import { XTerm } from "xterm-for-react"
import { FitAddon } from "xterm-addon-fit"
import { PubSub } from "./utils/PubSub"
import { Socket } from "./websocket/socket"
import LocalEchoController from "local-echo"
import { stdin } from "./websocket/messages"
import { blue, red } from 'ansicolor'
import { defaultLanguage, SupportedLanguage } from "./utils/languages"

import "xterm/css/xterm.css"

export function Terminal() {
    const xtermRef = useRef<XTerm | null>(null)
    const fitAddon = new FitAddon()
    const localEcho = new LocalEchoController()

    function readLine(prompt: string = "") {
        localEcho.read(prompt)
            .then(input => {
                if (input.toLowerCase() == "repl()") {
                    PubSub.dispatch("local:repl")
                } else {
                    Socket.send(stdin(input))
                }
                readLine()
            })
            .catch(_ => {})
    }

    function attemptRead(language: SupportedLanguage) {
        xtermRef.current?.terminal.reset()
        localEcho.println(language.message)
        if (language.repl) {
            readLine()
        }
    }

    useEffect(() => {
        attemptRead(defaultLanguage)
        const id = "terminal"
        PubSub.on(id, "local:stdout", (text) => {
            localEcho.println(text)
        })
        PubSub.on(id, "ws:stdout", (message) => {
            const lines = message.content.split("\n")
            lines.forEach((line, index) => {
                readLine(`${index > 0 ? "\n" : ""}${line}`)
            })
        });
        PubSub.on(id, "ws:stderr", (message) => {
            localEcho.println(red(message.content))
        });
        PubSub.on(id, "ws:stop", (payload) => {
            if (payload.reason != "kill") {
                localEcho.abortRead()
                localEcho.println(blue(payload.message))
                readLine()
            }
        })
        PubSub.on(id, "ws:error", (payload) => {
            localEcho.println(red(payload.content))
            readLine()
        })
        PubSub.on(id, "local:language-changed", (language) => {
            localEcho.abortRead()
            // Let the current read promise to complete
            setTimeout(() => {
                attemptRead(language)
            }, 0)
        })
    })

    useEffect(() => {
        fitAddon.fit()
        window.addEventListener('resize', () => { fitAddon.fit() })
    })

    return (
        <div className="output-container h-full p-4 relative">
            <XTerm
                className="terminal-container h-full"
                ref={xtermRef}
                addons={[fitAddon, localEcho]}
                options={{
                    theme: {
                        background: '#FFFFFFFF',
                        foreground: '#000000FF',
                        selection: '#FFFFFF', // Needs xterm-selection-layer's mix-blend-mode: exclusion
                        cursor: '#9B9B9B',
                    },
                    fontSize: 14,
                    cursorBlink: true,
                    cursorStyle: "block"
                }}
                onResize={async () => { fitAddon.fit() }} 
                customKeyEventHandler={(e) => { 
                    if (e.ctrlKey && e.type == "keydown" && (e.key == "c" || e.key == "d")) {
                        let input = e.key == "c" ? '\u0003' : '\u0004'
                        Socket.send(stdin(input))
                    } else if ((e.metaKey || e.ctrlKey) && e.key == "k" && e.type == "keydown") {
                        xtermRef.current?.terminal.clear()
                    }
                    return true
                 }} 
                />
        </div>

    );
}
