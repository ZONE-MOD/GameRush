#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# GameRush: upload the current project to a new public GitHub repository.
# Run this script from the extracted project root in Termux.

if [[ -z "${PREFIX:-}" || "${PREFIX}" != *com.termux* ]]; then
  echo "این اسکریپت را داخل برنامه Termux اجرا کن."
  exit 1
fi

if [[ ! -f "project.godot" || ! -d "game" || ! -d ".github/workflows" ]]; then
  echo "خطا: پوشه ریشه پروژه پیدا نشد."
  echo "وارد پوشه‌ای شو که project.godot و پوشه‌های game و .github داخل آن هستند."
  exit 1
fi

echo "== GameRush GitHub uploader =="

pkg update -y
pkg install -y git gh

if ! gh auth status --hostname github.com >/dev/null 2>&1; then
  echo
  echo "برای دسترسی به GitHub باید یک بار ورود را تأیید کنی."
  gh auth login --hostname github.com --git-protocol https --web
fi

gh auth status --hostname github.com >/dev/null
GH_USER="$(gh api user --jq .login)"
GH_ID="$(gh api user --jq .id)"

read -r -p "نام Repository [GameRush]: " REPO
REPO="${REPO:-GameRush}"

if [[ ! "$REPO" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "نام Repository نامعتبر است."
  exit 1
fi

FULL_REPO="${GH_USER}/${REPO}"
echo
echo "حساب GitHub: ${GH_USER}"
echo "مخزن مقصد: https://github.com/${FULL_REPO}"
echo "مخزن به صورت Public ساخته می‌شود تا لینک وب بازی عمومی باشد."

if gh repo view "$FULL_REPO" >/dev/null 2>&1; then
  echo "Repository از قبل وجود دارد؛ از همان استفاده می‌کنم."
else
  gh repo create "$REPO" --public \
    --description "GameRush - Godot Android and Web game project"
fi

git init -b main
git config user.name "$GH_USER"
git config user.email "${GH_ID}+${GH_USER}@users.noreply.github.com"

git add -A
if git diff --cached --quiet; then
  echo "تغییری برای commit وجود ندارد."
else
  git commit -m "Upload GameRush project"
fi

if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "https://github.com/${FULL_REPO}.git"
else
  git remote add origin "https://github.com/${FULL_REPO}.git"
fi

git push -u origin main

# Configure GitHub Pages for a workflow-based deployment (best effort).
gh api -X POST "repos/${FULL_REPO}/pages" -f build_type=workflow >/dev/null 2>&1 || true

echo
echo "========================================"
echo "آپلود سورس با موفقیت انجام شد:"
echo "https://github.com/${FULL_REPO}"
echo "========================================"
echo
echo "اکنون اجرای GitHub Actions را بررسی می‌کنم..."

sleep 4
RUN_ID="$(gh run list --repo "$FULL_REPO" --branch main --limit 1 --json databaseId --jq '.[0].databaseId // empty' 2>/dev/null || true)"

if [[ -n "$RUN_ID" ]]; then
  if gh run watch "$RUN_ID" --repo "$FULL_REPO" --exit-status; then
    echo
    echo "ساخت و انتشار workflow موفق شد."
    PAGE_URL="$(gh api "repos/${FULL_REPO}/pages" --jq .html_url 2>/dev/null || true)"
    if [[ -n "$PAGE_URL" ]]; then
      echo "لینک بازی: ${PAGE_URL}"
    else
      echo "لینک Pages را در Settings > Pages بررسی کن."
    fi
    echo "APK: تب Actions > اجرای موفق > Artifacts > DinoRush-Android-debug"
  else
    echo
    echo "سورس آپلود شد، اما workflow خطا داد یا کامل نشد."
    echo "گزارش خطا: https://github.com/${FULL_REPO}/actions"
  fi
else
  echo "سورس آپلود شد. اجرای workflow را اینجا بررسی کن:"
  echo "https://github.com/${FULL_REPO}/actions"
fi
