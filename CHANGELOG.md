# CHANGELOG.md

> File này chỉ viết bằng **tiếng Việt**.  
> Không sửa/xóa lịch sử cũ. Khi có thay đổi hoàn thành đáng kể, thêm mục mới ngay dưới phần `Nhật ký`, mục mới nhất ở trên cùng.  
> Chỉ ghi những gì thực tế đã làm và kiểm tra; không tự suy đoán kết quả test.

## Mẫu

```md
## YYYY-MM-DD HH:mm — TASK-ID

- **Trạng thái:** Hoàn thành / Một phần / Bị chặn
- **Thay đổi:** ...
- **Kiểm tra:** ...
- **Rủi ro / còn lại:** ...
- **Bước tiếp theo:** ...
```

---

# Nhật ký

## 2026-10-08 18:27 — FIX-02

- **Trạng thái:** Hoàn thành và xác minh bằng kiểm thử cùng emulator.
- **Thay đổi:** Bổ sung lọc tiêu đề hóa đơn chung, dòng metadata và ngữ cảnh nhân viên để không gán tiêu đề hoặc tên nhân viên làm cửa hàng khi không có ứng viên đáng tin cậy. Nhận diện các biến thể `T.CỘNG`, `T. CỘNG`, `T CỘNG`; tìm số tiền trong cửa sổ tối đa 24 dòng sau nhãn tổng và xếp hạng theo khoảng cách, ngữ cảnh tiền tệ/thanh toán, vị trí cuối và giá trị lặp. Giữ nguyên OCR, ngày tháng và cấu hình R8.
- **Kiểm tra:** `dart format lib test` (26 tệp, 2 tệp được định dạng); `flutter analyze` không có vấn đề; `flutter test` đạt 35/35; build APK debug và release thành công. Cài release lên emulator Android 16, chạy lại cùng ảnh hóa đơn: ô cửa hàng để trống, ngày `20/10/2014`, tổng `400000000`.
- **Rủi ro / còn lại:** OCR vẫn sắp xếp một số dòng và số tiền riêng; heuristic chỉ tìm trong cửa sổ giới hạn và không xác định tên cửa hàng nếu văn bản không cung cấp bằng chứng đáng tin cậy.

## 2026-10-08 17:45 — FIX-01

- **Trạng thái:** Đã sửa và xác minh OCR trên bản release có R8.
- **Thay đổi:** Bổ sung quy tắc `-dontwarn` cho kiểu Component của Firebase/ML Kit và giữ lớp triển khai `ComponentRegistrar` cùng constructor không tham số. Quy tắc registrar chưa tự khắc phục lỗi; thêm quy tắc giữ riêng `com.google.android.gms.internal.mlkit_vision_common.zzmj`, lớp xuất hiện tại điểm crash. Giữ nguyên cấu hình build release và `kotlin.incremental=false`; không đổi mã OCR hoặc phiên bản phụ thuộc.
- **Kiểm tra:** Build `flutter build apk --release` thành công. Cài APK lên emulator Android 16 `sdk_gphone16k_x86_64`, chọn cùng ảnh hóa đơn trong thư viện, crop và xác nhận; OCR hoàn tất, đưa văn bản nhận dạng sang màn hình Kiểm tra. Logcat không còn NPE `zzmj`. Quy tắc giữ toàn package `mlkit_vision_common` cũng đã thử thành công nhưng được thu hẹp; quy tắc chỉ giữ `zzmj` tiếp tục vượt qua luồng OCR thật.
- **Rủi ro / còn lại:** OCR chạy được; parser chưa tự điền tổng tiền cho ảnh thử này và tên cửa hàng được nhận diện là tiêu đề hóa đơn. Không thuộc phạm vi FIX-01.

## 2026-10-08 16:03 — QA-01

- **Trạng thái:** Hoàn thành tính năng chọn ảnh và kiểm tra tự động/build; đã xác minh mở rồi hủy bộ chọn ảnh trên emulator. Chưa kiểm tra nhận dạng với hóa đơn thật.
- **Thay đổi:** Thêm `image_picker` để chọn ảnh JPG/JPEG/PNG từ thư viện. Ảnh đã chọn đi qua cùng bước cắt ảnh, OCR offline, parser và màn hình Review như ảnh chụp camera; cho phép thao tác khi camera không khả dụng. Hủy chọn giữ nguyên màn hình Scan; lỗi định dạng/đọc ảnh có thông báo.
- **Kiểm tra:** `dart format lib test` (26 tệp, không còn thay đổi), `flutter analyze` (không có vấn đề), `flutter test` (31/31), build APK debug và release thành công. Cài/mở release trên emulator Android 16, mở Android Photo Picker rồi hủy và xác nhận quay lại Scan.
- **Rủi ro / còn lại:** Không có ảnh hóa đơn thật để kiểm tra crop, OCR, parser và Review sau import trên thiết bị. Test widget xác nhận chuyển tiếp từ ảnh được chọn sang cropper/OCR bằng callback giả, không kiểm tra độ chính xác ML Kit. Emulator có ảnh chụp cảnh ảo từ lần kiểm tra trước, không dùng chúng để khẳng định OCR hóa đơn thật.
- **Bước tiếp theo:** Chọn ảnh hóa đơn thật trên Android để xác minh toàn bộ nhánh import và sửa các trường trong Review nếu cần.

## 2026-10-08 15:31 — FINAL-01

- **Trạng thái:** Hoàn thành phần kiểm tra tự động, build và tài liệu; chưa xác minh đầy đủ luồng bằng hóa đơn thật.
- **Thay đổi:** Hoàn thiện README, kịch bản demo tiếng Việt, nguồn báo cáo kỹ thuật và PDF 3 trang; lưu ảnh chụp màn hình thực tế từ emulator. Sửa cấu hình ProGuard để R8 bỏ qua các lớp ML Kit cho script không dùng (ứng dụng chỉ khởi tạo Latin), giữ nguyên cấu hình Kotlin hiện có. Bắt lỗi PlatformException khi dọn CameraX controller chưa tạo preview surface để không phát sinh lỗi chưa xử lý. Bổ sung loại trừ cho `android/local.properties`, cache Kotlin và cấu hình VS Code cá nhân trong `.gitignore`.
- **Kiểm tra:** `dart format lib test` (25 tệp, không thay đổi), `flutter analyze` (không có vấn đề), `flutter test` (28/28), build debug và release đều thành công. Cài và mở APK release trên Pixel_7 emulator; xác nhận Home, preview camera ảo, chụp/crop, trạng thái OCR lỗi có thể chuyển sang nhập tay và màn hình Thống kê rỗng ở 1080×2400. Lần thử camera sau khi sửa không còn lỗi teardown chưa xử lý. `apksigner verify` thành công; APK ký bằng Android debug key.
- **Kết quả build release:** `build/app/outputs/flutter-apk/app-release.apk`, 85.204.045 byte (81,3 MiB; khoảng 85,2 MB), cài được trên emulator; chỉ phù hợp APK thử nghiệm, không phải ký production.
- **Tiêu chí đã xác minh:** Kiểm tra format/analyze/test; build debug/release; cài/mở release; Home, camera preview, capture/crop, nhánh khôi phục OCR, thống kê dữ liệu rỗng; README, kịch bản demo, báo cáo nguồn/PDF và ảnh chụp.
- **Rủi ro / còn lại:** Không có hóa đơn thật trong lần kiểm tra. OCR trên cảnh ảo của emulator trả lỗi có thể khôi phục, nên chưa xác nhận nhận dạng tên/ngày/tổng trên hóa đơn. Chưa xác minh lưu SQLite, ảnh thu nhỏ, dữ liệu còn sau khi mở lại, biểu đồ có dữ liệu/hoạt ảnh và flash/tap-focus/lifecycle. Chưa có Git repository/remote; chưa có thông tin sinh viên, URL nộp bài hoặc video demo. `flutter doctor` còn báo giấy phép Android chưa chấp nhận; các build vẫn thành công. APK dùng debug signing.
- **Việc người dùng cần thực hiện để nộp:** Thử toàn bộ luồng bằng hóa đơn thật trên Android và cập nhật kết quả; điền thông tin sinh viên cùng URL thật vào README/báo cáo; tạo repository GitHub công khai rồi `git init`, `git add .`, `git commit`, thêm remote và `git push`; ghi và tải video demo; tạo private release keystore nếu cần phân phối ngoài mục đích thử nghiệm. Không có thao tác commit/push/tải lên nào được thực hiện.

## 2026-10-08 09:38 — STATS-01

- **Trạng thái:** Đã triển khai; còn chờ xác minh hiển thị và dữ liệu thực tế trên Android.
- **Thay đổi:** Thay màn hình thống kê tạm bằng tổng chi tiêu, biểu đồ vành khuyên theo năm danh mục và biểu đồ cột từ thứ Hai đến Chủ nhật của tuần hiện tại. Hai biểu đồ vẽ trực tiếp bằng CustomPainter/Canvas, chuyển động trong 700 mili giây, có chú thích và xử lý dữ liệu bằng không. Tổng hợp số tiền VND nguyên từ truy vấn SQLite hiện có; phân tuần theo ngày giao dịch địa phương, xử lý ranh giới tháng/năm. Tải lại khi mở màn hình, trở lại ứng dụng hoặc làm mới; có trạng thái chờ, rỗng và lỗi có thể thử lại. Không thêm thư viện hay dữ liệu mẫu.
- **Kiểm tra:** dart format lib test, flutter analyze, flutter test (28 bài kiểm tra) và flutter build apk --debug đều thành công. Kiểm tra tự động bao gồm tổng/độ phân bố theo danh mục, tuần qua tháng/năm, ngày địa phương và UTC, khoản chi ngoài tuần, số tiền lớn, dữ liệu rỗng, tiến trình hoạt ảnh, bố cục hẹp, tải lại và thử lại sau lỗi. Đã xác nhận không có thư viện biểu đồ và cấu hình kotlin.incremental=false vẫn được giữ.
- **Rủi ro / còn lại:** Đã khởi động trình giả lập Pixel_7 nhưng ADB báo unauthorized, kể cả sau khi kết nối lại và khởi động lại máy chủ ADB. Chưa thể cài/chạy ứng dụng để quan sát hoạt ảnh, đối chiếu với khoản chi đã lưu hoặc xác minh cập nhật sau luồng quét/lưu trên Android; các tiêu chí tương ứng vẫn để mở.
- **Bước tiếp theo:** FINAL-01

## 2026-10-08 08:54 — EXPENSE-01

- **Trạng thái:** Đã triển khai; còn chờ xác minh luồng lưu trữ trên Android.
- **Thay đổi:** Nút Lưu ở màn hình kiểm tra chỉ sao chép ảnh đã cắt vào thư mục hóa đơn sau khi dữ liệu hợp lệ; sau đó ghi đường dẫn ảnh và khoản chi vào SQLite. Chặn thao tác lưu lặp, hiển thị trạng thái và lỗi, xóa bản sao mới nếu ghi cơ sở dữ liệu thất bại. Sau khi lưu thành công, ứng dụng trở về Home và tải lại lịch sử. Sửa việc khôi phục ngày giao dịch theo giờ địa phương, cho phép thử lại khi mở cơ sở dữ liệu thất bại, và bỏ yêu cầu khởi tạo dữ liệu định dạng ngày không cần thiết ở thẻ lịch sử.
- **Kiểm tra:** dart format lib test, flutter analyze, flutter test (17 bài kiểm tra) và flutter build apk --debug đều thành công. Kiểm tra tự động bao gồm lưu hợp lệ, chặn lưu lặp, dữ liệu thiếu, chụp lại, lỗi lưu ảnh/cơ sở dữ liệu, hiển thị lịch sử với đường dẫn ảnh không tồn tại, cùng các bài kiểm tra parser cũ.
- **Rủi ro / còn lại:** Chưa có thiết bị hoặc emulator Android; chưa xác minh thực tế Scan → Review → Save → Home, ảnh thu nhỏ, và dữ liệu còn sau khi khởi động lại. Các tiêu chí phụ thuộc thiết bị trong TASKS.md vẫn để mở.
- **Bước tiếp theo:** STATS-01

## 2026-10-08 08:36 — SCAN-01

- **Trạng thái:** Đã triển khai; còn chờ xác minh camera/OCR trên Android
- **Thay đổi:** Tích hợp camera preview, khung căn hóa đơn, flash, tap-to-focus, xử lý vòng đời camera và chụp ảnh; thêm bước crop ảnh thật bằng image_cropper; chạy Google ML Kit Text Recognition offline trên ảnh đã crop; thêm parser heuristic cho merchant/ngày/tổng tiền và màn hình review có thể sửa dữ liệu, chọn danh mục, chụp lại hoặc nhập thủ công. Nút tiếp tục chỉ trả về dữ liệu Expense đã kiểm tra và đường dẫn ảnh; chưa ghi SQLite.
- **Kiểm tra:** dart format lib test, flutter analyze, flutter test và flutter build apk --debug đều thành công. Bộ test parser bao gồm định dạng tiền VND dấu phẩy/dấu chấm, total so với subtotal/discount, ngày hợp lệ/không hợp lệ, thiếu dữ liệu và OCR nhiễu; widget test xác minh nhập tay và chọn danh mục.
- **Rủi ro / còn lại:** Không có thiết bị/emulator Android để xác minh camera preview, chụp/crop thực tế hoặc kết quả OCR on-device. Các acceptance phụ thuộc thiết bị vẫn chưa đánh dấu hoàn tất.
- **Bước tiếp theo:** EXPENSE-01

## 2026-10-08 07:52 — CORE-01

- **Trạng thái:** Đã triển khai nền tảng; còn chờ xác minh trên Android
- **Thay đổi:** Tạo model Expense với năm danh mục cố định và ngày ISO-8601; thêm hợp đồng dữ liệu ParsedReceipt; triển khai SQLite version 1 với thao tác thêm và truy vấn lịch sử; thêm dịch vụ sao chép ảnh vào thư mục riêng trong bộ nhớ ứng dụng; xây dựng điều hướng Chi tiêu/Quét/Thống kê, danh sách Home và trạng thái rỗng; giữ OCR, parser, review và biểu đồ ở trạng thái placeholder.
- **Kiểm tra:** dart format lib test, flutter analyze và flutter test đều thành công. Đã thử flutter build apk --debug nhưng lỗi Kotlin incremental compiler lặp lại: không thể tạo đường dẫn tương đối giữa source plugin trong cache ổ C: và project trên ổ F:.
- **Rủi ro / còn lại:** Không có Android device/emulator. Chưa xác minh app launch, SQLite initialization, insert/query hoặc Home đọc expense đã lưu trên Android; các acceptance tương ứng vẫn để chưa hoàn tất.
- **Bước tiếp theo:** Xác minh các acceptance CORE-01 còn lại trên Android; sau đó thực hiện SCAN-01.

## 2026-10-07 23:14 — CORE-00

- **Trạng thái:** Hoàn thành phần bootstrap
- **Thay đổi:** Khởi tạo Flutter 3.47.6 trực tiếp tại thư mục gốc với Android; tạo skeleton `lib/` và màn hình Home placeholder; thêm sáu dependency nền tảng theo yêu cầu; khai báo quyền camera Android; cập nhật trạng thái bootstrap và hướng dẫn package trong README.
- **Kiểm tra:** `flutter pub get` thành công; `dart format lib test` và kiểm tra format không phát hiện thay đổi còn thiếu; `flutter analyze` không có lỗi. Đã thử `flutter build apk --debug` nhưng Kotlin incremental compiler lỗi do đường dẫn source cache ở ổ C: và project ở ổ F:.
- **Rủi ro / còn lại:** Chưa thể chạy ứng dụng vì không có Android device/emulator; build APK debug chưa thành công do lỗi Kotlin cache nhiều ổ đĩa. `flutter doctor` báo thiếu Chrome và Visual Studio, không ảnh hưởng mục tiêu Android.
- **Bước tiếp theo:** CORE-01

## 2026-10-07 — DOCS-INIT

- **Trạng thái:** Hoàn thành
- **Thay đổi:** Chốt bộ tài liệu triển khai Mini-Project 3 gồm `AGENTS.md`, `PLAN.md`, `TASKS.md`, `CHANGELOG.md`, `README.md`. Phạm vi được giới hạn đúng yêu cầu: Flutter/Dart, camera + framing/crop, Google ML Kit OCR on-device, heuristic parser merchant/date/total, review thủ công, `sqflite`, lưu ảnh local và biểu đồ animation bằng `CustomPainter`.
- **Kiểm tra:** Đã đối chiếu roadmap với yêu cầu Mini-Project 3 được cung cấp; chưa có kiểm tra mã nguồn hoặc build ứng dụng ở bước tài liệu.
- **Rủi ro / còn lại:** Chưa triển khai code; camera/OCR cần kiểm tra trên môi trường Android thực tế.
- **Bước tiếp theo:** Thực hiện `CORE-01`.
