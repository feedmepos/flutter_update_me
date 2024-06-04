import { Hono } from "hono";
import { MeStore } from "@feedmepos/me-store-core";

type Bindings = {
  OPENAI_API_KEY: string;
  GITHUB_API_KEY: string;
};

const app = new Hono<{ Bindings: Bindings }>();

app.get("/", (c) => {
  return c.text(c.env.OPENAI_API_KEY);
});

app.get(
  "/version",
  MeStore({
    apps: [
      {
        appId: "cc.feedme.vitame",
        github: "https://github.com/feedmepos/flutter_update_me",
      },
    ],
  })
);

export default app;
