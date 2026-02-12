import * as functions from "firebase-functions/v1"; // ★ v1を明示的に指定
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * 新しいイベントが登録されたら、その事業者のフォロワーに通知を送る関数
 */
export const sendNewEventNotification = functions.firestore
  .document("events/{eventId}")
  .onCreate(async (snapshot, context) => {
    // 1. イベントデータの取得
    const eventData = snapshot.data();
    if (!eventData) return; // データがない場合のガード

    const adminId = eventData.adminId; // 事業者ID
    const eventName = eventData.eventName; // イベント名
    const eventId = context.params.eventId; // イベントID

    console.log(`New event created: ${eventName} by ${adminId}`);

    try {
      // 2. 事業者名の取得 (通知のタイトルに使うため)
      const businessDoc = await admin.firestore().collection("businesses").doc(adminId).get();
      const businessData = businessDoc.data();
      const businessName = businessData?.admin_name || "事業者"; // admin_nameフィールドを使用

      // 3. フォロワー一覧の取得 (Step 1で作ったサブコレクション)
      const followersSnapshot = await admin.firestore()
        .collection("businesses")
        .doc(adminId)
        .collection("followers")
        .get();

      if (followersSnapshot.empty) {
        console.log("No followers found.");
        return;
      }

      // フォロワーのユーザーIDリストを作成
      const followerIds = followersSnapshot.docs.map((doc) => doc.id);

      // 4. 各フォロワーのFCMトークンを取得 (usersコレクションから)
      const tokens: string[] = [];
      
      const tokenPromises = followerIds.map(async (uid) => {
        const userDoc = await admin.firestore().collection("users").doc(uid).get();
        const userData = userDoc.data();
        if (userData && userData.fcmToken) {
          tokens.push(userData.fcmToken);
        }
      });

      await Promise.all(tokenPromises);

      if (tokens.length === 0) {
        console.log("No tokens found to send.");
        return;
      }

      // 5. 通知メッセージの作成
      const message: admin.messaging.MulticastMessage = {
        notification: {
          title: `${businessName} が新しいイベントを登録しました！`,
          body: `${eventName}\n詳細をチェックしてみよう！`,
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK", // タップ時の挙動用
          type: "new_event",
          eventId: eventId,
          businessId: adminId,
        },
        tokens: tokens, // 送信先リスト
      };

      // ★ 追加: ここで送信先のトークン一覧をログに出す
      console.log("Target FCM Tokens:", tokens);

      // 6. 送信実行
      const response = await admin.messaging().sendEachForMulticast(message);
      
      console.log(`${response.successCount} messages were sent successfully`);
      
    } catch (error) {
      console.error("Error sending notification:", error);
    }
  });