const {logger} = require("firebase-functions");
const {getMessaging} = require("firebase-admin/messaging");

module.exports.sendNotification = async (title, body, tokens) => {
  const messaging = getMessaging();

  const message = {
    notification: {
      title: title,
      body: body,
    },
    android: {
      priority: "high",
    },
    tokens: tokens,
  };

  try {
    const result = await messaging.sendEachForMulticast(message);
    if (result.failureCount > 0) {
      result.responses.forEach((response, idx) => {
        if (!response.success) {
          logger.error(
              `Failed to send message to token ${tokens[idx]}: ` +
              response.error,
          );
        }
      });
    }
  } catch (error) {
    logger.error(`Error sending message: ${error}`);
  }
};
