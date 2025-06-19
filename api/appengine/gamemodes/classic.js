const { getFirestore } = require("firebase-admin/firestore");
const { sendNotification } = require("../notifications");

module.exports.startClassicGame = async (gameId) => {
    const db = getFirestore();

    const gameRef = db.collection("games").doc(gameId);
    const gameSnapshot = await gameRef.get();
    if (!gameSnapshot.exists) {
        console.error(`Game ${gameId} does not exist.`);
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
            fcmToken: playerData.fcmToken,
        });
    });

    const seekers = [];
    const hiders = [];
    playersSnapshot.forEach((doc) => {
        const playerData = doc.data();
        if (playerData.role === "seeker") {
            seekers.push({
                id: doc.id,
                uid: playerData.uid,
                name: playerData.name,
                fcmToken: playerData.fcmToken,
            });
        } else if (playerData.role === "hider") {
            hiders.push({
                id: doc.id,
                uid: playerData.uid,
                name: playerData.name,
                fcmToken: playerData.fcmToken,
            });
        }
    });

    setTimeout(async () => {
        const newGameSnapshot = await gameRef.get();
        if (!newGameSnapshot.exists) {
            return;
        }

        const newGameData = newGameSnapshot.data();

        if (newGameData.status !== "in_progress") {
            return;
        }

        console.log(`Game ${gameId} is releasing seekers.`);

        for (const player of seekers) {
            await playersRef.doc(player.id).update({
                status: "active",
                caughtHiders: [],
            });
        }

        const tokens = players.map((player) => player.fcmToken);
        await sendNotification("Seekers Released", "The seekers have been released. Don't get caught!", tokens);

    }, gameData.settings.hide_duration * 60 * 1000);

    setTimeout(async () => {
        const newGameSnapshot = await gameRef.get();
        if (!newGameSnapshot.exists) {
            return;
        }

        const newGameData = newGameSnapshot.data();

        if (newGameData.status !== "in_progress") {
            return;
        }

        console.log(`Game ${gameId} is finished.`);

        await gameRef.update({
            status: "finished",
            winner: "hider",
        });

        const tokens = players.map((player) => player.fcmToken);
        await sendNotification("Game Finished", "The game has ended. Hiders win!", tokens);

    }, (gameData.settings.hide_duration + gameData.settings.game_duration) *
    60 * 1000);
};