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