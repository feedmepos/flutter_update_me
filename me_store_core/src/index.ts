import type { Env, MiddlewareHandler } from "hono";
import { Octokit } from "octokit";

export type SupportedPlatform = "windows" | "android" | "ios";
export type DeviceMeta = { [key: string]: any };
export type CheckForUpdateQuery = {
  appId: string;
  platform: SupportedPlatform;
  version: string;
  deviceId: string;
} & DeviceMeta;
export type ReleaseChecker = (
  query: CheckForUpdateQuery,
  release: GithubRelease
) => Promise<boolean>;
export type Enforcer = (release: GithubRelease) => string;

export interface MeStoreReleaseInfo {
  version: string;

  /**
   * The date the release published
   */
  releaseAt: string;

  /**
   * The time to enforce this version
   */
  enforceAt: string | null;

  /**
   * HTML format, follow Github Release
   */
  releaseNote: string;

  bundleUrl: string;
}

export interface MeStoreAppConfig {
  appId: string;
  github: string;
  tagPrefix?: string;
  githubToken?: string;
  shouldGetRelease?: ReleaseChecker;
  enforcer?: Enforcer;
  bundleExtension?: PlatformBundleExtension;
}

export interface MeStoreConfig {
  apps: MeStoreAppConfig[];
  cacheBundle?: (asset: string) => Promise<string>;
}

type PlatformBundleExtension = {
  [key in SupportedPlatform]: string;
};

type GithubRelease = Awaited<
  ReturnType<Octokit["rest"]["repos"]["getRelease"]>
>["data"];

const defaultExtensionSettings: PlatformBundleExtension = {
  windows: "exe",
  android: "apk",
  ios: "ipa",
};

function getPlatformAsset(
  platform: SupportedPlatform,
  release: GithubRelease
): GithubRelease["assets"][0] | undefined {
  return release.assets.find((a) =>
    a.name.endsWith(defaultExtensionSettings[platform])
  );
}

export function MeStore(config: MeStoreConfig): MiddlewareHandler {
  return async (c) => {
    const query = c.req.query() as CheckForUpdateQuery;
    const app = config.apps.find((a) => a.appId == query.appId);

    if (!app) {
      return c.text("App not found", 404);
    }

    const splitted = new URL(app?.github).pathname.split("/");
    const owner = splitted[1];
    const repo = splitted[2];

    const octokit = new Octokit({ auth: app.githubToken });
    let availableReleases: GithubRelease[] = [];
    let latestVersionFound: boolean = false;
    let page = 1;

    // Keep fetch release until we found the latest version
    while (!latestVersionFound) {
      // Fetch all the release from the repo
      let releases = (
        await octokit.rest.repos.listReleases({
          owner: owner,
          repo: repo,
          per_page: 100,
          page,
        })
      ).data;

      // If no more release found, stop the loop
      if (releases.length == 0) {
        break;
      }

      // filter out the release tag matched certain prefix, unsed in monorepo with multiple app release
      if (app.tagPrefix) {
        releases = releases.filter((r) =>
          r.tag_name.startsWith(app.tagPrefix!)
        );
      }

      // Filter out the releases that has asset matched the platform supported extension
      releases = releases.filter((r) => !!getPlatformAsset(query.platform, r));

      for (let r of releases) {
        availableReleases.push(r);
        if (!r.prerelease && !r.draft) {
          latestVersionFound = true;
          break;
        }
      }
      page++;
    }

    if (availableReleases.length == 0) {
      return c.text("No release found", 404);
    }

    let selectedRelease;
    let checker: ReleaseChecker =
      app.shouldGetRelease ||
      (async (_, release) =>
        release.prerelease === false && release.draft === false);

    for (var r of availableReleases) {
      if (await checker(query, r)) {
        selectedRelease = r;
        break;
      }
    }

    if (!selectedRelease) {
      return c.text("No suitable release found", 404);
    }

    const bundle = getPlatformAsset(query.platform, selectedRelease)!;
    const resp: MeStoreReleaseInfo = {
      version: selectedRelease.name!,
      enforceAt: app.enforcer ? app.enforcer(selectedRelease) : null,
      releaseAt: selectedRelease.published_at!,
      releaseNote: selectedRelease.body_html || "",
      bundleUrl: config.cacheBundle
        ? await config.cacheBundle(bundle.browser_download_url)
        : bundle.browser_download_url,
    };
    return c.json(resp, 200);
  };
}
