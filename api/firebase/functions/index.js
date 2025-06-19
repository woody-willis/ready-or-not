const {logger} = require("firebase-functions");
const {
  onDocumentUpdatedWithAuthContext,
} = require("firebase-functions/v2/firestore");

const {initializeApp} = require("firebase-admin/app");

const {startClassicGame, gameStateChanged} = require("./gamemodes/classic");

initializeApp();

exports.startGame = onDocumentUpdatedWithAuthContext(
    "/games/{gameId}",
    async (event) => {
      if (event.data.after.get("status") !== "starting") return;

      const gameId = event.params.gameId;

      const gameMode = event.data.after.get("gameMode");
      logger.log(`Game ${gameId} is starting with game mode ${gameMode}.`);

      switch (gameMode) {
        case "classic":
          // Handle classic game mode
          startClassicGame(gameId);
          break;
        default:
          logger.error(`Unknown game mode: ${gameMode}`);
      }
    },
);

exports.gameStateChanged = onDocumentUpdatedWithAuthContext(
    "/games/{gameId}",
    async (event) => {
      if (event.data.after.get("status") !== "in_progress") return;

      const gameId = event.params.gameId;
      const gameMode = event.data.after.get("gameMode");

      switch (gameMode) {
        case "classic":
          // Handle classic game mode
          gameStateChanged(gameId);
          break;
        default:
          logger.error(`Unknown game mode: ${gameMode}`);
      }
    },
);
