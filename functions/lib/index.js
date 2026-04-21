"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onFriendRequestAccepted = exports.onFriendRequest = exports.onNewMessage = void 0;
const admin = require("firebase-admin");
const firestore_1 = require("firebase-functions/v2/firestore");
const v2_1 = require("firebase-functions/v2");
const firestore_2 = require("firebase-admin/firestore");
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
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
// ── Función 2 — Nueva solicitud de amistad ────────────────────────────────────
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
// ── Función 3 — Solicitud de amistad aceptada ─────────────────────────────────
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