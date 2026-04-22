"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.searchSpotifyTracks = exports.searchSpotifyArtists = void 0;
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const v2_1 = require("firebase-functions/v2");
const spotifyClientId = (0, params_1.defineSecret)('SPOTIFY_CLIENT_ID');
const spotifyClientSecret = (0, params_1.defineSecret)('SPOTIFY_CLIENT_SECRET');
// Module-level cache — reused across warm instances (Spotify tokens last 3600 s).
let cachedToken = null;
let tokenExpiresAt = 0;
async function getSpotifyToken(clientId, clientSecret) {
    const now = Date.now();
    if (cachedToken && now < tokenExpiresAt - 60_000)
        return cachedToken;
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
        v2_1.logger.error('Spotify token request failed', { status: res.status });
        throw new https_1.HttpsError('internal', 'Failed to obtain Spotify token');
    }
    const data = await res.json();
    cachedToken = data.access_token;
    tokenExpiresAt = now + data.expires_in * 1000;
    return cachedToken;
}
// ── Function 1 — Search artists ───────────────────────────────────────────────
exports.searchSpotifyArtists = (0, https_1.onCall)({ region: 'europe-southwest1', secrets: [spotifyClientId, spotifyClientSecret] }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError('unauthenticated', 'Login required');
    const query = request.data.query?.trim() ?? '';
    const limit = Math.min(Number(request.data.limit) || 20, 50);
    if (!query)
        return [];
    const token = await getSpotifyToken(spotifyClientId.value(), spotifyClientSecret.value());
    const url = new URL('https://api.spotify.com/v1/search');
    url.searchParams.set('q', query);
    url.searchParams.set('type', 'artist');
    url.searchParams.set('limit', String(limit));
    const res = await fetch(url.toString(), {
        headers: { Authorization: `Bearer ${token}` },
    });
    if (!res.ok) {
        v2_1.logger.error('Spotify searchArtists failed', { status: res.status, query });
        throw new https_1.HttpsError('internal', 'Spotify search failed');
    }
    const data = await res.json();
    return data.artists.items.map((item) => ({
        name: item.name ?? 'Unknown Artist',
        imageUrl: item.images?.[0]?.url ?? '',
        genres: item.genres ?? [],
        spotifyId: item.id ?? null,
    }));
});
// ── Function 2 — Search tracks ────────────────────────────────────────────────
exports.searchSpotifyTracks = (0, https_1.onCall)({ region: 'europe-southwest1', secrets: [spotifyClientId, spotifyClientSecret] }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError('unauthenticated', 'Login required');
    const query = request.data.query?.trim() ?? '';
    const limit = Math.min(Number(request.data.limit) || 20, 50);
    if (!query)
        return [];
    const token = await getSpotifyToken(spotifyClientId.value(), spotifyClientSecret.value());
    const url = new URL('https://api.spotify.com/v1/search');
    url.searchParams.set('q', query);
    url.searchParams.set('type', 'track');
    url.searchParams.set('limit', String(limit));
    const res = await fetch(url.toString(), {
        headers: { Authorization: `Bearer ${token}` },
    });
    if (!res.ok) {
        v2_1.logger.error('Spotify searchTracks failed', { status: res.status, query });
        throw new https_1.HttpsError('internal', 'Spotify search failed');
    }
    const data = await res.json();
    return data.tracks.items.map((item) => ({
        title: item.name ?? 'Unknown',
        artist: item.artists?.[0]?.name ?? 'Unknown Artist',
        imageUrl: item.album?.images?.[0]?.url ?? '',
        spotifyUrl: item.id ? `https://open.spotify.com/track/${item.id}` : '',
    }));
});
//# sourceMappingURL=spotify.js.map