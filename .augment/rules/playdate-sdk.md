---
type: "always_apply"
---

# Playdate SDK Documentation

Always reference the official Playdate SDK documentation when working with Playdate development.

- Official Documentation: `docs/playdate/Inside Playdate.html`
- SDK Version: 3.0.2
- Primary Language: Lua (with C API available)

## Key Guidelines:
- Use `playdate.graphics` for drawing operations
- Display resolution: 400x240 pixels, 1-bit monochrome
- Default refresh rate: 30 FPS (max 50 FPS)
- Use `import` instead of `require` for loading Lua files
- Main entry point must be `main.lua`
- Follow the geometry API conventions in `playdate.geometry`
- Always build the output to `builds` directory, always use `gmud-pd.pdx` as the bulit package name