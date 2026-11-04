# Wongherm Bakery

แอปพรีออเดอร์ขนมโฮมเมด/เบเกอรี่ เปรียบเทียบข้อกำหนดและช่องว่างล่าสุดได้ที่ [docs/BAKERY_REQUIREMENTS_REVIEW.md](docs/BAKERY_REQUIREMENTS_REVIEW.md)

แอป Android สำหรับสั่งซื้อเบเกอรี่ สร้างด้วย Flutter และ Supabase รองรับบัญชีลูกค้า/เจ้าของร้าน รายการสินค้า ตะกร้า การสั่งซื้อ หลักฐานชำระเงิน ประวัติคำสั่งซื้อ การแจ้งเตือนในแอป และแชทเรียลไทม์ระหว่างลูกค้ากับแอดมิน

## ฟีเจอร์และสถานะ Week 2–6

- **Week 2 — UX/UI (30 ก.ย. 2569):** บรีฟปัญหา/ผู้ใช้ โฟลว์หลัก และ wireframe 5 หน้าจออยู่ใน [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md); โครงสร้างโปรเจกต์และธีมอยู่ใน `lib/`
- **Week 3 — Data & Sync (7 ต.ค. 2569):** Auth, CRUD สินค้า, schema/data model และ SQLite cache สำหรับอ่าน catalog ตอนออฟไลน์; รายละเอียด schema อยู่ใน [docs/DATA_MODEL.md](docs/DATA_MODEL.md)
- **Week 4 — Integrations (14 ต.ค. 2569):** แชทเรียลไทม์ลูกค้า↔แอดมิน, แจ้งเตือนในแอปจาก Supabase, อัปโหลดรูปสินค้าไป Supabase Storage, กรองตามหมวดหมู่ และค้นหาจากชื่อ/รายละเอียดสินค้า
- **Week 5 — Polish & Test (21 ต.ค. 2569):** เพิ่มป้ายกำกับสำหรับช่องค้นหาและปุ่มที่ใช้ไอคอน, เพิ่ม contrast ของปุ่มหลัก, ขยาย tap target ปุ่มเพิ่มสินค้า, ซ่อนการจัดการสินค้าในหน้าลูกค้า, ตรวจราคา non-finite และมี automated tests 20 เคส
- **เพิ่มเติม:** เพิ่มช่องจัดการจำนวนสต๊อกและแสดงจำนวนคงเหลือในหน้าร้าน; ต้อง apply migration [`supabase/migrations/20261029_product_stock.sql`](supabase/migrations/20261029_product_stock.sql) ก่อน
- **เพิ่มเติม:** เพิ่มหน้าเจ้าของร้านสำหรับดู/กรองออเดอร์ ตรวจสลิป อนุมัติ/ปฏิเสธการชำระ และอัปเดตสถานะจัดเตรียม; การตรวจสลิปต้อง apply [`supabase/migrations/20261104_owner_order_review.sql`](supabase/migrations/20261104_owner_order_review.sql) และตั้ง RLS/Storage policies ให้ครบ
- **Week 6 — Final Delivery (ภายใน 4 พ.ย. 2569):** Android APK สำหรับทดสอบสร้างแล้วที่ `build/app/outputs/flutter-apk/app-release.apk`; มีลิงก์ GitHub และสคริปต์เดโมด้านล่าง

> แชทและแจ้งเตือนในแอปใช้ Supabase Realtime; ยังไม่มี push notification

ก่อนใช้แชท ให้รัน migration [`supabase/migrations/20261020_chat.sql`](supabase/migrations/20261020_chat.sql) ใน Supabase SQL Editor ด้วยบัญชีเจ้าของโปรเจกต์ แล้วตรวจว่าตาราง `user_roles` มี role `owner` ให้บัญชีแอดมินและเปิด Realtime สำหรับสองตารางแล้ว

ก่อนแก้ไข/ลบข้อความแชท ให้รัน `supabase/migrations/20261104_chat_message_edit_delete.sql` หลัง migration แชท เพื่อเพิ่ม `edited_at` และ policy ที่ให้แต่ละคนแก้/ลบได้เฉพาะข้อความของตัวเอง

ก่อนใช้หน้าตรวจสลิป ให้รัน migration `supabase/migrations/20261104_owner_order_review.sql` และตั้ง policy ให้เจ้าของร้านอ่าน `orders`, `order_items`, `payment_proofs` และอ่านไฟล์ใน private bucket `payment-proofs` ได้ การเพิ่ม migration ใน repository ไม่ได้ apply ไปยัง Supabase project โดยอัตโนมัติ

ก่อนยืนยันคำสั่งซื้อ ให้รัน migration `supabase/migrations/20261104_create_order_with_stock.sql` หลังจากสร้างตารางหลักแล้ว เพื่อเพิ่ม RPC ที่ checkout เรียกใช้และตัดสต๊อกแบบ transaction

ก่อนใช้การแจ้งเตือนออเดอร์ ให้รัน migration `supabase/migrations/20261104_order_notifications.sql` หลังจากสร้าง `notifications`, `user_roles`, `orders` และ `payment_proofs` แล้ว ตรวจ RLS ให้ผู้ใช้เห็นเฉพาะ notification ของตน และเปิด Realtime สำหรับตาราง `notifications`

## เริ่มต้นใช้งาน

ต้องติดตั้ง Flutter SDK ที่รองรับ Dart SDK `^3.12.2` และมีโปรเจกต์ Supabase ที่ตั้งค่าตาราง/Storage ให้ตรงกับ service ใน `lib/` ก่อน

```powershell
flutter pub get
flutter run
```

สร้าง APK สำหรับติดตั้งบน Android:

```powershell
flutter build apk --release
```

ผลลัพธ์: `build/app/outputs/flutter-apk/app-release.apk` (แพ็กเกจ `com.wongherm.bakery`, version `1.0.0`). APK นี้ใช้ debug signing key ตามการตั้งค่าปัจจุบัน เหมาะสำหรับติดตั้งทดสอบ/เดโมเท่านั้น; ก่อนเผยแพร่บน Play Store ให้ตั้งค่า release keystore ของเจ้าของแอปและตรวจว่า application ID เป็นของผู้เผยแพร่

แอปเชื่อมต่อ Supabase project ผ่าน `lib/main.dart` ปัจจุบัน URL และ anon key ถูกกำหนดในซอร์สโค้ด ให้ใช้ anon key เท่านั้น (ห้ามใส่ service-role key) และตั้งค่า Row Level Security/Storage policies ฝั่ง Supabase ก่อนเปิดใช้งานจริง

## ตรวจคุณภาพ

```powershell
flutter analyze
flutter test
```

รายละเอียด test cases และบันทึกบั๊กอยู่ใน [TEST_PLAN.md](TEST_PLAN.md). การทดสอบตะกร้าและ SQLite cache ไม่ต้องเชื่อมต่อ Supabase; การทดสอบ end-to-end ต้องมีบัญชีทดสอบและข้อมูลใน Supabase

## Demo สด (7–10 นาที)

1. **0:00–1:00** แนะนำ Wongherm Bakery และเป้าหมายการสั่งขนม
2. **1:00–2:00** เข้าสู่ระบบด้วยบัญชีลูกค้า และแสดงหน้ารายการ/หมวดหมู่
3. **2:00–3:00** ค้นหาสินค้า เปิดรายละเอียด และเพิ่มสินค้าลงตะกร้า
4. **3:00–4:30** ปรับจำนวน ตรวจยอด และยืนยันคำสั่งซื้อ
5. **4:30–5:30** อัปโหลดหลักฐานชำระเงิน และเปิดประวัติคำสั่งซื้อ
6. **5:30–6:30** เปิดแจ้งเตือนในแอปและแสดงสถานะอ่านแล้ว
7. **6:30–7:30** สลับบัญชีเจ้าของร้าน แสดงการจัดการสินค้า/อัปโหลดรูป (ถ้า backend พร้อม)
8. **7:30–9:00** สรุปสถาปัตยกรรม, ผลทดสอบ, known issues และแผนต่อยอด

## รายการส่งมอบก่อน 4 พ.ย. 2569

- GitHub: [BoonsitaWh/flutter_application_1](https://github.com/BoonsitaWh/flutter_application_1) (remote ที่ตั้งค่าใน repository นี้; ตรวจสิทธิ์และสถานะ push ก่อนวันส่ง)
- Android APK: `build/app/outputs/flutter-apk/app-release.apk` (สร้างแล้ว; debug-signed สำหรับทดสอบ)
- iOS TestFlight: ยังไม่มี iOS project ใน repository นี้; ต้องสร้าง iOS target, ตั้ง signing และเผยแพร่ TestFlight แยกต่างหาก
- README: มีขั้นตอนเริ่มต้น, สถานะฟีเจอร์, คำสั่งตรวจคุณภาพ, สคริปต์เดโม และข้อจำกัด
- เตรียมบัญชีเดโมแยกสำหรับลูกค้าและเจ้าของร้าน, ข้อมูลสินค้า, หลักฐานชำระเงินตัวอย่าง และเครือข่ายที่เชื่อม Supabase ได้

## Known limitations

- แชทใช้ได้เมื่อ deploy migration และ RLS/Realtime ฝั่ง Supabase แล้ว; ไม่มี push notification
- SQLite cache รองรับอ่าน catalog ล่าสุดตอนออฟไลน์; การเปลี่ยนสินค้าแบบ offline ยังไม่มี write queue และยังต้องบันทึกกับ Supabase ก่อน
- สต๊อกยังเป็นจำนวนที่เจ้าของร้านกรอกเอง; checkout ยังไม่ reserve/decrement แบบ transaction จึงไม่ควรใช้ยืนยันสต๊อกเมื่อมีคำสั่งซื้อพร้อมกัน
- ยังไม่มีคูปอง/ส่วนลด, payment gateway/ยืนยันยอดอัตโนมัติ, สรุปยอดขายใน dashboard, หรือการส่งรูปในแชท; รายละเอียดอยู่ใน [docs/BAKERY_REQUIREMENTS_REVIEW.md](docs/BAKERY_REQUIREMENTS_REVIEW.md)
- การสั่งซื้อ/แจ้งเตือน/อัปโหลดหลักฐานต้องพึ่ง Supabase schema, RLS และ Storage policies ที่ถูกต้อง
- APK ผ่านการ build และตรวจ APK signature/package metadata แล้ว แต่ยังไม่ได้ติดตั้งทดสอบบนอุปกรณ์จริง
