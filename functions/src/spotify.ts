import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';
import { logger } from 'firebase-functions/v2';

const spotifyClientId = defineSecret('SPOTIFY_CLIENT_ID');
const spotifyClientSecret = defineSecret('SPOTIFY_CLIENT_SECRET');

// Module-level cache — reused across warm instances (Spotify tokens last 3600 s).
let cachedToken: string | null = null;
let tokenExpiresAt = 0;

async function getSpotifyToken(clientId: string, clientSecret: string): Promise<string> {
  const now = Date.now();
  if (cachedToken && now < tokenExpiresAt - 60_000) return cachedToken;

  const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');
  const res = await fetch('https://accounts.spotify.com/api/token', {
    method: 'POST',
    headers: {
      Authorization: `Basic ${credentials}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: 'grant_type=client_credentials',
  });

  if (!res.ok) {
    logger.error('Spotify token request failed', { status: res.status });
    throw new HttpsError('internal', 'Failed to obtain Spotify token');
  }

  const data = await res.json() as { access_token: string; expires_in: number };
  cachedToken = data.access_token;
  tokenExpiresAt = now + data.expires_in * 1000;
  return cachedToken;
}

// ── Exported types (mirror the Flutter app.Artist / app.Track models) ─────────

interface ArtistResult {
  name: string;
  imageUrl: string;
  genres: string[];
  spotifyId: string | null;
}

interface TrackResult {
  title: string;
  artist: string;
  imageUrl: string;
  spotifyUrl: string;
}

// ── Function 1 — Search artists ───────────────────────────────────────────────

export const searchSpotifyArtists = onCall(
  { region: 'europe-southwest1', secrets: [spotifyClientId, spotifyClientSecret] },
  async (request): Promise<ArtistResult[]> => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Login required');

    const query = (request.data.query as string | undefined)?.trim() ?? '';
    const limit = Math.min(Number(request.data.limit) || 20, 50);
    if (!query) return [];

    const token = await getSpotifyToken(spotifyClientId.value(), spotifyClientSecret.value());

    const url = new URL('https://api.spotify.com/v1/search');
    url.searchParams.set('q', query);
    url.searchParams.set('type', 'artist');
    url.searchParams.set('limit', String(limit));

    const res = await fetch(url.toString(), {
      headers: { Authorization: `Bearer ${token}` },
    });

    if (!res.ok) {
      logger.error('Spotify searchArtists failed', { status: res.status, query });
      throw new HttpsError('internal', 'Spotify search failed');
    }

    const data = await res.json() as {
      artists: {
        items: Array<{
          id: string;
          name: string;
          genres: string[];
          images: Array<{ url: string }>;
        }>;
      };
    };

    return data.artists.items.map((item) => ({
      name: item.name ?? 'Unknown Artist',
      imageUrl: item.images?.[0]?.url ?? '',
      genres: item.genres ?? [],
      spotifyId: item.id ?? null,
    }));
  },
);

// ── Function 2 — Search tracks ────────────────────────────────────────────────

export const searchSpotifyTracks = onCall(
  { region: 'europe-southwest1', secrets: [spotifyClientId, spotifyClientSecret] },
  async (request): Promise<TrackResult[]> => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Login required');

    const query = (request.data.query as string | undefined)?.trim() ?? '';
    const limit = Math.min(Number(request.data.limit) || 20, 50);
    if (!query) return [];

    const token = await getSpotifyToken(spotifyClientId.value(), spotifyClientSecret.value());

    const url = new URL('https://api.spotify.com/v1/search');
    url.searchParams.set('q', query);
    url.searchParams.set('type', 'track');
    url.searchParams.set('limit', String(limit));

    const res = await fetch(url.toString(), {
      headers: { Authorization: `Bearer ${token}` },
    });

    if (!res.ok) {
      logger.error('Spotify searchTracks failed', { status: res.status, query });
      throw new HttpsError('internal', 'Spotify search failed');
    }

    const data = await res.json() as {
      tracks: {
        items: Array<{
          id: string;
          name: string;
          artists: Array<{ name: string }>;
          album: { images: Array<{ url: string }> };
        }>;
      };
    };

    return data.tracks.items.map((item) => ({
      title: item.name ?? 'Unknown',
      artist: item.artists?.[0]?.name ?? 'Unknown Artist',
      imageUrl: item.album?.images?.[0]?.url ?? '',
      spotifyUrl: item.id ? `https://open.spotify.com/track/${item.id}` : '',
    }));
  },
);
