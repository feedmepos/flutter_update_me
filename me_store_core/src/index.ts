import { Hono } from 'hono'
import { Octokit } from 'octokit'

export type DeviceMeta = { [key: string]: any };
export type CheckForUpdateQuery = {
  appId: string;
  version?: string;
  deviceId?: string;

  platform: 'windows' | 'android' | 'ios'
} & DeviceMeta;
export type ReleaseChecker = (query: CheckForUpdateQuery, release: GithubRelease) => Promise<boolean>;
export type CompulsoryChecker = (release: GithubRelease) => boolean;

export interface MeStoreReleaseInfo {
  compulsory: boolean;

  version: string;
  /**
   * ISO Date
   */
  releaseDate: string;

  releaseNote: string;

  installerUrl: string;
}

export interface MeStoreAppConfig {
  appId: string;
  owner: string;
  repo: string;
  tagPrefix?: string;
  githubToken?: string;
  shouldGetRelease?: ReleaseChecker;
  isCompulsory?:
}

export interface MeStoreConfig {
  apps: MeStoreAppConfig[];
}

type GithubRelease = Awaited<ReturnType<Octokit['rest']["repos"]["getRelease"]>>['data']

export function createStore(config: MeStoreConfig) {
  const store = new Hono()
  store.get('/check-for-update', async (c) => {
    const query = c.req.query() as CheckForUpdateQuery;
    const app = config.apps.find(a => a.appId == query.appId)
    if (!app) {
      return c.text('App not found', 404);
    }

    const octokit = new Octokit({ auth: app.githubToken });
    let prereleaseAfterlatest: GithubRelease[] = [];
    let latestVersionFound: GithubRelease | undefined;
    let page = 1;

    while (!latestVersionFound) {
      let releases = (await octokit.rest.repos.listReleases({
        owner: app.owner,
        repo: app.repo,
        per_page: 100,
        page,
      })).data

      if (app.tagPrefix) {
        releases = releases.filter(r => r.tag_name.startsWith(app.tagPrefix!))
      }
      for (let r of releases) {
        if (r.prerelease) {
          prereleaseAfterlatest.push(r);
        } else {
          latestVersionFound = r;
          break;
        }
      }
      page++;
    }

    let selectedRelease;
    let checker: ReleaseChecker = app.shouldGetRelease || (async (_, release) => release.prerelease === false && release.draft === false);

    for (var r of [...prereleaseAfterlatest, latestVersionFound]) {
      if (await checker(query, r)) {
        selectedRelease = r;
        break;
      }
    }

    if (!selectedRelease) {
      return c.text('No update found', 404);
    }

    const resp: MeStoreReleaseInfo = {
      compulsory: app.isCompulsory?.call(selectedRelease) ?? false,
      version: selectedRelease.name!,
      releaseDate: selectedRelease.published_at!,
      releaseNote: selectedRelease.body_html,
      installerUrl: 
    }

    c.res.json

      .forEach((r) => {

      })






  })
  return;
}

