Como você é um **Arquiteto de Sistemas** e está trabalhando com uma linguagem de baixo nível como **Zig**, o prompt precisa ser técnico e focado em "como as coisas funcionam por baixo do capô".

Aqui está um prompt estruturado para o **NotebookLM**. Ele foi desenhado para extrair informações sobre gerenciamento de memória, interoperação com C (C-ABI) e técnicas de renderização vetorial.

---

### Deep Research Prompt for NotebookLM

> **Role:** You are a Senior Systems Architect and Graphics Engineer specializing in low-level languages (Zig/C/C++) and high-performance GUI applications.
>
> **Task:** Conduct a deep investigation to provide technical references, libraries, and implementation strategies for building a **High-Performance Infinite Canvas Drawing Application** using the **Zig programming language** and **Wacom Intuos** tablets.
>
> **Core Investigation Areas:**
>
> 1.  **Input Handling & Low Latency:**
>     * Investigate APIs for Wacom tablet input (Wintab on Windows, Libinput/XInput on Linux) and how to interface them with Zig using C-ABI.
>     * Research techniques for sub-pixel precision and high-frequency polling to minimize input-to-photon latency.
>     * Identify methods for stroke stabilization and smoothing (e.g., Savitzky-Golay filters or Cubic Bézier interpolation) suitable for real-time applications.
>
> 2.  **Infinite Canvas Architecture:**
>     * Research spatial partitioning structures (Quadtrees, R-trees, or Tiling) to manage millions of vector points efficiently in an infinite 2D space.
>     * Identify strategies for "Floating Point Drift" mitigation when navigating far from the origin (e.g., using `f64` for world coordinates and `f32` for local view-space).
>     * Explore "Level of Detail" (LOD) techniques for rendering thick vs. thin lines at different zoom levels.
>
> 3.  **Zig-Compatible Graphics Libraries:**
>     * Compare low-level backends: **Mach (WebGPU)**, **Sokol (OpenGL/D3D)**, and **Raylib**. Evaluate them based on Zig 0.13+ compatibility, memory footprint, and ease of custom vertex buffer manipulation.
>     * Look for Zig-native implementations of path rendering or efficient GPU-accelerated vector graphics (similar to NanoVG or Lyon).
>
> 4.  **Data Persistence & Export:**
>     * Research efficient binary serialization formats for vector data (ZON, FlatBuffers, or custom packed structs).
>     * Investigate headless rendering techniques to export the vector canvas into high-resolution lossless formats like PNG/TGA without affecting the main UI thread.
>
> 5.  **Technical References:**
>     * Find open-source projects or academic papers related to infinite canvas tools (e.g., concepts used in Figma, Miro, or Xournal++).
>
> **Output Format:** Provide a structured technical report with specific library recommendations, code snippets logic (pseudo-code or Zig), and a list of "Best Practices" for memory management in this specific context.