# Omise Android

โปรเจกต์นี้เป็นการใช้งาน Omise API สำหรับการชำระเงินผ่านแอปพลิเคชัน Android โดยใช้ Omise SDK เพื่อให้สามารถรับชำระเงินด้วยบัตรเครดิตหรือบัตรเดบิตจากผู้ใช้งานได้อย่างง่ายดายและปลอดภัย

## การติดตั้ง

1. **Clone Repository:**

```
git clone https://github.com/micsmic611/omiseandroid.git
```
2. **ติดตั้ง Dependencies:**
ใช้ Android Studio เพื่อติดตั้งและทำการสร้างโปรเจกต์

เปิดไฟล์ `build.gradle` แล้วทำการติดตั้ง dependencies ที่จำเป็น:
```gradle
dependencies {
    implementation 'co.omise.android:omise-android:1.6.3'
    implementation 'com.google.android.material:material:1.3.0'
}
```
3. **ตั้งค่า API Key:**

    ลงทะเบียนกับ Omise เพื่อรับ public key และ secret key

## การแสดงผลการชำระเงิน (Display Payment Status)
การสร้างการชำระเงิน (Create Payment)
โปรเจกต์นี้จะช่วยให้ผู้ใช้สามารถสร้างการชำระเงินได้ โดยทำการเรียกใช้ Omise API สำหรับการรับข้อมูลการชำระเงินจากผู้ใช้
ตัวอย่างโค้ด:
```
OmiseCard card = new OmiseCard("tokn_test_4ybnth7i68d5djtf7mc");

// สร้างการชำระเงิน
OmiseAPI omiseAPI = new OmiseAPI("your_secret_key");
omiseAPI.createCharge(card, new OmiseCallback<Charge>() {
    @Override
    public void onSuccess(Charge charge) {
        Log.d("Charge", charge.toString());
        // ประมวลผลหลังจากการชำระเงินสำเร็จ
    }

    @Override
    public void onError(Throwable throwable) {
        Log.e("Error", throwable.getMessage());
        // ประมวลผลหากเกิดข้อผิดพลาด
    }
});
```
หลังจากการชำระเงินเสร็จสิ้น, การแสดงผลการชำระเงินจะถูกอัพเดตในแอปพลิเคชันเพื่อตรวจสอบสถานะของการชำระเงิน

ตัวอย่างโค้ด:
```
if (charge.isSucceeded()) {
    // แสดงข้อความการชำระเงินสำเร็จ
    Toast.makeText(context, "การชำระเงินสำเร็จ", Toast.LENGTH_SHORT).show();
} else {
    // แสดงข้อความการชำระเงินล้มเหลว
    Toast.makeText(context, "การชำระเงินล้มเหลว", Toast.LENGTH_SHORT).show();
}
```
