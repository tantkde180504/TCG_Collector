const functions = require("firebase-functions");
const admin = require("firebase-admin");
const PayOS = require("@payos/node");

admin.initializeApp();

// Khởi tạo PayOS bằng cách lấy các biến môi trường cấu hình trên Cloud
const payos = new PayOS(
    process.env.PAYOS_CLIENT_ID,
    process.env.PAYOS_API_KEY,
    process.env.PAYOS_CHECKSUM_KEY
);

// 1. API: Tạo Link thanh toán VietQR
exports.createPaymentLink = functions.https.onCall(async (data, context) => {
    // Yêu cầu người dùng phải đăng nhập trên app
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Bạn phải đăng nhập để thực hiện giao dịch."
        );
    }

    const { orderId, amount, description } = data;

    // PayOS yêu cầu mã đơn hàng (orderCode) phải là dạng Số Nguyên (Number)
    // Chúng ta sẽ lấy chuỗi số từ orderId (ví dụ: ORD-1718900000000-123 -> 1718900000000123)
    const orderCode = Number(orderId.replace(/\D/g, ""));

    const paymentBody = {
        orderCode: orderCode,
        amount: amount,
        description: description.substring(0, 25), // PayOS giới hạn ký tự mô tả
        cancelUrl: "https://tcgcollector.web.app/cancel", // URL khi bấm hủy
        returnUrl: "https://tcgcollector.web.app/success", // URL khi thanh toán xong
    };

    try {
        const paymentResponse = await payos.createPaymentLink(paymentBody);
        return {
            status: "success",
            paymentUrl: paymentResponse.checkoutUrl
        };
    } catch (error) {
        console.error("Lỗi khi tạo Link thanh toán PayOS:", error);
        throw new functions.https.HttpsError("internal", "Không thể khởi tạo giao dịch thanh toán.");
    }
});

// 2. WEBHOOK: Tiếp nhận kết quả thanh toán từ PayOS
exports.payosWebhook = functions.https.onRequest(async (req, res) => {
    const webhookData = req.body;

    try {
        // Xác thực chữ ký webhook để đảm bảo dữ liệu do chính PayOS gửi tới
        const verifiedData = payos.verifyPaymentWebhookData(webhookData);
        const orderCode = verifiedData.orderCode;

        // Nếu giao dịch thành công (desc === "success" hoặc theo định nghĩa PayOS)
        if (verifiedData.desc === "success" || webhookData.success === true) {
            // Tìm đơn hàng tương ứng trong Firestore
            const ordersQuery = await admin.firestore()
                .collectionGroup("orders")
                .where("orderCode", "==", orderCode)
                .limit(1)
                .get();

            if (!ordersQuery.empty) {
                const orderDoc = ordersQuery.docs[0];
                // Cập nhật trạng thái sang "Paid" (Đã thanh toán)
                await orderDoc.ref.update({
                    status: "Paid",
                    paymentTimestamp: admin.firestore.FieldValue.serverTimestamp()
                });
                console.log(`Đơn hàng số ${orderCode} đã được cập nhật thanh toán thành công.`);
            }
        }

        // Trả về kết quả 200 OK cho PayOS xác nhận đã xử lý xong Webhook
        res.status(200).json({ status: "success" });
    } catch (error) {
        console.error("Xác thực Webhook PayOS thất bại:", error);
        res.status(400).send("Webhook Verification Failed");
    }
});
