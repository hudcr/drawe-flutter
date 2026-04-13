const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getRandomPrompt } = require("./prompts");

async function startGame(code, uid) {
  const db = getFirestore();
  const roomRef = db.collection("rooms").doc(code);
  const roomSnap = await roomRef.get();

  if (!roomSnap.exists) throw new Error("Room not found");
  const room = roomSnap.data();
  if (room.hostId !== uid) throw new Error("Only the host can start the game");

  const prompt = getRandomPrompt();
  await roomRef.update({
    status: "drawing",
    currentRound: 1,
    totalRounds: room.settings.rounds,
    prompt,
    roundStartedAt: FieldValue.serverTimestamp(),
    drawingSubmissions: [],
    voteSubmissions: [],
    usedPrompts: [prompt],
  });
}

async function submitDrawing(code, uid, displayName, dataURL) {
  const db = getFirestore();
  const roomRef = db.collection("rooms").doc(code);

  await roomRef.collection("drawings").doc(uid).set({
    uid,
    displayName,
    dataURL,
    ratings: {},
  });

  await roomRef.update({ drawingSubmissions: FieldValue.arrayUnion(uid) });

  // check if everyone has submitted
  const [roomSnap, playersSnap] = await Promise.all([
    roomRef.get(),
    roomRef.collection("players").get(),
  ]);

  if (roomSnap.data().drawingSubmissions.length >= playersSnap.size) {
    await roomRef.update({ status: "voting", voteSubmissions: [] });
  }
}

async function submitVotes(code, uid, ratings) {
  const db = getFirestore();
  const roomRef = db.collection("rooms").doc(code);

  // write all ratings in a batch
  const batch = db.batch();
  for (const [targetUid, stars] of Object.entries(ratings)) {
    batch.update(roomRef.collection("drawings").doc(targetUid), {
      [`ratings.${uid}`]: stars,
    });
  }
  await batch.commit();
  await roomRef.update({ voteSubmissions: FieldValue.arrayUnion(uid) });

  const playersSnap = await roomRef.collection("players").get();

  // use a transaction to safely handle the round transition
  await db.runTransaction(async (t) => {
    const roomSnap = await t.get(roomRef);
    const room = roomSnap.data();

    if (room.status !== "voting") return;
    if (room.voteSubmissions.length < playersSnap.size) return;

    // tally up scores from ratings
    const drawingsSnap = await roomRef.collection("drawings").get();
    for (const drawingDoc of drawingsSnap.docs) {
      const d = drawingDoc.data();
      const total = Object.values(d.ratings || {}).reduce((a, b) => a + b, 0);
      if (total > 0) {
        t.update(roomRef.collection("players").doc(d.uid), {
          score: FieldValue.increment(total),
        });
      }
    }

    if (room.currentRound >= room.totalRounds) {
      t.update(roomRef, { status: "results" });
    } else {
      const prompt = getRandomPrompt(room.usedPrompts || []);
      t.update(roomRef, {
        status: "drawing",
        currentRound: FieldValue.increment(1),
        prompt,
        roundStartedAt: FieldValue.serverTimestamp(),
        drawingSubmissions: [],
        voteSubmissions: [],
        usedPrompts: FieldValue.arrayUnion(prompt),
      });
    }
  });
}

module.exports = { startGame, submitDrawing, submitVotes };
