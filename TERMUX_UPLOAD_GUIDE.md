# آپلود خودکار GameRush با Termux

1. فایل ZIP را در پوشه Downloads گوشی ذخیره کن.
2. در Termux دسترسی فایل را بده و ZIP را استخراج کن:

   ```bash
   termux-setup-storage
   pkg update -y && pkg install unzip -y
   cd ~/storage/downloads
   unzip -o GameRush_GitHub_Ready.zip -d GameRush
   cd GameRush
   ```

3. اسکریپت را اجرا کن:

   ```bash
   bash upload_to_github_termux.sh
   ```

اسکریپت git و GitHub CLI را نصب می‌کند، ورود امن GitHub را از طریق مرورگر تأیید می‌گیرد، Repository عمومی GameRush را می‌سازد (یا از مخزن موجود استفاده می‌کند)، فایل‌ها را روی شاخه main می‌فرستد و اجرای GitHub Actions را بررسی می‌کند.

برای ساخت Repository و انتشار عمومی، باید خودت ورود GitHub را در مرورگر تأیید کنی. اسکریپت از توکن یا رمز عبور در متن فرمان نمی‌خواهد.
