const { initializeApp } = require("firebase-admin/app");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { createRoom, joinRoom } = require("./src/roomManager");
const { startGame, submitDrawing, submitVotes } = require("./src/gameLogic");

initializeApp();

function requireAuth(request) {
  if (!request.auth) throw new HttpsError("unauthenticated", "Must be logged in");
}

function getDisplayName(request) {
  return request.auth.token.name || request.auth.token.email?.split("@")[0] || "Player";
}

exports.createRoom = onCall(async (request) => {
  requireAuth(request);
  const code = await createRoom(request.auth.uid, getDisplayName(request), request.data.settings);
  return { code };
});

exports.joinRoom = onCall(async (request) => {
  requireAuth(request);
  await joinRoom(request.data.code, request.auth.uid, getDisplayName(request));
  return { success: true };
});

exports.startGame = onCall(async (request) => {
  requireAuth(request);
  await startGame(request.data.code, request.auth.uid);
  return { success: true };
});

exports.submitDrawing = onCall(async (request) => {
  requireAuth(request);
  await submitDrawing(request.data.code, request.auth.uid, getDisplayName(request), request.data.dataURL);
  return { success: true };
});

exports.submitVotes = onCall(async (request) => {
  requireAuth(request);
  await submitVotes(request.data.code, request.auth.uid, request.data.ratings);
  return { success: true };
});
