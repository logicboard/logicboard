/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        OpenSans: ["Open Sans", "sans-serif"],
        Code: ["IBM Plex Mono", "monospace"],
      },
      fontWeight: {
        thin: 100,
        extralight: 200,
        light: 300,
        slim: 350,
        regular: 400,
        medium: 500,
        semibold: 600,
        bold: 700,
      },
      fontSize: {
        md: '0.95rem'
      },
      colors: {
        gray: {
          'extreme-dark': '#1F2022',
          'dark': '#242420',
          'soft-dark': '#2A2B30',
          'normal': '#899196',
          'light': '#91908B',
          'lighter': '#C9C9C9',
          'hover-bg': '#F6F8FA',
        }
      }
    },
  },
  plugins: [],
}

