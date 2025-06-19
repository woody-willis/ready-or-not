const { getMessaging } = require("firebase-admin/messaging");

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
                    console.error(`Failed to send message to token ${tokens[idx]}: ${response.error}`);
                }
            });
        }
    } catch (error) {
        console.error(`Error sending message: ${error}`);
    }
};