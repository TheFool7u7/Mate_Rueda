const { onDocumentWritten, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { getStorage } = require("firebase-admin/storage");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// 1. onVoteWrite: agrega votos y calcula promedio al puntaje
exports.onvotewrite = onDocumentWritten("rooms/{roomId}/rounds/{roundId}/responses/{letterId}/votes/{voterId}", async (event) => {
  const { roomId, roundId, letterId } = event.params;
  
  // Obtenemos todos los votos de la respuesta
  const votesRef = db.collection("rooms").doc(roomId).collection("rounds").doc(roundId).collection("responses").doc(letterId).collection("votes");
  const votesSnap = await votesRef.get();
  
  let totalScore = 0;
  let count = 0;
  votesSnap.forEach(doc => {
    const data = doc.data();
    if (data.score != null) {
      totalScore += data.score;
      count++;
    }
  });
  
  const average = count > 0 ? totalScore / count : 0;
  
  // Actualizamos el documento de la respuesta con el promedio
  const responseRef = db.collection("rooms").doc(roomId).collection("rounds").doc(roundId).collection("responses").doc(letterId);
  await responseRef.set({
    averageScore: average,
    totalVotes: count
  }, { merge: true });
});

// 2. onRoundComplete: limpia nodo RTDB y guarda resultado en Firestore
exports.onroundcomplete = onDocumentUpdated("rooms/{roomId}", async (event) => {
  const newData = event.data.after.data();
  const oldData = event.data.before.data();
  
  // Verificamos si el estado cambió a "finished"
  if (newData.status === 'finished' && oldData.status !== 'finished') {
    const roomId = event.params.roomId;
    
    // Limpiamos el nodo RTDB
    await admin.database().ref(`games/${roomId}`).remove();
    
    // (Opcional) el resultado ya está en Firestore en newData, pero 
    // podríamos consolidarlo si fuera necesario.
    console.log(`Sala ${roomId} finalizada. RTDB limpiado.`);
  }
});

// 3. TTL cleanup para archivos /punishments/ mayores a 24h
exports.cleanuppunishments = onSchedule("every 24 hours", async (event) => {
  const bucket = getStorage().bucket();
  const [files] = await bucket.getFiles({ prefix: 'punishments/' });
  
  const now = Date.now();
  const ONE_DAY_MS = 24 * 60 * 60 * 1000;
  
  const deletePromises = files.map(file => {
    return file.getMetadata().then(([metadata]) => {
      const created = new Date(metadata.timeCreated).getTime();
      if (now - created > ONE_DAY_MS) {
        return file.delete();
      }
    });
  });
  
  await Promise.all(deletePromises);
  console.log('Cleanup de castigos completado.');
});
