const { onValueWritten } = require("firebase-functions/v2/database");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

// 1. onMateAnswerWrite: registra y respalda en servidor las respuestas de
// cada mesa en una sala de MateRueda (RF05, RF08).
exports.onmateanswerwrite = onValueWritten("mate/{roomId}/answers/{teamUid}", async (event) => {
  const after = event.data.after.val();
  if (!after) return;
  const { roomId, teamUid } = event.params;
  console.log(`MateRueda sala ${roomId}: respuesta de ${teamUid} en ronda ${after.round} -> opción ${after.index}`);
});

// 2. cleanupMateRooms: elimina salas de MateRueda con más de 12 horas de
// antigüedad para mantener limpia la base de datos en tiempo real.
exports.cleanupmaterooms = onSchedule("every 12 hours", async () => {
  const db = admin.database();
  const snap = await db.ref("mate").get();
  if (!snap.exists()) return;

  const now = Date.now();
  const MAX_AGE_MS = 12 * 60 * 60 * 1000;
  const removals = [];

  snap.forEach((child) => {
    const createdAt = child.child("createdAt").val() || 0;
    if (now - createdAt > MAX_AGE_MS) {
      removals.push(child.ref.remove());
    }
  });

  await Promise.all(removals);
  console.log(`MateRueda: ${removals.length} salas antiguas limpiadas.`);
});
