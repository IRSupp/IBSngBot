<div align="center">

# 🚀 IRSupp — IBSng & Telegram Bot Installer

**One-command installer for a customized IBSng server and the IRSupp IBSng Telegram bot.**

[![Docker](https://img.shields.io/badge/Docker-required-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Platform](https://img.shields.io/badge/Platform-Linux%20amd64-informational)](#requirements)
[![Telegram](https://img.shields.io/badge/Telegram-IRSupp-26A5E4?logo=telegram&logoColor=white)](https://t.me/irsuppchannel)

**[English](#-english) · [فارسی](#-فارسی)**

</div>

---

## 🇬🇧 English

### Overview

This repository provides a single interactive installer that sets up and manages two Docker stacks on a fresh Linux server:

| Component | What it is |
|---|---|
| **IBSng (IRSupp customized)** | The billing / provisioning backend — web panel, XML-RPC API, RADIUS. |
| **IRSupp IBSng Bot** | A Telegram bot for selling and managing VPN accounts, with its own PostgreSQL database. |

Both run as Docker containers with persistent volumes, so your data survives restarts, updates, and reinstalls.

### Requirements

- A fresh Linux server (Ubuntu 22.04 / 24.04 recommended)
- `root` access
- `amd64` architecture
- Internet access to Docker Hub

Docker is installed automatically if it is missing.

### Installation

Run this single command on your server:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRSupp/IBSngBot/main/IRSupp-IBSngBot-Installer.sh)
```

> The installer needs `root`. If you are not root, prefix the command with `sudo`.

You will see the main menu:

```
═══════════════════════════════════════════════
        IRSupp Installer — IBSng & Bot
═══════════════════════════════════════════════

  IBSng : running  version latest
  Bot   : running  version 1.0.2

  1) Install IBSng IRSupp Customize version
  2) Install IRSupp IBSng Bot
  3) Exit
```

Each component has its own sub-menu:

```
  1) Install / Reinstall
  2) Status
  3) Live Log
  4) Restart
  5) Update (pull latest image)
  6) Delete (keeps data volume)
  7) Back
```

### Recommended order

1. **Install IBSng first** (option 1). You will be asked for four ports — press Enter to accept the defaults:

   | Port | Default | Purpose |
   |---|---|---|
   | Web | `80` | IBSng admin panel |
   | API | `1235` | XML-RPC — the bot connects here |
   | RADIUS auth | `1812/udp` | Authentication |
   | RADIUS acct | `1813/udp` | Accounting |

   Default panel login: user `system` / password `admin` — **change it immediately.**

2. **Install the Bot** (option 2). You will be asked for:

   - **Bot token** — from [@BotFather](https://t.me/BotFather)
   - **Admin numeric IDs** — comma-separated (e.g. `123456,789012`)
   - **License key** — see [Contact & License](#-contact--license--ارتباط-و-لایسنس) at the bottom of this page
   - **License server URL** — press Enter for the default

   Everything else (encryption key, database password, hardware ID) is generated automatically.

3. **Connect the bot to IBSng.** In the bot's server settings use:

   ```
   host = 127.0.0.1        API port = 1235
   ```

### Updating

Rebuilding is never required on your side — just pull the new image:

**Menu → component → `5) Update`**

Your database, settings, and license stay untouched. The `build` ID shown in the menu changes after a successful update.

### Data & persistence

| Volume | Contents |
|---|---|
| `ibsng_pgdata` | IBSng database |
| `ibsng_bot_pgdata` | Bot database (users, plans, payments, tickets) |

`Delete` removes containers but **keeps these volumes**, so reinstalling restores your data.

Bot configuration is stored at `/opt/ibsng_bot/bot.env` (permissions `600`).

### Backup

```bash
# Bot database
docker exec ibsng_bot_db pg_dump -U ibsng_bot ibsng_bot > bot-backup.sql

# Restore
cat bot-backup.sql | docker exec -i ibsng_bot_db psql -U ibsng_bot ibsng_bot
```

Also keep a copy of `/opt/ibsng_bot/bot.env` — it contains your `FERNET_KEY`.

---

### 🔧 Troubleshooting

<details>
<summary><b>The bot container keeps restarting</b></summary>

Check the logs first:

**Menu → 2 → 3 (Live Log)**

Common causes:

- **Invalid bot token** — the token was mistyped. Reinstall (option 1) and re-enter it.
- **License error** — verify `LICENSE_KEY` and `LICENSE_SERVER` in `/opt/ibsng_bot/bot.env`, then restart.
- **Database not ready** — the bot retries for ~30 seconds. If it still fails, check that `ibsng_bot_db` is running with `docker ps`.

</details>

<details>
<summary><b>The bot cannot connect to IBSng</b></summary>

The bot runs with host networking, so it reaches IBSng over `127.0.0.1`.

In the bot's server settings, make sure you used:

```
host = 127.0.0.1
API port = 1235   (or the port you chose during IBSng installation)
```

Verify the API port is actually published:

```bash
docker port ibsng
```

You should see a line mapping `1235/tcp`.

</details>

<details>
<summary><b>Port already in use</b></summary>

If installation fails with a port conflict, something else on the server is using that port. Either stop it, or reinstall and choose different ports:

```bash
ss -tulpn | grep -E ':80|:1235'
```

</details>

<details>
<summary><b>Docker Hub pull fails (403 / timeout)</b></summary>

This is usually a transient network issue. Simply retry — Docker resumes partial downloads. If it keeps failing, pull the base image separately first:

```bash
docker pull python:3.12-slim
```

</details>

<details>
<summary><b>I moved the bot to a new server and the license stopped working</b></summary>

The license is bound to a stable `HARDWARE_ID` derived from the server's machine ID. Moving servers requires a **re-issued license** for the new hardware ID.

Find your current hardware ID:

```bash
grep HARDWARE_ID /opt/ibsng_bot/bot.env
```

Then contact support to have the license re-issued.

</details>

<details>
<summary><b>I lost my FERNET_KEY</b></summary>

`FERNET_KEY` encrypts the stored IBSng server passwords. **Without it, those passwords cannot be decrypted.**

If it is lost, you must re-enter the IBSng server credentials in the bot's admin panel after reinstalling.

Never change this key on a working installation.

</details>

<details>
<summary><b>How do I see full logs / stop following them?</b></summary>

**Menu → component → 3 (Live Log)** shows the last 200 lines and keeps streaming new output.

Press **Ctrl+C** to stop and return to the shell.

For a one-off look without the menu:

```bash
docker logs --tail 100 ibsng_bot_app
docker logs --tail 100 ibsng
```

</details>

<details>
<summary><b>Securing the IBSng API port</b></summary>

The API port (`1235`) is published on all interfaces. If your server is publicly reachable, restrict it with a firewall:

```bash
ufw allow from 127.0.0.1 to any port 1235
ufw deny 1235
```

</details>

---

<div align="right">

## 🇮🇷 فارسی

### معرفی

این ریپازیتوری یک نصب‌کننده‌ی تعاملی است که دو سرویس داکری را روی یک سرور لینوکس تازه نصب و مدیریت می‌کند:

| بخش | توضیح |
|---|---|
| **IBSng (نسخه‌ی سفارشی IRSupp)** | هسته‌ی حساب‌داری و ارائه‌ی سرویس — پنل وب، API از نوع XML-RPC و RADIUS |
| **ربات IBSng آی‌آر‌ساپورت** | ربات تلگرام برای فروش و مدیریت اکانت‌های VPN، همراه با دیتابیس PostgreSQL اختصاصی |

هر دو به‌صورت کانتینر داکر با فضای ذخیره‌سازی ماندگار اجرا می‌شوند؛ بنابراین داده‌ها پس از ری‌استارت، به‌روزرسانی و نصب مجدد باقی می‌مانند.

### پیش‌نیازها

- یک سرور لینوکس تازه (اوبونتو ۲۲.۰۴ یا ۲۴.۰۴ توصیه می‌شود)
- دسترسی `root`
- معماری `amd64`
- دسترسی اینترنت به Docker Hub

اگر داکر نصب نباشد، به‌صورت خودکار نصب می‌شود.

### نصب

این یک دستور را روی سرور اجرا کنید:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/IRSupp/IBSngBot/main/IRSupp-IBSngBot-Installer.sh)
```

> نصب‌کننده به دسترسی `root` نیاز دارد. اگر کاربر root نیستید، ابتدای دستور `sudo` بگذارید.

منوی اصلی نمایش داده می‌شود:

```
═══════════════════════════════════════════════
        IRSupp Installer — IBSng & Bot
═══════════════════════════════════════════════

  IBSng : running  version latest
  Bot   : running  version 1.0.2

  1) Install IBSng IRSupp Customize version
  2) Install IRSupp IBSng Bot
  3) Exit
```

هر بخش زیرمنوی خودش را دارد:

```
  1) Install / Reinstall     نصب / نصب مجدد
  2) Status                  وضعیت
  3) Live Log                نمایش زنده‌ی لاگ
  4) Restart                 ری‌استارت
  5) Update                  به‌روزرسانی
  6) Delete                  حذف (داده‌ها حفظ می‌شود)
  7) Back                    بازگشت
```

### ترتیب پیشنهادی نصب

۱. **ابتدا IBSng را نصب کنید** (گزینه‌ی ۱). چهار پورت از شما پرسیده می‌شود؛ برای مقادیر پیش‌فرض فقط Enter بزنید:

| پورت | پیش‌فرض | کاربرد |
|---|---|---|
| وب | `80` | پنل مدیریت IBSng |
| API | `1235` | XML-RPC — ربات از این پورت وصل می‌شود |
| RADIUS auth | `1812/udp` | احراز هویت |
| RADIUS acct | `1813/udp` | حساب‌داری |

ورود پیش‌فرض پنل: کاربر `system` و رمز `admin` — **بلافاصله تغییرش دهید.**

۲. **سپس ربات را نصب کنید** (گزینه‌ی ۲). این موارد پرسیده می‌شود:

- **توکن ربات** — از [@BotFather](https://t.me/BotFather)
- **آیدی عددی ادمین‌ها** — با کاما جدا شده (مثل `123456,789012`)
- **کلید لایسنس** — به بخش [ارتباط و لایسنس](#-contact--license--ارتباط-و-لایسنس) در انتهای صفحه مراجعه کنید
- **آدرس سرور لایسنس** — برای مقدار پیش‌فرض Enter بزنید

بقیه‌ی موارد (کلید رمزنگاری، رمز دیتابیس و شناسه‌ی سخت‌افزار) خودکار ساخته می‌شوند.

۳. **اتصال ربات به IBSng.** در تنظیمات سرور داخل ربات این مقادیر را وارد کنید:

```
host = 127.0.0.1        API port = 1235
```

### به‌روزرسانی

لازم نیست چیزی را خودتان build کنید — فقط ایمیج جدید را دریافت کنید:

**منو ← بخش موردنظر ← گزینه‌ی `5) Update`**

دیتابیس، تنظیمات و لایسنس شما دست‌نخورده باقی می‌مانند. پس از به‌روزرسانی موفق، شناسه‌ی `build` در منو تغییر می‌کند.

### داده‌ها و ماندگاری

| Volume | محتوا |
|---|---|
| `ibsng_pgdata` | دیتابیس IBSng |
| `ibsng_bot_pgdata` | دیتابیس ربات (کاربران، پلن‌ها، پرداخت‌ها، تیکت‌ها) |

گزینه‌ی `Delete` فقط کانتینرها را حذف می‌کند و **این volumeها را نگه می‌دارد**؛ بنابراین با نصب مجدد، داده‌ها برمی‌گردند.

تنظیمات ربات در مسیر `/opt/ibsng_bot/bot.env` ذخیره می‌شود (با دسترسی `600`).

### پشتیبان‌گیری

```bash
# دیتابیس ربات
docker exec ibsng_bot_db pg_dump -U ibsng_bot ibsng_bot > bot-backup.sql

# بازیابی
cat bot-backup.sql | docker exec -i ibsng_bot_db psql -U ibsng_bot ibsng_bot
```

از فایل `/opt/ibsng_bot/bot.env` هم نسخه‌ی پشتیبان بگیرید — کلید `FERNET_KEY` در آن است.

---

### 🔧 عیب‌یابی

<details>
<summary><b>کانتینر ربات مدام ری‌استارت می‌شود</b></summary>

ابتدا لاگ را ببینید:

**منو ← ۲ ← ۳ (Live Log)**

دلایل رایج:

- **توکن نامعتبر** — توکن اشتباه وارد شده. نصب مجدد (گزینه‌ی ۱) و وارد کردن دوباره‌ی توکن.
- **خطای لایسنس** — مقادیر `LICENSE_KEY` و `LICENSE_SERVER` را در `/opt/ibsng_bot/bot.env` بررسی و سپس ری‌استارت کنید.
- **آماده نبودن دیتابیس** — ربات حدود ۳۰ ثانیه تلاش می‌کند. اگر باز هم شکست خورد، با `docker ps` مطمئن شوید کانتینر `ibsng_bot_db` در حال اجراست.

</details>

<details>
<summary><b>ربات به IBSng وصل نمی‌شود</b></summary>

ربات روی شبکه‌ی میزبان اجرا می‌شود، بنابراین از طریق `127.0.0.1` به IBSng دسترسی دارد.

در تنظیمات سرور داخل ربات مطمئن شوید این مقادیر را وارد کرده‌اید:

```
host = 127.0.0.1
API port = 1235   (یا پورتی که هنگام نصب IBSng انتخاب کردید)
```

بررسی کنید پورت API واقعاً منتشر شده باشد:

```bash
docker port ibsng
```

باید خطی ببینید که `1235/tcp` را map کرده است.

</details>

<details>
<summary><b>پورت از قبل اشغال است</b></summary>

اگر نصب به‌دلیل تداخل پورت شکست خورد، سرویس دیگری روی سرور از آن پورت استفاده می‌کند. یا آن را متوقف کنید یا هنگام نصب مجدد پورت دیگری انتخاب کنید:

```bash
ss -tulpn | grep -E ':80|:1235'
```

</details>

<details>
<summary><b>دریافت ایمیج از Docker Hub شکست می‌خورد (خطای 403 یا timeout)</b></summary>

معمولاً یک مشکل موقتی شبکه است. دوباره تلاش کنید — داکر دانلود نیمه‌تمام را ادامه می‌دهد. اگر باز هم ادامه داشت، ابتدا ایمیج پایه را جداگانه بگیرید:

```bash
docker pull python:3.12-slim
```

</details>

<details>
<summary><b>ربات را به سرور جدید منتقل کردم و لایسنس کار نمی‌کند</b></summary>

لایسنس به یک `HARDWARE_ID` پایدار گره خورده که از machine-id سرور ساخته می‌شود. با تغییر سرور، لایسنس باید برای شناسه‌ی سخت‌افزار جدید **مجدداً صادر شود**.

شناسه‌ی فعلی را ببینید:

```bash
grep HARDWARE_ID /opt/ibsng_bot/bot.env
```

سپس برای صدور مجدد لایسنس با پشتیبانی تماس بگیرید.

</details>

<details>
<summary><b>کلید FERNET_KEY را گم کرده‌ام</b></summary>

`FERNET_KEY` رمزهای ذخیره‌شده‌ی سرورهای IBSng را رمزنگاری می‌کند. **بدون آن، این رمزها قابل بازگشایی نیستند.**

اگر گم شد، پس از نصب مجدد باید اطلاعات ورود سرورهای IBSng را دوباره در پنل ادمین ربات وارد کنید.

روی یک نصب سالم هرگز این کلید را تغییر ندهید.

</details>

<details>
<summary><b>چطور لاگ کامل را ببینم یا از آن خارج شوم؟</b></summary>

**منو ← بخش موردنظر ← ۳ (Live Log)** ابتدا ۲۰۰ خط آخر را نشان می‌دهد و سپس خروجی جدید را زنده ادامه می‌دهد.

با زدن **Ctrl+C** خارج می‌شوید و به خط فرمان برمی‌گردید.

برای یک نگاه سریع بدون منو:

```bash
docker logs --tail 100 ibsng_bot_app
docker logs --tail 100 ibsng
```

</details>

<details>
<summary><b>امن‌سازی پورت API در IBSng</b></summary>

پورت API (`1235`) روی همه‌ی رابط‌های شبکه منتشر می‌شود. اگر سرور شما از اینترنت قابل دسترسی است، با فایروال محدودش کنید:

```bash
ufw allow from 127.0.0.1 to any port 1235
ufw deny 1235
```

</details>

</div>

---

<div align="center">

## 📞 Contact & License · ارتباط و لایسنس

### Buying a license · خرید لایسنس

The bot requires a valid license key tied to your server.
ربات برای کار کردن به یک کلید لایسنس معتبر که به سرور شما گره خورده نیاز دارد.

<br>

[![Telegram Channel](https://img.shields.io/badge/📢_IRSupp_Channel-26A5E4?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/irsuppchannel)

[![Buy License](https://img.shields.io/badge/🔑_Buy_Bot_License-2AABEE?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/irsupplm_bot)

<br>

| | |
|---|---|
| 📢 **Telegram Channel** | [@irsuppchannel](https://t.me/irsuppchannel) |
| 🔑 **Buy Bot License** | [@irsupplm_bot](https://t.me/irsupplm_bot) |

<br>

<sub>© IRSupp — All rights reserved.</sub>

</div>
