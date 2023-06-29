import { defaultLanguage, SupportedLanguage } from "../utils/languages"

export enum Event {
    RUN = "run",
    REPL = "repl",
    STDIN = "stdin",
    STDOUT = "stdout",
    ERROR = "error",
    STOP = "stop",
    KILL = "kill"
}

export type File = {
    main: boolean,
    name: string,
    directory: boolean,
    content: string
}

export type Message = {
    event: Event,
    payload: {},
}

export function run(language: SupportedLanguage, code: string) {
    return ({
        event: Event.RUN,
        payload: {
            language: language.code,
            files: [
                {
                    main: true,
                    name: language.main_file,
                    directory: false,
                    content: code
                }
            ]
        }
    })
}

export function repl(language: SupportedLanguage, code: string) {
    return ({
        event: Event.REPL,
        payload: {
            language: language.code,
            files: [
                {
                    main: true,
                    name: language.main_file,
                    directory: false,
                    content: code
                }
            ]
        }
    })
}

export function stdin(text: string) {
    return ({
        event: Event.STDIN,
        payload: {
            content: text
        }
    })
}

export function kill() {
    return ({
        event: Event.KILL,
        payload: {

        }
    })
}