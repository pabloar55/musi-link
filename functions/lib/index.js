"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onFriendRequestAccepted = exports.onFriendRequest = exports.onUserMusicProfileChanged = exports.onNewMessage = exports.searchSpotifyTracks = exports.searchSpotifyArtists = void 0;
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
const recommendationIndexCollection = 'music_recommendation_index';
const recommendationsCollection = 'recommendations';
const maxRecommendationInputArtists = 10;
const maxRecommendationInputGenres = 10;
const maxIndexUsersPerToken = 80;
const maxStoredRecommendations = 100;
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
            android: Object.assign({ priority: 'high' }, (tag ? { notification: { tag } } : {})),
            apns: { payload: { aps: { sound: 'default' } } },
        });
    }
    catch (error) {
        const fcmError = error;
        if (fcmError.code === 'messaging/registration-token-not-registered') {
            await db.doc(`users/${recipientUid}`).update({ fcmToken: firestore_2.FieldValue.delete() });
            return;
        }
        v2_1.logger.error('sendNotification: unexpected FCM error', { recipientUid, error });
        throw error;
    }
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
        topArtistNames: stringList(data === null || data === void 0 ? void 0 : data.topArtistNames).slice(0, maxRecommendationInputArtists),
        topGenreNames: stringList(data === null || data === void 0 ? void 0 : data.topGenreNames).slice(0, maxRecommendationInputGenres),
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
function tokenKey(type, value) {
    return `${type}_${Buffer.from(value.toLowerCase(), 'utf8').toString('base64url')}`;
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
    const myArtists = new Set(myProfile.topArtistNames);
    const myGenres = new Set(myProfile.topGenreNames);
    const sharedArtistNames = candidate.topArtistNames.filter((artist) => myArtists.has(artist));
    const sharedGenreNames = candidate.topGenreNames.filter((genre) => myGenres.has(genre));
    if (sharedArtistNames.length === 0 && sharedGenreNames.length === 0)
        return null;
    const artistScore = Math.min(sharedArtistNames.length * 14, 70);
    const genreScore = Math.min(sharedGenreNames.length * 6, 30);
    return {
        uid: candidate.uid,
        score: artistScore + genreScore,
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
async function refreshRecommendations(uid, profile) {
    const tokens = musicTokens(profile);
    await deleteExistingRecommendations(uid);
    if (tokens.length === 0)
        return;
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
    const generatedAt = firestore_2.Timestamp.now();
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
    v2_1.logger.info('refreshRecommendations: generated recommendations', {
        uid,
        candidateCount: candidates.size,
        recommendationCount: recommendations.length,
    });
}
// ── Función 1 — Nuevo mensaje ─────────────────────────────────────────────────
exports.onNewMessage = (0, firestore_1.onDocumentCreated)({ document: 'chats/{chatId}/messages/{messageId}', region: 'europe-southwest1' }, async (event) => {
    var _a, _b, _c, _d;
    try {
        const message = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
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
            db.doc(`users/${recipientId}`).get(),
            db.doc(`users/${senderId}`).get(),
        ]);
        const fcmToken = (_b = recipientSnap.data()) === null || _b === void 0 ? void 0 : _b.fcmToken;
        const senderName = (_c = senderSnap.data()) === null || _c === void 0 ? void 0 : _c.displayName;
        if (!fcmToken || !senderName)
            return;
        await sendNotification(recipientId, fcmToken, { title: senderName, body: (_d = message.text) !== null && _d !== void 0 ? _d : '📎' }, {
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
// Rebuilds the current user's recommendation list when their music taste changes.
// Cost is bounded by 20 tokens * 80 index docs plus <= 100 recommendation writes.
exports.onUserMusicProfileChanged = (0, firestore_1.onDocumentUpdated)({ document: 'users/{userId}', region: 'europe-southwest1' }, async (event) => {
    var _a, _b;
    try {
        const before = readMusicProfile((_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data());
        const after = readMusicProfile((_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data());
        if (!musicProfileChanged(before, after))
            return;
        const uid = event.params.userId;
        await updateRecommendationIndex(uid, before, after);
        await refreshRecommendations(uid, after);
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
    var _a, _b, _c;
    try {
        const request = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
        if (!request)
            return;
        const senderId = request.senderId;
        const receiverId = request.receiverId;
        const [receiverSnap, senderSnap] = await Promise.all([
            db.doc(`users/${receiverId}`).get(),
            db.doc(`users/${senderId}`).get(),
        ]);
        const fcmToken = (_b = receiverSnap.data()) === null || _b === void 0 ? void 0 : _b.fcmToken;
        const senderName = (_c = senderSnap.data()) === null || _c === void 0 ? void 0 : _c.displayName;
        if (!fcmToken || !senderName)
            return;
        await sendNotification(receiverId, fcmToken, { title: 'MusiLink', body: `${senderName} sent you a friend request` }, { type: 'friend_request', senderId });
    }
    catch (error) {
        v2_1.logger.error('onFriendRequest: unhandled error', { requestId: event.params.requestId, error });
        throw error;
    }
});
// ── Función 4 — Solicitud de amistad aceptada ─────────────────────────────────
exports.onFriendRequestAccepted = (0, firestore_1.onDocumentUpdated)({ document: 'friend_requests/{requestId}', region: 'europe-southwest1' }, async (event) => {
    var _a, _b, _c, _d;
    try {
        const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
        const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
        if (!before || !after)
            return;
        if (before.status !== 'pending' || after.status !== 'accepted')
            return;
        const senderId = after.senderId;
        const receiverId = after.receiverId;
        const [senderSnap, receiverSnap] = await Promise.all([
            db.doc(`users/${senderId}`).get(),
            db.doc(`users/${receiverId}`).get(),
        ]);
        const fcmToken = (_c = senderSnap.data()) === null || _c === void 0 ? void 0 : _c.fcmToken;
        const accepterName = (_d = receiverSnap.data()) === null || _d === void 0 ? void 0 : _d.displayName;
        if (!fcmToken || !accepterName)
            return;
        await sendNotification(senderId, fcmToken, { title: 'MusiLink', body: `${accepterName} accepted your friend request` }, { type: 'friend_request_accepted', accepterId: receiverId });
        await db.doc(event.document).delete();
    }
    catch (error) {
        v2_1.logger.error('onFriendRequestAccepted: unhandled error', { requestId: event.params.requestId, error });
        throw error;
    }
});
//# sourceMappingURL=index.js.map