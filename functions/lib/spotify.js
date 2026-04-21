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
    if (cachedToken && now < tokenExpiresAt - 60000)
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
    var _a, _b;
    if (!request.auth)
        throw new https_1.HttpsError('unauthenticated', 'Login required');
    const query = (_b = (_a = request.data.query) === null || _a === void 0 ? void 0 : _a.trim()) !== null && _b !== void 0 ? _b : '';
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
    return data.artists.items.map((item) => {
        var _a, _b, _c, _d, _e, _f;
        return ({
            name: (_a = item.name) !== null && _a !== void 0 ? _a : 'Unknown Artist',
            imageUrl: (_d = (_c = (_b = item.images) === null || _b === void 0 ? void 0 : _b[0]) === null || _c === void 0 ? void 0 : _c.url) !== null && _d !== void 0 ? _d : '',
            genres: (_e = item.genres) !== null && _e !== void 0 ? _e : [],
            spotifyId: (_f = item.id) !== null && _f !== void 0 ? _f : null,
        });
    });
});
// ── Function 2 — Search tracks ────────────────────────────────────────────────
exports.searchSpotifyTracks = (0, https_1.onCall)({ region: 'europe-southwest1', secrets: [spotifyClientId, spotifyClientSecret] }, async (request) => {
    var _a, _b;
    if (!request.auth)
        throw new https_1.HttpsError('unauthenticated', 'Login required');
    const query = (_b = (_a = request.data.query) === null || _a === void 0 ? void 0 : _a.trim()) !== null && _b !== void 0 ? _b : '';
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
    return data.tracks.items.map((item) => {
        var _a, _b, _c, _d, _e, _f, _g, _h;
        return ({
            title: (_a = item.name) !== null && _a !== void 0 ? _a : 'Unknown',
            artist: (_d = (_c = (_b = item.artists) === null || _b === void 0 ? void 0 : _b[0]) === null || _c === void 0 ? void 0 : _c.name) !== null && _d !== void 0 ? _d : 'Unknown Artist',
            imageUrl: (_h = (_g = (_f = (_e = item.album) === null || _e === void 0 ? void 0 : _e.images) === null || _f === void 0 ? void 0 : _f[0]) === null || _g === void 0 ? void 0 : _g.url) !== null && _h !== void 0 ? _h : '',
            spotifyUrl: item.id ? `https://open.spotify.com/track/${item.id}` : '',
        });
    });
});
//# sourceMappingURL=spotify.js.map