import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { logger } from 'firebase-functions/v2';

const lastFmApiKey = defineSecret('LASTFM_API_KEY');

const collabPattern = /(&|feat\.?|ft\.?)/i;

export const getSimilarArtists = onCall(
  { region: 'europe-southwest1', secrets: [lastFmApiKey] },
  async (request): Promise<string[]> => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Login required');

    const artistName = (request.data.artistName as string | undefined)?.trim() ?? '';
    const limit = Math.min(Number(request.data.limit) || 10, 50);
    if (!artistName) return [];

    const url = new URL('https://ws.audioscrobbler.com/2.0/');
    url.searchParams.set('method', 'artist.getSimilar');
    url.searchParams.set('artist', artistName);
    url.searchParams.set('api_key', lastFmApiKey.value());
    url.searchParams.set('format', 'json');
    url.searchParams.set('limit', String(limit));
    url.searchParams.set('autocorrect', '1');

    const res = await fetch(url.toString());
    if (!res.ok) {
      logger.error('Last.fm getSimilar failed', { status: res.status, artistName });
      throw new HttpsError('internal', 'Last.fm request failed');
    }

    const data = await res.json() as {
      similarartists?: { artist?: Array<{ name: string }> };
    };

    const artists = data.similarartists?.artist;
    if (!Array.isArray(artists)) return [];

    return artists
      .map((a) => a.name ?? '')
      .filter((name) => name && !collabPattern.test(name))
      .slice(0, limit);
  },
);
