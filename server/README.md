# Server preparation

The Cloudflare Worker URL supplied for the future admin panel is recorded in `config/game_config.json`. The Worker endpoints are not assumed to exist yet. This folder contains the D1 schema and API contract required before connecting accounts, coins, bans, verified badges, permanent username reservations, and online skin ownership.

Do not put admin keys, database credentials, signing secrets, or payment secrets in this repository. Add them as Cloudflare Worker secrets after the backend is implemented.

`api_client.gd` رابط سمت بازی برای مسیرهای پیشنهادی قرارداد API را آماده می‌کند؛ چون `api_enabled` فعلاً خاموش است، هیچ درخواست حساب آنلاینی ارسال نمی‌شود.
