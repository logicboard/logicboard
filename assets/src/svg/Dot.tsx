import React from "react";

export function Dot() {
    return (
        <svg width="8px" height="8px" viewBox="0 0 8 8" version="1.1">
            <defs>
                <linearGradient x1="50%" y1="100%" x2="50%" y2="0%" id="linearGradient-1">
                    <stop stopColor="#00AD31" offset="0%"></stop>
                    <stop stopColor="#00B536" offset="100%"></stop>
                </linearGradient>
            </defs>
            <g id="Page-1" stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
                <g id="icon-radio-button-active" fill="url(#linearGradient-1)" stroke="#009E2A" strokeWidth="0.576177285">
                    <rect id="Checkbox" x="0.288088643" y="0.288088643" width="7.42382271" height="7.42382271" rx="3.71191136"></rect>
                </g>
            </g>
        </svg>
    )
}
