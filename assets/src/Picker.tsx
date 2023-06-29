import React from "react"
import { useEffect, useState, useRef } from "react"
import { useRecoilState } from 'recoil';
import { Run, Stop, Down, Dot } from "./svg"
import { languages, SupportedLanguage } from "./utils/languages"
import { PubSub } from "./utils/PubSub"
import { codeState, languageState, executingState } from "./AppState"

export function Picker() {
    const [language, setLanguage] = useRecoilState(languageState)
    const [_, setSource] = useRecoilState(codeState)
    const [isRunning, setRunning] = useRecoilState(executingState)
    const [visible, setVisible] = useState<Boolean>(false)
    const sortedLangs = languages.sort((a, b) => (a.name > b.name) ? 1 : -1)

    function handleClickOutside(ref) {
        useEffect(() => {
            function handleClickOutside(event) {
                if (ref.current && !ref.current.contains(event.target)) {
                    setVisible(false)
                }
            }
            document.addEventListener("mousedown", handleClickOutside)
            return () => {
                document.removeEventListener("mousedown", handleClickOutside)
            }
        }, [ref])
    }

    function handleSelection(lang: SupportedLanguage) {
        setLanguage(lang)
        setSource(lang.example)
        setVisible(false)
        PubSub.dispatch("local:language-changed", lang)
    }

    const wrapperRef = useRef(null)
    handleClickOutside(wrapperRef)

    return (
        <div ref={wrapperRef} className="w-36 relative inline-block text-left" >
            <div className="flex flex-row items-center rounded-sm bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50">
                <div className="flex flex-row cursor-pointer" onClick={async () => { setVisible(!visible) }} >
                    {isRunning ? (
                        <a>Stop</a>
                    ) : (
                        <div className="inline-flex space-x-2 items-center w-full justify-start gap-x-1.5 " id="menu-button" aria-expanded="true" aria-haspopup="true">
                            {language.name}
                            <Down />
                        </div>
                    )}
                </div>
                <div className="ml-auto cursor-pointer" onClick={async () => { PubSub.dispatch("local:run"); setRunning(true) }}>
                    {isRunning ? (<Stop />) : (<Run />)}
                </div>
            </div>
            <div className={`max-h-[400px] overflow-scroll absolute right-0 z-10 mt-2 w-36 origin-top-right rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none transition ${visible ? '' : 'invisible'} ease-${visible ? 'out' : 'in'} duration-${visible ? '100' : '75'} transform opacity-${visible ? '100' : '0'}`} role="menu" aria-orientation="vertical" aria-labelledby="menu-button" tab-index="-1">
                <div className="py-1" role="none">
                    {sortedLangs.map((lang) => {
                        return (
                            <div key={lang.code} className="flex flex-row items-center justify-start hover:bg-gray-hover-bg cursor-pointer" onClick={async () => { handleSelection(lang) }}>
                                <a href="#" className="text-gray-700 block px-4 py-2 text-md" role="menuitem" tab-index="-1" id="menu-item-0">{lang.name}</a>
                                <div className={`ml-auto mr-4 ${language == lang ? "" : "invisible"}`}>
                                    <Dot />
                                </div>
                            </div>
                        );
                    })}
                </div>
            </div>
        </div>
    );
}