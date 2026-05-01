"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onFriendRequestAccepted = exports.onFriendRequest = exports.onUserMusicProfileChanged = exports.onUserMusicProfileCreated = exports.onNewMessage = exports.searchSpotifyTracks = exports.searchSpotifyArtists = void 0;
const admin = require("firebase-admin");
const firestore_1 = require("firebase-functions/v2/firestore");
const v2_1 = require("firebase-functions/v2");
const firestore_2 = require("firebase-admin/firestore");
var spotify_1 = require("./spotify");
Object.defineProperty(exports, "searchSpotifyArtists", { enumerable: true, get: function () { return spotify_1.searchSpotifyArtists; } });
Object.defineProperty(exports, "searchSpotifyTracks", { enumerable: true, get: function () { return spotify_1.searchSpotifyTracks; } });
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
const userPrivateCollection = 'user_private';
const recommendationIndexCollection = 'music_recommendation_index';
const recommendationsCollection = 'recommendations';
const maxRecommendationInputArtists = 15;
const maxRecommendationInputGenres = 10;
const maxIndexUsersPerToken = 80;
const maxStoredRecommendations = 100;
const maxReciprocalRecommendationUsers = 100;
const artistScoreWeight = 70;
const genreScoreWeight = 30;
const artistEvidenceTarget = 7;
const genreEvidenceTarget = 4;
const defaultLocale = 'en';
const supportedLocales = new Set(['en', 'es', 'fr']);
const notificationText = {
    friendRequest: {
        en: (name) => `${name} sent you a friend request`,
        es: (name) => `${name} te envió una solicitud de amistad`,
        fr: (name) => `${name} vous a envoyé une demande d'amitié`,
    },
    friendRequestAccepted: {
        en: (name) => `${name} accepted your friend request`,
        es: (name) => `${name} aceptó tu solicitud de amistad`,
        fr: (name) => `${name} a accepté votre demande d'amitié`,
    },
};
// ── Helper ────────────────────────────────────────────────────────────────────
async function sendNotification(recipientUid, token, notification, data, 
// Notifications with the same tag replace each other in the drawer,
// keeping one entry per conversation instead of an unbounded stack.
tag) {
    try {
        await messaging.send({
            token,
            notification,
            data,
            android: {
                priority: 'high',
                ...(tag ? { notification: { tag } } : {}),
            },
            apns: { payload: { aps: { sound: 'default' } } },
        });
    }
    catch (error) {
        const fcmError = error;
        if (fcmError.code === 'messaging/registration-token-not-registered') {
            await db.doc(`${userPrivateCollection}/${recipientUid}`).update({ fcmToken: firestore_2.FieldValue.delete() });
            return;
        }
        v2_1.logger.error('sendNotification: unexpected FCM error', { recipientUid, error });
        throw error;
    }
}
function preferredLocale(data) {
    const locale = data?.preferredLocale;
    if (typeof locale !== 'string')
        return defaultLocale;
    const languageCode = locale.toLowerCase().split(/[-_]/)[0];
    return supportedLocales.has(languageCode)
        ? languageCode
        : defaultLocale;
}
function stringList(value) {
    if (!Array.isArray(value))
        return [];
    return value
        .filter((item) => typeof item === 'string')
        .map((item) => item.trim())
        .filter((item) => item.length > 0);
}
function readMusicProfile(data) {
    return {
        topArtistNames: stringList(data?.topArtistNames).slice(0, maxRecommendationInputArtists),
        topGenreNames: stringList(data?.topGenreNames).slice(0, maxRecommendationInputGenres),
    };
}
function sameStringList(left, right) {
    if (left.length !== right.length)
        return false;
    return left.every((value, index) => value === right[index]);
}
function musicProfileChanged(before, after) {
    return !sameStringList(before.topArtistNames, after.topArtistNames) ||
        !sameStringList(before.topGenreNames, after.topGenreNames);
}
function timestampMillis(value) {
    return value instanceof firestore_2.Timestamp ? value.toMillis() : undefined;
}
function recommendationRefreshRequested(before, after) {
    const beforeMillis = timestampMillis(before?.recommendationsRefreshRequestedAt);
    const afterMillis = timestampMillis(after?.recommendationsRefreshRequestedAt);
    return afterMillis !== undefined && afterMillis !== beforeMillis;
}
function tokenKey(type, value) {
    return `${type}_${Buffer.from(value.toLowerCase(), 'utf8').toString('base64url')}`;
}
function normalizedMusicKey(value) {
    return value.trim().toLowerCase();
}
function uniqueMusicNames(values) {
    const namesByKey = new Map();
    for (const value of values) {
        const trimmed = value.trim();
        const key = normalizedMusicKey(trimmed);
        if (key.length > 0 && !namesByKey.has(key))
            namesByKey.set(key, trimmed);
    }
    return [...namesByKey.values()];
}
function similarityScore(sharedCount, leftCount, rightCount, evidenceTarget, weight) {
    if (sharedCount === 0)
        return 0;
    const comparableCount = Math.min(leftCount, rightCount);
    const coverage = comparableCount === 0 ? 0 : sharedCount / comparableCount;
    const evidence = Math.min(sharedCount / evidenceTarget, 1);
    return Math.max(coverage, evidence) * weight;
}
function musicTokens(profile) {
    return [
        ...profile.topArtistNames.map((value) => ({
            key: tokenKey('artist', value),
            type: 'artist',
            value,
        })),
        ...profile.topGenreNames.map((value) => ({
            key: tokenKey('genre', value),
            type: 'genre',
            value,
        })),
    ];
}
function indexUserRef(token, uid) {
    return db
        .collection(recommendationIndexCollection)
        .doc(token.key)
        .collection('users')
        .doc(uid);
}
function userDocRef(uid) {
    return db.collection('users').doc(uid);
}
async function commitBatches(operations) {
    const batchSize = 400;
    for (let i = 0; i < operations.length; i += batchSize) {
        const batch = db.batch();
        operations.slice(i, i + batchSize).forEach((operation) => operation(batch));
        await batch.commit();
    }
}
async function updateRecommendationIndex(uid, before, after) {
    const previousTokens = new Map(musicTokens(before).map((token) => [token.key, token]));
    const nextTokens = new Map(musicTokens(after).map((token) => [token.key, token]));
    const now = firestore_2.FieldValue.serverTimestamp();
    const operations = [];
    for (const [key, token] of previousTokens) {
        if (!nextTokens.has(key)) {
            operations.push((batch) => batch.delete(indexUserRef(token, uid)));
        }
    }
    for (const token of nextTokens.values()) {
        operations.push((batch) => batch.set(indexUserRef(token, uid), {
            uid,
            tokenType: token.type,
            tokenValue: token.value,
            topArtistNames: after.topArtistNames,
            topGenreNames: after.topGenreNames,
            updatedAt: now,
        }));
    }
    if (operations.length > 0)
        await commitBatches(operations);
}
function calculateRecommendation(myProfile, candidate) {
    const myArtistNames = uniqueMusicNames(myProfile.topArtistNames);
    const candidateArtistNames = uniqueMusicNames(candidate.topArtistNames);
    const myGenreNames = uniqueMusicNames(myProfile.topGenreNames);
    const candidateGenreNames = uniqueMusicNames(candidate.topGenreNames);
    const myArtists = new Set(myArtistNames.map(normalizedMusicKey));
    const myGenres = new Set(myGenreNames.map(normalizedMusicKey));
    const sharedArtistNames = candidateArtistNames.filter((artist) => myArtists.has(normalizedMusicKey(artist)));
    const sharedGenreNames = candidateGenreNames.filter((genre) => myGenres.has(normalizedMusicKey(genre)));
    if (sharedArtistNames.length === 0 && sharedGenreNames.length === 0)
        return null;
    const artistScore = similarityScore(sharedArtistNames.length, myArtistNames.length, candidateArtistNames.length, artistEvidenceTarget, artistScoreWeight);
    const genreScore = similarityScore(sharedGenreNames.length, myGenreNames.length, candidateGenreNames.length, genreEvidenceTarget, genreScoreWeight);
    return {
        uid: candidate.uid,
        score: Math.round(artistScore + genreScore),
        sharedArtistNames,
        sharedGenreNames,
    };
}
async function deleteExistingRecommendations(uid) {
    const existing = await db
        .collection(`users/${uid}/${recommendationsCollection}`)
        .get();
    if (existing.empty)
        return;
    await commitBatches(existing.docs.map((doc) => (batch) => batch.delete(doc.ref)));
}
async function deleteStaleRecommendations(uid, currentRecommendationIds) {
    const existing = await db
        .collection(`users/${uid}/${recommendationsCollection}`)
        .get();
    const staleDocs = existing.docs.filter((doc) => !currentRecommendationIds.has(doc.id));
    if (staleDocs.length === 0)
        return;
    await commitBatches(staleDocs.map((doc) => (batch) => batch.delete(doc.ref)));
}
async function refreshRecommendations(uid, profile) {
    const tokens = musicTokens(profile);
    const generatedAt = firestore_2.Timestamp.now();
    if (tokens.length === 0) {
        await deleteExistingRecommendations(uid);
        await userDocRef(uid).update({ recommendationsGeneratedAt: generatedAt });
        return;
    }
    const snapshots = await Promise.all(tokens.map((token) => db
        .collection(recommendationIndexCollection)
        .doc(token.key)
        .collection('users')
        .orderBy('updatedAt', 'desc')
        .limit(maxIndexUsersPerToken)
        .get()));
    const candidates = new Map();
    for (const snapshot of snapshots) {
        for (const doc of snapshot.docs) {
            if (doc.id === uid || candidates.has(doc.id))
                continue;
            const data = doc.data();
            candidates.set(doc.id, {
                uid: doc.id,
                topArtistNames: stringList(data.topArtistNames),
                topGenreNames: stringList(data.topGenreNames),
            });
        }
    }
    const recommendations = [...candidates.values()]
        .map((candidate) => calculateRecommendation(profile, candidate))
        .filter((result) => result !== null)
        .sort((a, b) => b.score - a.score)
        .slice(0, maxStoredRecommendations);
    const recommendationIds = new Set(recommendations.map((recommendation) => recommendation.uid));
    await commitBatches(recommendations.map((recommendation, index) => (batch) => {
        batch.set(db.doc(`users/${uid}/${recommendationsCollection}/${recommendation.uid}`), {
            userId: recommendation.uid,
            score: recommendation.score,
            sharedArtistNames: recommendation.sharedArtistNames,
            sharedGenreNames: recommendation.sharedGenreNames,
            rank: index + 1,
            generatedAt,
        });
    }));
    await deleteStaleRecommendations(uid, recommendationIds);
    await userDocRef(uid).update({ recommendationsGeneratedAt: generatedAt });
    v2_1.logger.info('refreshRecommendations: generated recommendations', {
        uid,
        candidateCount: candidates.size,
        recommendationCount: recommendations.length,
    });
}
async function matchingCandidateProfiles(uid, profiles) {
    const tokenMap = new Map();
    profiles
        .flatMap((profile) => musicTokens(profile))
        .forEach((token) => tokenMap.set(token.key, token));
    const tokens = [...tokenMap.values()];
    if (tokens.length === 0)
        return new Map();
    const snapshots = await Promise.all(tokens.map((token) => db
        .collection(recommendationIndexCollection)
        .doc(token.key)
        .collection('users')
        .orderBy('updatedAt', 'desc')
        .limit(maxIndexUsersPerToken)
        .get()));
    const candidates = new Map();
    for (const snapshot of snapshots) {
        for (const doc of snapshot.docs) {
            if (doc.id === uid || candidates.has(doc.id))
                continue;
            const data = doc.data();
            candidates.set(doc.id, {
                uid: doc.id,
                topArtistNames: stringList(data.topArtistNames),
                topGenreNames: stringList(data.topGenreNames),
            });
            if (candidates.size >= maxReciprocalRecommendationUsers)
                return candidates;
        }
    }
    return candidates;
}
async function updateReciprocalRecommendations(uid, profile, candidates) {
    const generatedAt = firestore_2.Timestamp.now();
    await commitBatches([...candidates.values()].map((candidate) => (batch) => {
        const recommendation = calculateRecommendation(candidate, {
            uid,
            topArtistNames: profile.topArtistNames,
            topGenreNames: profile.topGenreNames,
        });
        const ref = db.doc(`users/${candidate.uid}/${recommendationsCollection}/${uid}`);
        if (recommendation === null) {
            batch.delete(ref);
            return;
        }
        batch.set(ref, {
            userId: uid,
            score: recommendation.score,
            sharedArtistNames: recommendation.sharedArtistNames,
            sharedGenreNames: recommendation.sharedGenreNames,
            rank: 0,
            generatedAt,
        });
    }));
    v2_1.logger.info('updateReciprocalRecommendations: updated candidates', {
        uid,
        candidateCount: candidates.size,
    });
}
async function rebuildMusicRecommendations(uid, before, after, options = {}) {
    const profileChanged = musicProfileChanged(before, after);
    const forceSelfRefresh = options.forceSelfRefresh === true;
    if (!profileChanged && !forceSelfRefresh)
        return;
    const reciprocalCandidates = profileChanged || forceSelfRefresh
        ? await matchingCandidateProfiles(uid, [before, after])
        : new Map();
    if (profileChanged || forceSelfRefresh)
        await updateRecommendationIndex(uid, before, after);
    await refreshRecommendations(uid, after);
    if (profileChanged || forceSelfRefresh) {
        await updateReciprocalRecommendations(uid, after, reciprocalCandidates);
    }
}
// ── Función 1 — Nuevo mensaje ─────────────────────────────────────────────────
exports.onNewMessage = (0, firestore_1.onDocumentCreated)({ document: 'chats/{chatId}/messages/{messageId}', region: 'europe-southwest1' }, async (event) => {
    try {
        const message = event.data?.data();
        if (!message)
            return;
        const chatId = event.params.chatId;
        const senderId = message.senderId;
        const chatSnap = await db.doc(`chats/${chatId}`).get();
        const chatData = chatSnap.data();
        if (!chatData)
            return;
        const participants = chatData.participants;
        if (participants.length !== 2)
            return;
        const recipientId = participants.find((p) => p !== senderId);
        if (!recipientId)
            return;
        const [recipientSnap, senderSnap] = await Promise.all([
            db.doc(`${userPrivateCollection}/${recipientId}`).get(),
            db.doc(`users/${senderId}`).get(),
        ]);
        const fcmToken = recipientSnap.data()?.fcmToken;
        const senderName = senderSnap.data()?.displayName;
        if (!fcmToken || !senderName)
            return;
        await sendNotification(recipientId, fcmToken, { title: senderName, body: message.text ?? '📎' }, {
            type: 'new_message',
            chatId,
            otherUserId: senderId,
            otherUserName: senderName,
        }, chatId);
    }
    catch (error) {
        v2_1.logger.error('onNewMessage: unhandled error', { chatId: event.params.chatId, error });
        throw error;
    }
});
// ── Función 2 — Recomendaciones musicales ─────────────────────────────────────
// Rebuilds recommendation lists when a user's music taste changes.
// The changed user's full list is rebuilt, and matching existing users get a
// reciprocal recommendation upsert/delete so discovery does not wait for them
// to edit their own profile.
exports.onUserMusicProfileCreated = (0, firestore_1.onDocumentCreated)({ document: 'users/{userId}', region: 'europe-southwest1' }, async (event) => {
    try {
        const after = readMusicProfile(event.data?.data());
        await rebuildMusicRecommendations(event.params.userId, {
            topArtistNames: [],
            topGenreNames: [],
        }, after);
    }
    catch (error) {
        v2_1.logger.error('onUserMusicProfileCreated: unhandled error', {
            userId: event.params.userId,
            error,
        });
        throw error;
    }
});
exports.onUserMusicProfileChanged = (0, firestore_1.onDocumentUpdated)({ document: 'users/{userId}', region: 'europe-southwest1' }, async (event) => {
    try {
        const beforeData = event.data?.before.data();
        const afterData = event.data?.after.data();
        const before = readMusicProfile(beforeData);
        const after = readMusicProfile(afterData);
        await rebuildMusicRecommendations(event.params.userId, before, after, {
            forceSelfRefresh: recommendationRefreshRequested(beforeData, afterData),
        });
    }
    catch (error) {
        v2_1.logger.error('onUserMusicProfileChanged: unhandled error', {
            userId: event.params.userId,
            error,
        });
        throw error;
    }
});
// ── Función 3 — Nueva solicitud de amistad ────────────────────────────────────
exports.onFriendRequest = (0, firestore_1.onDocumentCreated)({ document: 'friend_requests/{requestId}', region: 'europe-southwest1' }, async (event) => {
    try {
        const request = event.data?.data();
        if (!request)
            return;
        if (request.status !== 'pending')
            return;
        const senderId = request.senderId;
        const receiverId = request.receiverId;
        const [receiverSnap, senderSnap] = await Promise.all([
            db.doc(`${userPrivateCollection}/${receiverId}`).get(),
            db.doc(`users/${senderId}`).get(),
        ]);
        const receiver = receiverSnap.data();
        const fcmToken = receiver?.fcmToken;
        const senderName = senderSnap.data()?.displayName;
        if (!fcmToken || !senderName)
            return;
        const locale = preferredLocale(receiver);
        await sendNotification(receiverId, fcmToken, { title: 'MusiLink', body: notificationText.friendRequest[locale](senderName) }, { type: 'friend_request', senderId });
    }
    catch (error) {
        v2_1.logger.error('onFriendRequest: unhandled error', { requestId: event.params.requestId, error });
        throw error;
    }
});
// ── Función 4 — Solicitud de amistad aceptada ─────────────────────────────────
exports.onFriendRequestAccepted = (0, firestore_1.onDocumentUpdated)({ document: 'friend_requests/{requestId}', region: 'europe-southwest1' }, async (event) => {
    try {
        const before = event.data?.before.data();
        const after = event.data?.after.data();
        if (!before || !after)
            return;
        if (before.status !== 'pending' || after.status !== 'accepted')
            return;
        const senderId = after.senderId;
        const receiverId = after.receiverId;
        const [senderSnap, receiverSnap] = await Promise.all([
            db.doc(`${userPrivateCollection}/${senderId}`).get(),
            db.doc(`users/${receiverId}`).get(),
        ]);
        const sender = senderSnap.data();
        const fcmToken = sender?.fcmToken;
        const accepterName = receiverSnap.data()?.displayName;
        if (!fcmToken || !accepterName)
            return;
        const locale = preferredLocale(sender);
        await sendNotification(senderId, fcmToken, { title: 'MusiLink', body: notificationText.friendRequestAccepted[locale](accepterName) }, { type: 'friend_request_accepted', accepterId: receiverId });
        await db.doc(event.document).delete();
    }
    catch (error) {
        v2_1.logger.error('onFriendRequestAccepted: unhandled error', { requestId: event.params.requestId, error });
        throw error;
    }
});
//# sourceMappingURL=index.js.map