import katex from 'katex'

/**
 * Shared KaTeX HTML renderer for editable Markdown surfaces.
 * Keep math generation out of editor widgets so every surface starts from the
 * same DOM contract as the Agent Markdown renderer.
 */
export function renderMarkdownMath(latex: string, displayMode = false): string {
  try {
    return katex.renderToString(latex, {
      displayMode,
      output: 'htmlAndMathml',
      throwOnError: false,
      // 数学模式里混入中文等 Unicode 文本时直接渲染，不输出警告（严格模式改为忽略）
      strict: false,
    })
  } catch {
    return latex
  }
}
