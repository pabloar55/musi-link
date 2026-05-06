"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.searchSpotifyTracks = exports.searchSpotifyArtists = void 0;
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const v2_1 = require("firebase-functions/v2");
const spotifyClientId = (0, params_1.defineSecret)('SPOTIFY_CLIENT_ID');
const spotifyClientSecret = (0, params_1.defineSecret)('SPOTIFY_CLIENT_SECRET');
const lastFmApiKey = (0, params_1.defineSecret)('LASTFM_API_KEY');
const defaultSpotifyMarket = 'ES';
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
function sanitizeSpotifyMarket(value) {
    if (typeof value !== 'string')
        return defaultSpotifyMarket;
    const market = value.trim().toUpperCase();
    return /^[A-Z]{2}$/.test(market) ? market : defaultSpotifyMarket;
}
function spotifyArtistQuery(query) {
    return `artist:${query.replace(/"/g, '').trim()}`;
}
function normalizeArtistName(value) {
    return value
        .normalize('NFKD')
        .replace(/[\u0300-\u036f]/g, '')
        .toLowerCase()
        .replace(/'/g, '')
        .replace(/&/g, ' and ')
        .replace(/[^a-z0-9]+/g, ' ')
        .replace(/\s+/g, ' ')
        .trim();
}
function scoreArtistMatch(item, queryKey, queryTokens) {
    const nameKey = normalizeArtistName(item.name ?? '');
    if (!nameKey)
        return Number.NEGATIVE_INFINITY;
    let score = 0;
    if (nameKey === queryKey) {
        score += 350;
    }
    else if (nameKey.startsWith(`${queryKey} `)) {
        score += 300;
    }
    else if (nameKey.includes(queryKey)) {
        score += 180;
    }
    else {
        const nameTokens = new Set(nameKey.split(' '));
        const matchingTokens = queryTokens.filter((token) => nameTokens.has(token)).length;
        if (matchingTokens === 0)
            score -= 200;
        score += (matchingTokens / Math.max(queryTokens.length, 1)) * 120;
    }
    const popularity = Math.max(0, Math.min(item.popularity ?? 0, 100));
    const followers = Math.max(0, item.followers?.total ?? 0);
    const hasImage = Boolean(item.images?.[0]?.url);
    const hasGenres = Boolean(item.genres?.length);
    score += popularity * 9;
    score += Math.log10(followers + 1) * 45;
    if (hasImage)
        score += 30;
    if (hasGenres)
        score += 20;
    if (nameKey !== queryKey && popularity < 10 && followers < 10_000)
        score -= 250;
    if (!hasImage && popularity < 20)
        score -= 80;
    return score;
}
async function getLastFmGenres(artistName, apiKey) {
    try {
        const url = new URL('https://ws.audioscrobbler.com/2.0/');
        url.searchParams.set('method', 'artist.getTopTags');
        url.searchParams.set('artist', artistName);
        url.searchParams.set('api_key', apiKey);
        url.searchParams.set('format', 'json');
        url.searchParams.set('autocorrect', '1');
        const res = await fetch(url.toString());
        if (!res.ok)
            return [];
        const data = await res.json();
        const tags = data.toptags?.tag;
        if (!Array.isArray(tags))
            return [];
        return tags
            .filter((t) => t.count >= 10)
            .slice(0, 5)
            .map((t) => t.name.toLowerCase());
    }
    catch {
        return [];
    }
}
// ── Function 1 — Search artists ───────────────────────────────────────────────
exports.searchSpotifyArtists = (0, https_1.onCall)({ region: 'europe-southwest1', secrets: [spotifyClientId, spotifyClientSecret, lastFmApiKey] }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError('unauthenticated', 'Login required');
    const query = request.data.query?.trim() ?? '';
    const limit = Math.min(Number(request.data.limit) || 20, 50);
    if (!query)
        return [];
    const market = sanitizeSpotifyMarket(request.data.market);
    const spotifyLimit = Math.min(Math.max(limit * 3, 20), 50);
    const token = await getSpotifyToken(spotifyClientId.value(), spotifyClientSecret.value());
    const url = new URL('https://api.spotify.com/v1/search');
    url.searchParams.set('q', spotifyArtistQuery(query));
    url.searchParams.set('type', 'artist');
    url.searchParams.set('market', market);
    url.searchParams.set('limit', String(spotifyLimit));
    const res = await fetch(url.toString(), {
        headers: { Authorization: `Bearer ${token}` },
    });
    if (!res.ok) {
        v2_1.logger.error('Spotify searchArtists failed', { status: res.status, query });
        throw new https_1.HttpsError('internal', 'Spotify search failed');
    }
    const data = await res.json();
    const queryKey = normalizeArtistName(query);
    const queryTokens = queryKey.split(' ').filter(Boolean);
    const rankedItems = data.artists.items.map((item) => ({
        item,
        nameKey: normalizeArtistName(item.name ?? ''),
        score: scoreArtistMatch(item, queryKey, queryTokens),
    }));
    const hasExactMatch = rankedItems.some(({ nameKey }) => nameKey === queryKey);
    const filtered = rankedItems
        .filter(({ nameKey, score }) => {
        if (score <= 0)
            return false;
        if (!hasExactMatch)
            return true;
        return nameKey === queryKey || nameKey.startsWith(`${queryKey} `) || nameKey.includes(queryKey) || score >= 500;
    })
        .sort((a, b) => b.score - a.score)
        .slice(0, limit)
        .map(({ item }) => ({
        name: item.name ?? 'Unknown Artist',
        imageUrl: item.images?.[0]?.url ?? '',
        genres: item.genres ?? [],
        spotifyId: item.id ?? null,
    }));
    const apiKey = lastFmApiKey.value();
    return await Promise.all(filtered.map(async (artist) => {
        if (artist.genres.length > 0)
            return artist;
        const genres = await getLastFmGenres(artist.name, apiKey);
        return { ...artist, genres };
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