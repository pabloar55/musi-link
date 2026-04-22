import * as admin from 'firebase-admin';
import {
  onDocumentCreated,
  onDocumentUpdated,
} from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions/v2';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
export { searchSpotifyArtists, searchSpotifyTracks } from './spotify';

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

const recommendationIndexCollection = 'music_recommendation_index';
const recommendationsCollection = 'recommendations';
const maxRecommendationInputArtists = 10;
const maxRecommendationInputGenres = 10;
const maxIndexUsersPerToken = 80;
const maxStoredRecommendations = 100;
const maxReciprocalRecommendationUsers = 100;

type TokenType = 'artist' | 'genre';
type SupportedLocale = 'en' | 'es' | 'fr';

interface MusicToken {
  key: string;
  type: TokenType;
  value: string;
}

interface UserMusicProfile {
  topArtistNames: string[];
  topGenreNames: string[];
}

interface CandidateProfile extends UserMusicProfile {
  uid: string;
}

interface RecommendationResult {
  uid: string;
  score: number;
  sharedArtistNames: string[];
  sharedGenreNames: string[];
}

const defaultLocale: SupportedLocale = 'en';
const supportedLocales = new Set<SupportedLocale>(['en', 'es', 'fr']);

const notificationText = {
  friendRequest: {
    en: (name: string) => `${name} sent you a friend request`,
    es: (name: string) => `${name} te envió una solicitud de amistad`,
    fr: (name: string) => `${name} vous a envoyé une demande d'amitié`,
  },
  friendRequestAccepted: {
    en: (name: string) => `${name} accepted your friend request`,
    es: (name: string) => `${name} aceptó tu solicitud de amistad`,
    fr: (name: string) => `${name} a accepté votre demande d'amitié`,
  },
} satisfies Record<string, Record<SupportedLocale, (name: string) => string>>;

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

function preferredLocale(data: admin.firestore.DocumentData | undefined): SupportedLocale {
  const locale = data?.preferredLocale;
  if (typeof locale !== 'string') return defaultLocale;

  const languageCode = locale.toLowerCase().split(/[-_]/)[0];
  return supportedLocales.has(languageCode as SupportedLocale)
    ? languageCode as SupportedLocale
    : defaultLocale;
}

function stringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .filter((item): item is string => typeof item === 'string')
    .map((item) => item.trim())
    .filter((item) => item.length > 0);
}

function readMusicProfile(data: admin.firestore.DocumentData | undefined): UserMusicProfile {
  return {
    topArtistNames: stringList(data?.topArtistNames).slice(0, maxRecommendationInputArtists),
    topGenreNames: stringList(data?.topGenreNames).slice(0, maxRecommendationInputGenres),
  };
}

function sameStringList(left: string[], right: string[]): boolean {
  if (left.length !== right.length) return false;
  return left.every((value, index) => value === right[index]);
}

function musicProfileChanged(
  before: UserMusicProfile,
  after: UserMusicProfile,
): boolean {
  return !sameStringList(before.topArtistNames, after.topArtistNames) ||
    !sameStringList(before.topGenreNames, after.topGenreNames);
}

function timestampMillis(value: unknown): number | undefined {
  return value instanceof Timestamp ? value.toMillis() : undefined;
}

function recommendationRefreshRequested(
  before: admin.firestore.DocumentData | undefined,
  after: admin.firestore.DocumentData | undefined,
): boolean {
  const beforeMillis = timestampMillis(before?.recommendationsRefreshRequestedAt);
  const afterMillis = timestampMillis(after?.recommendationsRefreshRequestedAt);
  return afterMillis !== undefined && afterMillis !== beforeMillis;
}

function tokenKey(type: TokenType, value: string): string {
  return `${type}_${Buffer.from(value.toLowerCase(), 'utf8').toString('base64url')}`;
}

function musicTokens(profile: UserMusicProfile): MusicToken[] {
  return [
    ...profile.topArtistNames.map((value) => ({
      key: tokenKey('artist', value),
      type: 'artist' as const,
      value,
    })),
    ...profile.topGenreNames.map((value) => ({
      key: tokenKey('genre', value),
      type: 'genre' as const,
      value,
    })),
  ];
}

function indexUserRef(token: MusicToken, uid: string): admin.firestore.DocumentReference {
  return db
    .collection(recommendationIndexCollection)
    .doc(token.key)
    .collection('users')
    .doc(uid);
}

async function commitBatches(
  operations: Array<(batch: admin.firestore.WriteBatch) => void>,
): Promise<void> {
  const batchSize = 400;
  for (let i = 0; i < operations.length; i += batchSize) {
    const batch = db.batch();
    operations.slice(i, i + batchSize).forEach((operation) => operation(batch));
    await batch.commit();
  }
}

async function updateRecommendationIndex(
  uid: string,
  before: UserMusicProfile,
  after: UserMusicProfile,
): Promise<void> {
  const previousTokens = new Map(musicTokens(before).map((token) => [token.key, token]));
  const nextTokens = new Map(musicTokens(after).map((token) => [token.key, token]));
  const now = FieldValue.serverTimestamp();
  const operations: Array<(batch: admin.firestore.WriteBatch) => void> = [];

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

  if (operations.length > 0) await commitBatches(operations);
}

function calculateRecommendation(
  myProfile: UserMusicProfile,
  candidate: CandidateProfile,
): RecommendationResult | null {
  const myArtists = new Set(myProfile.topArtistNames);
  const myGenres = new Set(myProfile.topGenreNames);
  const sharedArtistNames = candidate.topArtistNames.filter((artist) => myArtists.has(artist));
  const sharedGenreNames = candidate.topGenreNames.filter((genre) => myGenres.has(genre));

  if (sharedArtistNames.length === 0 && sharedGenreNames.length === 0) return null;

  const artistScore = Math.min(sharedArtistNames.length * 14, 70);
  const genreScore = Math.min(sharedGenreNames.length * 6, 30);

  return {
    uid: candidate.uid,
    score: artistScore + genreScore,
    sharedArtistNames,
    sharedGenreNames,
  };
}

async function deleteExistingRecommendations(uid: string): Promise<void> {
  const existing = await db
    .collection(`users/${uid}/${recommendationsCollection}`)
    .get();
  if (existing.empty) return;

  await commitBatches(
    existing.docs.map((doc) => (batch) => batch.delete(doc.ref)),
  );
}

async function refreshRecommendations(uid: string, profile: UserMusicProfile): Promise<void> {
  const tokens = musicTokens(profile);
  await deleteExistingRecommendations(uid);

  if (tokens.length === 0) return;

  const snapshots = await Promise.all(tokens.map((token) =>
    db
      .collection(recommendationIndexCollection)
      .doc(token.key)
      .collection('users')
      .orderBy('updatedAt', 'desc')
      .limit(maxIndexUsersPerToken)
      .get(),
  ));

  const candidates = new Map<string, CandidateProfile>();
  for (const snapshot of snapshots) {
    for (const doc of snapshot.docs) {
      if (doc.id === uid || candidates.has(doc.id)) continue;
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
    .filter((result): result is RecommendationResult => result !== null)
    .sort((a, b) => b.score - a.score)
    .slice(0, maxStoredRecommendations);

  const generatedAt = Timestamp.now();
  await commitBatches(recommendations.map((recommendation, index) => (batch) => {
    batch.set(
      db.doc(`users/${uid}/${recommendationsCollection}/${recommendation.uid}`),
      {
        userId: recommendation.uid,
        score: recommendation.score,
        sharedArtistNames: recommendation.sharedArtistNames,
        sharedGenreNames: recommendation.sharedGenreNames,
        rank: index + 1,
        generatedAt,
      },
    );
  }));

  logger.info('refreshRecommendations: generated recommendations', {
    uid,
    candidateCount: candidates.size,
    recommendationCount: recommendations.length,
  });
}

async function matchingCandidateProfiles(
  uid: string,
  profiles: UserMusicProfile[],
): Promise<Map<string, CandidateProfile>> {
  const tokenMap = new Map<string, MusicToken>();
  profiles
    .flatMap((profile) => musicTokens(profile))
    .forEach((token) => tokenMap.set(token.key, token));

  const tokens = [...tokenMap.values()];
  if (tokens.length === 0) return new Map();

  const snapshots = await Promise.all(tokens.map((token) =>
    db
      .collection(recommendationIndexCollection)
      .doc(token.key)
      .collection('users')
      .orderBy('updatedAt', 'desc')
      .limit(maxIndexUsersPerToken)
      .get(),
  ));

  const candidates = new Map<string, CandidateProfile>();
  for (const snapshot of snapshots) {
    for (const doc of snapshot.docs) {
      if (doc.id === uid || candidates.has(doc.id)) continue;
      const data = doc.data();
      candidates.set(doc.id, {
        uid: doc.id,
        topArtistNames: stringList(data.topArtistNames),
        topGenreNames: stringList(data.topGenreNames),
      });
      if (candidates.size >= maxReciprocalRecommendationUsers) return candidates;
    }
  }

  return candidates;
}

async function updateReciprocalRecommendations(
  uid: string,
  profile: UserMusicProfile,
  candidates: Map<string, CandidateProfile>,
): Promise<void> {
  const generatedAt = Timestamp.now();
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

  logger.info('updateReciprocalRecommendations: updated candidates', {
    uid,
    candidateCount: candidates.size,
  });
}

async function rebuildMusicRecommendations(
  uid: string,
  before: UserMusicProfile,
  after: UserMusicProfile,
  options: { forceSelfRefresh?: boolean } = {},
): Promise<void> {
  const profileChanged = musicProfileChanged(before, after);
  const forceSelfRefresh = options.forceSelfRefresh === true;
  if (!profileChanged && !forceSelfRefresh) return;

  const reciprocalCandidates = profileChanged || forceSelfRefresh
    ? await matchingCandidateProfiles(uid, [before, after])
    : new Map<string, CandidateProfile>();
  if (profileChanged || forceSelfRefresh) await updateRecommendationIndex(uid, before, after);
  await refreshRecommendations(uid, after);
  if (profileChanged || forceSelfRefresh) {
    await updateReciprocalRecommendations(uid, after, reciprocalCandidates);
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

// ── Función 2 — Recomendaciones musicales ─────────────────────────────────────

// Rebuilds recommendation lists when a user's music taste changes.
// The changed user's full list is rebuilt, and matching existing users get a
// reciprocal recommendation upsert/delete so discovery does not wait for them
// to edit their own profile.
export const onUserMusicProfileCreated = onDocumentCreated(
  { document: 'users/{userId}', region: 'europe-southwest1' },
  async (event) => {
    try {
      const after = readMusicProfile(event.data?.data());
      await rebuildMusicRecommendations(event.params.userId, {
        topArtistNames: [],
        topGenreNames: [],
      }, after);
    } catch (error) {
      logger.error('onUserMusicProfileCreated: unhandled error', {
        userId: event.params.userId,
        error,
      });
      throw error;
    }
  },
);

export const onUserMusicProfileChanged = onDocumentUpdated(
  { document: 'users/{userId}', region: 'europe-southwest1' },
  async (event) => {
    try {
      const beforeData = event.data?.before.data();
      const afterData = event.data?.after.data();
      const before = readMusicProfile(beforeData);
      const after = readMusicProfile(afterData);
      await rebuildMusicRecommendations(event.params.userId, before, after, {
        forceSelfRefresh: recommendationRefreshRequested(beforeData, afterData),
      });
    } catch (error) {
      logger.error('onUserMusicProfileChanged: unhandled error', {
        userId: event.params.userId,
        error,
      });
      throw error;
    }
  },
);

// ── Función 3 — Nueva solicitud de amistad ────────────────────────────────────

export const onFriendRequest = onDocumentCreated(
  { document: 'friend_requests/{requestId}', region: 'europe-southwest1' },
  async (event) => {
    try {
      const request = event.data?.data();
      if (!request) return;
      if (request.status !== 'pending') return;

      const senderId = request.senderId as string;
      const receiverId = request.receiverId as string;

      const [receiverSnap, senderSnap] = await Promise.all([
        db.doc(`users/${receiverId}`).get(),
        db.doc(`users/${senderId}`).get(),
      ]);

      const receiver = receiverSnap.data();
      const fcmToken = receiver?.fcmToken as string | undefined;
      const senderName = senderSnap.data()?.displayName as string | undefined;
      if (!fcmToken || !senderName) return;
      const locale = preferredLocale(receiver);

      await sendNotification(
        receiverId,
        fcmToken,
        { title: 'MusiLink', body: notificationText.friendRequest[locale](senderName) },
        { type: 'friend_request', senderId },
      );
    } catch (error) {
      logger.error('onFriendRequest: unhandled error', { requestId: event.params.requestId, error });
      throw error;
    }
  },
);

// ── Función 4 — Solicitud de amistad aceptada ─────────────────────────────────

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

      const sender = senderSnap.data();
      const fcmToken = sender?.fcmToken as string | undefined;
      const accepterName = receiverSnap.data()?.displayName as string | undefined;
      if (!fcmToken || !accepterName) return;
      const locale = preferredLocale(sender);

      await sendNotification(
        senderId,
        fcmToken,
        { title: 'MusiLink', body: notificationText.friendRequestAccepted[locale](accepterName) },
        { type: 'friend_request_accepted', accepterId: receiverId },
      );

      await db.doc(event.document).delete();
    } catch (error) {
      logger.error('onFriendRequestAccepted: unhandled error', { requestId: event.params.requestId, error });
      throw error;
    }
  },
);
