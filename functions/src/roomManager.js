const { getFirestore, FieldValue } = require("firebase-admin/firestore");

function generateCode() {
  // removed O, 0, I, 1 to avoid confusion
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let code = "";
  for (let i = 0; i < 5; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

async function createRoom(uid, displayName, settings = {}) {
  const db = getFirestore();
  const code = generateCode();
  const roomRef = db.collection("rooms").doc(code);

  await roomRef.set({
    code,
    hostId: uid,
    status: "lobby",
    settings: {
      rounds: settings.rounds ?? 3,
      drawTime: settings.drawTime ?? 60,
    },
    currentRound: 0,
    totalRounds: settings.rounds ?? 3,
    prompt: null,
    roundStartedAt: null,
    drawingSubmissions: [],
    voteSubmissions: [],
    usedPrompts: [],
    createdAt: FieldValue.serverTimestamp(),
  });

  await roomRef.collection("players").doc(uid).set({
    uid,
    displayName,
    score: 0,
  });

  return code;
}

async function joinRoom(code, uid, displayName) {
  const db = getFirestore();
  const roomRef = db.collection("rooms").doc(code);
  const snap = await roomRef.get();

  if (!snap.exists) throw new Error("Room not found");
  if (snap.data().status !== "lobby") throw new Error("Game already started");

  await roomRef.collection("players").doc(uid).set(
    { uid, displayName, score: 0 },
    { merge: true }
  );
}

module.exports = { createRoom, joinRoom };
