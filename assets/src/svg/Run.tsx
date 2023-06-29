import React from "react";

export function Run() {
    return (
        <svg width="24px" height="24px" viewBox="0 0 21 24" version="1.1" className="dropdown-run">
            <defs>
                <linearGradient x1="50%" y1="100%" x2="50%" y2="0%" id="linearGradient-1">
                    <stop stopColor="#00AD31" offset="0%"></stop>
                    <stop stopColor="#00B536" offset="100%"></stop>
                </linearGradient>
                <polygon id="path-2" points="0 0 19 10.9981779 0 22"></polygon>
                <filter x="-10.5%" y="-4.5%" width="121.1%" height="118.2%" filterUnits="objectBoundingBox" id="filter-3">
                    <feOffset dx="0" dy="1" in="SourceAlpha" result="shadowOffsetOuter1"></feOffset>
                    <feGaussianBlur stdDeviation="0.5" in="shadowOffsetOuter1" result="shadowBlurOuter1"></feGaussianBlur>
                    <feComposite in="shadowBlurOuter1" in2="SourceAlpha" operator="out" result="shadowBlurOuter1"></feComposite>
                    <feColorMatrix values="0 0 0 0 0.05996003   0 0 0 0 0.12319117   0 0 0 0 0.0786947682  0 0 0 0.1 0" type="matrix" in="shadowBlurOuter1"></feColorMatrix>
                </filter>
                <filter x="-10.5%" y="-4.5%" width="121.1%" height="118.2%" filterUnits="objectBoundingBox" id="filter-4">
                    <feOffset dx="0" dy="2" in="SourceAlpha" result="shadowOffsetInner1"></feOffset>
                    <feComposite in="shadowOffsetInner1" in2="SourceAlpha" operator="arithmetic" k2="-1" k3="1" result="shadowInnerInner1"></feComposite>
                    <feColorMatrix values="0 0 0 0 0.999901831   0 0 0 0 1   0 0 0 0 0.999879897  0 0 0 0.06 0" type="matrix" in="shadowInnerInner1"></feColorMatrix>
                </filter>
            </defs>
            <g id="run" stroke="none" strokeWidth="1" fill="none" fillRule="evenodd">
                <g id="Fill-125" transform="translate(1.000000, 0.000000)">
                    <use fill="black" fillOpacity="1" filter="url(#filter-3)" href="#path-2"></use>
                    <use fill="url(#linearGradient-1)" fillRule="evenodd" href="#path-2"></use>
                    <use fill="black" fillOpacity="1" filter="url(#filter-4)" href="#path-2"></use>
                    <path stroke="#009E2A" strokeWidth="0.95" d="M0.475,0.823794086 L18.0519648,10.998246 L0.475,21.1760692 L0.475,0.823794086 Z"></path>
                </g>
            </g>
        </svg>
    )
}
