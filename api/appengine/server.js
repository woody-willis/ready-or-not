const express = require('express');
const app = express();

const { initializeApp } = require('firebase-admin/app');
const fbApp = initializeApp();

const { getFirestore } = require('firebase-admin/firestore');

const { startClassicGame } = require('./gamemodes/classic');

app.get('/start-game/:id', async (req, res) => {
    const gameId = req.params.id;
    const db = getFirestore(fbApp);

    const gameRef = db.collection('games').doc(gameId);
    const gameSnapshot = await gameRef.get();
    const gameData = gameSnapshot.data();

    if (!gameData) {
        res.status(404).json({
            success: false,
            message: `Game with ID ${gameId} not found.`,
        });
        return;
    }

    switch (gameData.gameMode) {
        case 'classic':
            await startClassicGame(gameId);
            break;
        default:
            res.status(400).json({
                success: false,
                message: `Game mode ${gameData.gameMode} is not supported.`,
            });
            return;
    }
    
    res.status(200).json({
        success: true,
    });
});

// Listen to the App Engine-specified port, or 8000 otherwise
const PORT = process.env.PORT || 8000;
app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}...`);
});