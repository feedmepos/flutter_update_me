import { Hono } from 'hono'

type Bindings = {
  OPENAI_API_KEY: string
  GITHUB_API_KEY: string
}

const app = new Hono<{ Bindings: Bindings }>()

app.get('/', (c) => {
  return c.text(c.env.OPENAI_API_KEY);
})

app.get('/version', (c) => {
  return c.text(c.env.GITHUB_API_KEY);
})

export default app
