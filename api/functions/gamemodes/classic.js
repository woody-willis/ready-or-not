const {logger} = require("firebase-functions");
const {getFirestore} = require("firebase-admin/firestore");

module.exports.startClassicGame = async (gameId) => {
  const db = getFirestore();

  const gameRef = db.collection("games").doc(gameId);
  const gameSnapshot = await gameRef.get();
  if (!gameSnapshot.exists) {
    logger.error(`Game ${gameId} does not exist.`);
    return;
  }

  const gameData = gameSnapshot.data();

  const playersRef = gameRef.collection("players");
  const playersSnapshot = await playersRef.get();
  if (playersSnapshot.empty) {
    logger.error(`No players found for game ${gameId}.`);
    return;
  }

  const players = [];
  playersSnapshot.forEach((doc) => {
    const playerData = doc.data();
    players.push({
      id: doc.id,
      uid: playerData.uid,
      name: playerData.name,
    });
  });
  if (players.length < 2) {
    logger.error(`Not enough players for game ${gameId}.`);
    return;
  }

  // Shuffle players
  players.sort(() => Math.random() - 0.5);

  const seekerCount = gameData.settings.seeker_amount;
  const seekers = players.slice(0, seekerCount);
  const hiders = players.slice(seekerCount);

  // Update player roles
  for (const player of seekers) {
    await playersRef.doc(player.id).update({
      role: "seeker",
      status: "awaiting_start",
    });
  }
  for (const player of hiders) {
    await playersRef.doc(player.id).update({
      role: "hider",
      status: "active",
    });
  }

  const startTime = new Date();
  const hideEndTime = new Date(startTime.getTime() +
    (gameData.settings.hide_duration * 60 * 1000));
  const gameEndTime = new Date(hideEndTime.getTime() +
    (gameData.settings.game_duration * 60 * 1000));

  // Set game state
  await gameRef.update({
    status: "in_progress",
    seekers: seekers.map((player) => player.uid),
    hiders: hiders.map((player) => player.uid),
    caughtHiders: [],
    startTime: startTime,
    hideEndTime: hideEndTime,
    gameEndTime: gameEndTime,
  });

  setTimeout(async () => {
    if (gameData.status !== "in_progress") {
      return;
    }

    logger.log(`Game ${gameId} is releasing seekers.`);

    for (const player of seekers) {
      await playersRef.doc(player.id).update({
        status: "active",
        caughtHiders: [],
      });
    }
  }, gameData.settings.hide_duration * 60 * 1000);

  setTimeout(async () => {
    if (gameData.status !== "in_progress") {
      return;
    }

    logger.log(`Game ${gameId} is finished.`);

    await gameRef.update({
      status: "finished",
      winner: "hiders",
    });
  }, (gameData.settings.hide_duration + gameData.settings.game_duration) *
        60 * 1000);
};
