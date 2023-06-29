import React from "react"
import { useRecoilValue, useRecoilState } from 'recoil'
import ReactCodeMirror from '@uiw/react-codemirror'
import { codeState, languageState } from "../AppState"
import { StreamLanguage } from '@codemirror/language'
import { elixir } from 'codemirror-lang-elixir'
import { SupportedLanguage } from "../utils/languages"
import { loadLanguage } from "@uiw/codemirror-extensions-langs"

export function CodeMirror() {

  const language = useRecoilValue(languageState)
  const [source, setSource] = useRecoilState(codeState)

  function lang(lang: SupportedLanguage) {
    if (lang.code == 'elixir') {
      return StreamLanguage.define(elixir)
    }
    return loadLanguage(lang.codemirror_code)
  }

  return (
    <div className="bg-blue-200 w-full h-full">
      <ReactCodeMirror className="h-full"
        value={source}
        height="100%"
        width="100%"
        style={{}}
        extensions={[lang(language)!].filter(Boolean)}
        onChange={async (value) => { setSource(value) }}
      />
    </div>
  )
}