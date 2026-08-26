<div align="center">

# 🤖 IBSng Bot — راهنمای نصب و مدیریت

**ربات تلگرام فروش سرویس روی بستر IBSng**

نصب یک‌خطه · به‌روزرسانی با یک کلیک · مدیریت آسان

[![Telegram Channel](https://img.shields.io/badge/کانال-@irsuppchannel-229ED9?style=flat&logo=telegram&logoColor=white)](https://t.me/irsuppchannel)
[![Support](https://img.shields.io/badge/پشتیبانی_و_خرید-@irsupplm__bot-229ED9?style=flat&logo=telegram&logoColor=white)](https://t.me/irsupplm_bot)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=flat&logo=docker&logoColor=white)](https://hub.docker.com/)

</div>

---

## 📋 فهرست

- [پیش‌نیازها](#-پیشنیازها)
- [نصب سریع](#-نصب-سریع-یکخطه)
- [منوی مدیریت](#-منوی-مدیریت)
- [به‌روزرسانی به آخرین نسخه](#-بهروزرسانی-به-آخرین-نسخه)
- [مدیریت با دستورات داکر](#-مدیریت-با-دستورات-داکر-پیشرفته)
- [رفع اشکال رایج](#-رفع-اشکال-رایج)
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

## 📞 پشتیبانی

<div align="center">

| | |
|---|---|
| 📢 کانال اطلاع‌رسانی | [@irsuppchannel](https://t.me/irsuppchannel) |
| 🔑 خرید و پشتیبانی | [@irsupplm_bot](https://t.me/irsupplm_bot) |

**قبل از تماس با پشتیبانی، لطفاً خروجی لاگ (`docker logs`) را آماده داشته باشید.**

</div>
