# راهنمای آپلود GameRush با Termux

این فایل ZIP را در یک پوشه استخراج کن تا ساختار پوشه‌ها حفظ شود. فایل‌ها را به‌صورت تخت و همگی در ریشه مخزن نریز؛ مسیرهایی مثل `game/` و `.github/workflows/` برای اجرای پروژه ضروری هستند.

## ۱) آماده‌سازی Termux

```bash
pkg update -y
pkg install git unzip -y
termux-setup-storage
```

## ۲) استخراج ZIP

فرض شده ZIP در پوشه Downloads اندروید است:

```bash
cd ~/storage/downloads
mkdir -p GameRushFiles
unzip -o GameRush_GitHub_Ready.zip -d GameRushFiles
cd GameRushFiles
```

## ۳) ساخت مخزن خالی در GitHub

در GitHub یک Repository خالی با نام `GameRush` بساز. گزینه افزودن README یا فایل اولیه را فعال نکن تا مخزن خالی بماند.

## ۴) ارسال همه فایل‌ها با حفظ پوشه‌ها

به‌جای `YOUR_USERNAME` نام کاربری GitHub خودت را قرار بده:

```bash
git init -b main
git add -A
git commit -m "Initial GameRush project"
git remote add origin https://github.com/YOUR_USERNAME/GameRush.git
git push -u origin main
```

اگر GitHub رمز خواست، به‌جای رمز حساب از Personal Access Token استفاده کن. توکن را در چت یا داخل فایل‌های پروژه نفرست.

## ۵) نکته مهم

- همه محتویات این پوشه باید در ریشه Repository با نام `GameRush` قرار بگیرند.
- پوشه مخفی `.github` را حذف نکن؛ Workflow ساخت وب و APK داخل آن است.
- پوشه‌های `game/`, `graphics/`, `audio/`, `ui/`, `native/` و `server/` باید حفظ شوند.
- پس از push، از تب Actions نتیجه ساخت را بررسی کن.
