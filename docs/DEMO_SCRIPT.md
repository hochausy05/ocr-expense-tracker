# Kịch bản demo OCR Expense Tracker (2–3 phút)

**Chuẩn bị:** Cài APK trên Android, dùng hóa đơn thật có ngày và tổng tiền dễ đọc, đảm bảo camera được cấp quyền. Chuẩn bị thêm một khoản chi đã lưu nếu muốn màn hình lịch sử có nhiều mục. Không dùng dữ liệu OCR giả.

| Thời lượng | Thao tác và lời dẫn |
|---|---|
| 0:00–0:15 | Mở ứng dụng ở màn hình Chi tiêu. “Đây là ứng dụng theo dõi chi tiêu từ hóa đơn, xử lý OCR ngay trên thiết bị và lưu dữ liệu cục bộ.” |
| 0:15–0:35 | Chạm Quét hóa đơn, cấp quyền camera nếu được hỏi. Cho thấy preview, khung căn hóa đơn; thử đèn flash nếu thiết bị hỗ trợ. “Khung giúp căn hóa đơn trước khi chụp.” |
| 0:35–0:55 | Đặt hóa đơn trong khung, chụp; căn chỉnh và xác nhận crop. “Ảnh crop này được chuyển trực tiếp vào bộ nhận dạng văn bản trên thiết bị.” |
| 0:55–1:20 | Chờ OCR và mở màn hình Kiểm tra. Chỉ vào tên cửa hàng, ngày, tổng tiền được nhận dạng. “Bộ phân tích heuristic đề xuất các trường; kết quả có thể khác nhau theo hóa đơn.” |
| 1:20–1:40 | Sửa một trường để minh họa nhập tay; chọn danh mục phù hợp. “Người dùng có thể sửa thông tin trước khi lưu.” |
| 1:40–2:00 | Chạm Lưu một lần. Quay về Chi tiêu, chỉ vào mục mới và ảnh thu nhỏ. “Khoản chi lưu trong SQLite; ảnh nằm trong vùng lưu trữ ứng dụng và cơ sở dữ liệu giữ đường dẫn.” |
| 2:00–2:30 | Mở Thống kê. Cho thấy biểu đồ vành khuyên và biểu đồ cột tuần; đợi hoạt ảnh chạy. “Cả hai biểu đồ tự vẽ bằng CustomPainter và tổng hợp từ khoản chi đã lưu.” |

**Ghi hình:** quay màn hình thiết bị thật, giữ chữ đủ rõ, chờ OCR/chart ổn định trước khi chuyển bước. Nếu camera/OCR không hoạt động hoặc emulator không hỗ trợ phần cứng, dừng và xử lý thiết bị trước khi quay; không ghép kết quả giả. Video chưa được ghi nhận là đã quay cho đến khi tệp video thực sự tồn tại.
