import { loadEnv } from 'vite'
import { defineConfig } from 'vitest/config'

// Relative base keeps production output portable for the iOS bundle.
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, '.', ['HOST', 'PORT'])
  const port = Number(env.PORT ?? 3000)
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('Invalid PORT')
  return {
    base: './',
    // Inline (empty) PostCSS config. Without it Vite searches parent folders for a
    // postcss.config.* and loads whatever it finds there, which broke the stylesheet
    // when an unrelated Tailwind config sat above this project.
    css: { postcss: { plugins: [] } },
    server: {
      host: env.HOST ?? '127.0.0.1', port, strictPort: true,
      allowedHosts: ['localhost', '127.0.0.1'],
    },
    build: { target: 'es2022', assetsInlineLimit: 0, chunkSizeWarningLimit: 4600, sourcemap: false },
    test: { environment: 'node', include: ['tests/**/*.test.{ts,mjs}'] },
  }
})
