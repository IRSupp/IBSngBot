<div align="center">

# 🤖 IBSng Bot — راهنمای نصب و مدیریت

**ربات تلگرام فروش سرویس روی بستر IBSng**

نصب یک‌خطه · به‌روزرسانی با یک کلیک · مدیریت آسان

[![Telegram Channel](https://img.shields.io/badge/کانال-@irsuppchannel-229ED9?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/irsuppchannel)
[![Support](https://img.shields.io/badge/پشتیبانی_و_خرید-@irsupplm__bot-229ED9?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/irsupplm_bot)

[![Docker Image](https://img.shields.io/badge/Docker_Hub-ibsngbot-2496ED?style=flat&logo=docker&logoColor=white)](https://hub.docker.com/r/boroumandhosein/ibsngbot/tags)
[![Platform](https://img.shields.io/badge/Ubuntu_%7C_Debian-supported-E95420?style=flat&logo=linux&logoColor=white)](#-پیشنیازها)

</div>

---

## 📋 فهرست

- [پیش‌نیازها](#-پیشنیازها)
- [نصب سریع](#-نصب-سریع-یکخطه)
- [منوی مدیریت](#-منوی-مدیریت)
- [به‌روزرسانی به آخرین نسخه](#-بهروزرسانی-به-آخرین-نسخه)
- [نصب یا تغییر به یک نسخه‌ی خاص](#-نصب-یا-تغییر-به-یک-نسخهی-خاص)
- [بازگشت به نسخه‌ی قبلی](#-بازگشت-به-نسخهی-قبلی-rollback)
- [پشتیبان‌گیری و بازیابی دیتابیس](#-پشتیبانگیری-و-بازیابی-دیتابیس)
- [مدیریت با دستورات داکر](#-مدیریت-با-دستورات-داکر-پیشرفته)
- [رفع اشکال رایج](#-رفع-اشکال-رایج)
- [پرسش‌های پرتکرار](#-پرسشهای-پرتکرار)
- [پشتیبانی](#-پشتیبانی)

---

## ✅ پیش‌نیازها

| مورد | حداقل |
|------|--------|
| سیستم‌عامل | Ubuntu 20.04+ / Debian 11+ |
| رم | 2 گیگابایت (برای اجرا) |
| دسترسی | کاربر `root` |
| Docker | به‌صورت خودکار توسط اسکریپت نصب می‌شود |

> 💡 یک توکن ربات از [@BotFather](https://t.me/BotFather) و آیدی عددی تلگرام خودتان (از [@userinfobot](https://t.me/userinfobot)) را از قبل آماده داشته باشید.

---

## 🚀 نصب سریع (یک‌خطه)

روی سرور، این دستور را اجرا کنید:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRSupp/IBSngBot/main/IRSupp-IBSngBot-Installer.sh)
```

سپس از منو، ابتدا **IBSng** و بعد **ربات** را نصب کنید. اسکریپت همه‌چیز (Docker، دیتابیس، کانتینرها) را خودکار راه‌اندازی می‌کند.

---

## 🎛 منوی مدیریت

با اجرای همان دستور نصب، منوی مدیریت باز می‌شود. دو بخش مجزا دارد:

### بخش ۱ — IBSng
### بخش ۲ — ربات

هر بخش این گزینه‌ها را دارد:

| گزینه | کار |
|-------|-----|
| 🟢 **Install** | نصب اولیه |
| 📊 **Status** | نمایش وضعیت (روشن/خاموش) |
| 📜 **Live Log** | مشاهده‌ی لاگ زنده |
| 🔄 **Restart** | ری‌استارت |
| ⬆️ **Update** | به‌روزرسانی به آخرین نسخه |
| 🗑 **Delete** | حذف |

---

## ⬆️ به‌روزرسانی به آخرین نسخه

هر وقت نسخه‌ی جدیدی منتشر شد (اطلاع‌رسانی در [کانال](https://t.me/irsuppchannel)):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRSupp/IBSngBot/main/IRSupp-IBSngBot-Installer.sh)
```

سپس: **بخش ۲ (ربات) → گزینه‌ی Update**

> ✅ دیتابیس و تنظیمات شما دست‌نخورده می‌مانند؛ فقط کد ربات به نسخه‌ی جدید ارتقا می‌یابد.

---

## 🎯 نصب یا تغییر به یک نسخه‌ی خاص

به‌طور پیش‌فرض همیشه آخرین نسخه (`latest`) نصب می‌شود. اگر بخواهید نسخه‌ی مشخصی را نصب کنید (مثلاً برای پایداری یا هماهنگی با راهنما)، از تگ نسخه استفاده کنید.

**۱) دیدن نسخه‌های موجود:**

فهرست کامل نسخه‌ها در داکرهاب:
👉 https://hub.docker.com/r/boroumandhosein/ibsngbot/tags

**۲) نصب یک نسخه‌ی خاص (مثلاً `1.0.5`):**

```bash
# نسخه‌ی موردنظر را بکشید
docker pull boroumandhosein/ibsngbot:1.0.5

# آن را به‌عنوان نسخه‌ی فعال علامت بزنید
docker tag boroumandhosein/ibsngbot:1.0.5 boroumandhosein/ibsngbot:latest

# کانتینر فعلی را بردارید و از منوی اسکریپت، بخش ربات → Restart (یا Update) را بزنید
docker rm -f ibsng_bot_app
```

سپس اسکریپت نصب را باز کنید و **بخش ۲ (ربات) → Restart** را بزنید تا با همان تنظیمات، نسخه‌ی انتخابی بالا بیاید.

> 💡 شماره‌ی نسخه را جایگزین `1.0.5` کنید. مثلاً برای نسخه‌ی `1.1.0`:
> `docker pull boroumandhosein/ibsngbot:1.1.0`

**۳) دیدن نسخه‌ی نصب‌شده‌ی فعلی:**

```bash
docker inspect --format '{{.Config.Image}}' ibsng_bot_app
docker images | grep ibsngbot
```

---

## ↩️ بازگشت به نسخه‌ی قبلی (Rollback)

اگر بعد از یک به‌روزرسانی مشکلی پیش آمد، به‌راحتی به نسخه‌ی قبلی برگردید:

```bash
# نسخه‌ی سالمِ قبلی را بکشید (شماره را جایگزین کنید)
docker pull boroumandhosein/ibsngbot:1.0.4

# آن را نسخه‌ی فعال کنید
docker tag boroumandhosein/ibsngbot:1.0.4 boroumandhosein/ibsngbot:latest

# کانتینر را بازسازی کنید
docker rm -f ibsng_bot_app
```

سپس از منوی اسکریپت، بخش ربات → **Restart** را بزنید.

> ✅ دیتابیس و تنظیمات شما در rollback هم دست‌نخورده می‌مانند.

---

## 💾 پشتیبان‌گیری و بازیابی دیتابیس

پیش از هر به‌روزرسانی مهم، یک پشتیبان بگیرید. دیتابیس داخل کانتینر `ibsng_bot_db` است.

**تهیه‌ی پشتیبان:**

```bash
docker exec ibsng_bot_db pg_dump -U ibsng_bot ibsng_bot > backup_$(date +%F).sql
```

فایلی مثل `backup_2026-01-15.sql` در پوشه‌ی فعلی ساخته می‌شود.

**بازیابی از پشتیبان:**

```bash
cat backup_2026-01-15.sql | docker exec -i ibsng_bot_db psql -U ibsng_bot -d ibsng_bot
```

> 💡 فایل پشتیبان را جایی امن (خارج از سرور) نگه دارید.

---

## 🐳 مدیریت با دستورات داکر (پیشرفته)

اگر ترجیح می‌دهید مستقیم با داکر کار کنید:

**نام کانتینرها:** ربات = `ibsng_bot_app` · دیتابیس = `ibsng_bot_db`

```bash
# وضعیت کانتینرها
docker ps

# لاگ زنده‌ی ربات (Ctrl+C برای خروج)
docker logs -f --tail 50 ibsng_bot_app

# فقط پیام‌های مهم (بدون هشدارهای بی‌ضرر)
docker logs --tail 200 ibsng_bot_app 2>&1 | grep -iv "PTBUserWarning"

# ری‌استارت ربات
docker restart ibsng_bot_app

# مصرف منابع
docker stats --no-stream
```

### به‌روزرسانی دستی

```bash
docker pull boroumandhosein/ibsngbot:latest
docker rm -f ibsng_bot_app
# سپس ربات را دوباره با همان تنظیمات اجرا کنید (یا از منوی Update اسکریپت استفاده کنید)
```

> 💡 ساده‌ترین و امن‌ترین راه به‌روزرسانی، همان گزینه‌ی **Update** در منوی اسکریپت است.

---

## 🩺 رفع اشکال رایج

<details>
<summary><b>ربات روشن نمی‌شود یا مدام ری‌استارت می‌شود</b></summary>

<br>

لاگ را بررسی کنید:

```bash
docker logs --tail 100 ibsng_bot_app 2>&1 | grep -iv "PTBUserWarning"
```

اگر خطای واضحی دیدید، متن آن را برای پشتیبانی بفرستید.

</details>

<details>
<summary><b>پیام «لایسنس نامعتبر» می‌بینم</b></summary>

<br>

معمولاً یک قطعی موقتی است و با ری‌استارت حل می‌شود:

```bash
docker restart ibsng_bot_app
```

اگر ادامه داشت، با پشتیبانی تماس بگیرید.

</details>

<details>
<summary><b>ادمین دوم را اضافه کردم ولی شناخته نمی‌شود</b></summary>

<br>

پس از ویرایش فایل تنظیمات، کانتینر باید **بازساخته** شود (نه فقط ری‌استارت). ساده‌ترین راه: از منوی اسکریپت گزینه‌ی **Update** یا **Restart** بخش ربات را بزنید.

</details>

<details>
<summary><b>فضای دیسک تمام شده</b></summary>

<br>

```bash
df -h /
docker system prune -f     # حذف موارد بدون‌استفاده‌ی داکر
```

</details>

<details>
<summary><b>سرویس داکر جواب نمی‌دهد</b></summary>

<br>

```bash
systemctl restart docker
```

</details>

---

## ❓ پرسش‌های پرتکرار

<details>
<summary><b>آیا با به‌روزرسانی، اطلاعات و تنظیماتم پاک می‌شود؟</b></summary>

<br>

نه. دیتابیس و تنظیمات شما در یک بخش جدا (volume) ذخیره می‌شوند و در به‌روزرسانی، rollback و ری‌استارت دست‌نخورده می‌مانند. فقط کد ربات عوض می‌شود.

</details>

<details>
<summary><b>هر چند وقت باید به‌روزرسانی کنم؟</b></summary>

<br>

هر وقت نسخه‌ی جدیدی در [کانال](https://t.me/irsuppchannel) اعلام شد. به‌روزرسانی اختیاری است ولی نسخه‌های جدید معمولاً رفع اشکال و قابلیت تازه دارند.

</details>

<details>
<summary><b>چند ادمین می‌توانم داشته باشم؟</b></summary>

<br>

محدودیتی ندارد. آیدی عددی ادمین‌ها را با کاما در فایل تنظیمات وارد کنید (مثال: `111111,222222`)، سپس ربات را از منوی اسکریپت **Restart** کنید. ادمین‌های با نقش محدود را هم می‌توانید از داخل خودِ ربات، بخش «مدیریت ادمین‌ها» اضافه کنید.

</details>

<details>
<summary><b>چطور بفهمم چه نسخه‌ای نصب است؟</b></summary>

<br>

```bash
docker inspect --format '{{.Config.Image}}' ibsng_bot_app
```

</details>

<details>
<summary><b>ربات و IBSng روی یک سرور هستند یا جدا؟</b></summary>

<br>

می‌توانند روی یک سرور باشند. اسکریپت نصب هر دو را جداگانه مدیریت می‌کند و ربات به‌صورت خودکار به IBSng محلی وصل می‌شود.

</details>

---

## 📞 پشتیبانی

<div align="center">

| | |
|---|---|
| 📢 کانال اطلاع‌رسانی | [@irsuppchannel](https://t.me/irsuppchannel) |
| 🔑 خرید و پشتیبانی | [@irsupplm_bot](https://t.me/irsupplm_bot) |

**قبل از تماس با پشتیبانی، لطفاً خروجی لاگ (`docker logs`) را آماده داشته باشید.**

</div>
