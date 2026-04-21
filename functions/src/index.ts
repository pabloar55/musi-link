import * as admin from 'firebase-admin';
import {
  onDocumentCreated,
  onDocumentUpdated,
} from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { FieldValue } from 'firebase-admin/firestore';

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ── Helper ────────────────────────────────────────────────────────────────────

async function sendNotification(
  recipientUid: string,
  token: string,
  notification: { title: string; body: string },
  data: Record<string, string>,
  // Notifications with the same tag replace each other in the drawer,
  // keeping one entry per conversation instead of an unbounded stack.
  tag?: string,
): Promise<void> {
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
  } catch (error: unknown) {
    const fcmError = error as { code?: string };
    if (fcmError.code === 'messaging/registration-token-not-registered') {
      await db.doc(`users/${recipientUid}`).update({ fcmToken: FieldValue.delete() });
      return;
    }
    logger.error('sendNotification: unexpected FCM error', { recipientUid, error });
    throw error;
  }
}

// ── Función 1 — Nuevo mensaje ─────────────────────────────────────────────────

export const onNewMessage = onDocumentCreated(
  { document: 'chats/{chatId}/messages/{messageId}', region: 'europe-southwest1' },
  async (event) => {
    try {
      const message = event.data?.data();
      if (!message) return;

      const chatId = event.params.chatId;
      const senderId = message.senderId as string;

      const chatSnap = await db.doc(`chats/${chatId}`).get();
      const chatData = chatSnap.data();
      if (!chatData) return;

      const participants = chatData.participants as string[];
      if (participants.length !== 2) return;
      const recipientId = participants.find((p) => p !== senderId);
      if (!recipientId) return;

      const [recipientSnap, senderSnap] = await Promise.all([
        db.doc(`users/${recipientId}`).get(),
        db.doc(`users/${senderId}`).get(),
      ]);

      const fcmToken = recipientSnap.data()?.fcmToken as string | undefined;
      const senderName = senderSnap.data()?.displayName as string | undefined;
      if (!fcmToken || !senderName) return;

      await sendNotification(
        recipientId,
        fcmToken,
        { title: senderName, body: (message.text as string | undefined) ?? '📎' },
        {
          type: 'new_message',
          chatId,
          otherUserId: senderId,
          otherUserName: senderName,
        },
        chatId,
      );
    } catch (error) {
      logger.error('onNewMessage: unhandled error', { chatId: event.params.chatId, error });
      throw error;
    }
  },
);

// ── Función 2 — Nueva solicitud de amistad ────────────────────────────────────

export const onFriendRequest = onDocumentCreated(
  { document: 'friend_requests/{requestId}', region: 'europe-southwest1' },
  async (event) => {
    try {
      const request = event.data?.data();
      if (!request) return;

      const senderId = request.senderId as string;
      const receiverId = request.receiverId as string;

      const [receiverSnap, senderSnap] = await Promise.all([
        db.doc(`users/${receiverId}`).get(),
        db.doc(`users/${senderId}`).get(),
      ]);

      const fcmToken = receiverSnap.data()?.fcmToken as string | undefined;
      const senderName = senderSnap.data()?.displayName as string | undefined;
      if (!fcmToken || !senderName) return;

      await sendNotification(
        receiverId,
        fcmToken,
        { title: 'MusiLink', body: `${senderName} sent you a friend request` },
        { type: 'friend_request', senderId },
      );
    } catch (error) {
      logger.error('onFriendRequest: unhandled error', { requestId: event.params.requestId, error });
      throw error;
    }
  },
);

// ── Función 3 — Solicitud de amistad aceptada ─────────────────────────────────

export const onFriendRequestAccepted = onDocumentUpdated(
  { document: 'friend_requests/{requestId}', region: 'europe-southwest1' },
  async (event) => {
    try {
      const before = event.data?.before.data();
      const after = event.data?.after.data();
      if (!before || !after) return;
      if (before.status !== 'pending' || after.status !== 'accepted') return;

      const senderId = after.senderId as string;
      const receiverId = after.receiverId as string;

      const [senderSnap, receiverSnap] = await Promise.all([
        db.doc(`users/${senderId}`).get(),
        db.doc(`users/${receiverId}`).get(),
      ]);

      const fcmToken = senderSnap.data()?.fcmToken as string | undefined;
      const accepterName = receiverSnap.data()?.displayName as string | undefined;
      if (!fcmToken || !accepterName) return;

      await sendNotification(
        senderId,
        fcmToken,
        { title: 'MusiLink', body: `${accepterName} accepted your friend request` },
        { type: 'friend_request_accepted', accepterId: receiverId },
      );

      await db.doc(event.document).delete();
    } catch (error) {
      logger.error('onFriendRequestAccepted: unhandled error', { requestId: event.params.requestId, error });
      throw error;
    }
  },
);
