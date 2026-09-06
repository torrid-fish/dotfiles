---
name: tmux-pane-collab
description: 與使用者在 tmux 的某個 pane 中協作。當使用者說「和我一起在…pane操作」、「跟我一起操作…pane」、「在…pane 協作」、或要求把指令/文字送到某個 tmux pane 執行時使用（例如「把這個指令送到 spark 那個 pane」「在 SER8 pane 上跑…」）。此 skill 教導如何：(1) 確認自己是否在 tmux 內、找出自己所在 window 與其他開著的 pane、或詢問使用者目標 pane 是哪一個；(2) 安全地把指令送進目標 pane 並與使用者協作——特別小心 local zsh 吃字元與目標互動式 zsh 的 history expansion / glob；(3) 讀回 pane 輸出。Use when collaborating inside a tmux pane via send-keys/capture-pane.
user-invocable: true
allowed-tools:
  - Bash(tmux *)
  - Bash(sleep *)
  - Bash(echo *)
  - Bash(grep *)
  - Read
---

# /tmux-pane-collab — 與使用者協作 tmux pane

當使用者要求「和我一起在…pane 操作」時，你透過 **tmux send-keys / capture-pane** 把指令送進目標 pane、讀回輸出、與使用者來回協作。你無法「進入」那個 pane 的 shell，一切都要隔著 tmux 操作。

> **最重要的規則**：指令字串會經過兩層 shell——(a) 你執行指令時的 **local zsh**（opencode 所在機器的 bash tool），(b) 目標 pane 裡的 shell（常常也是互動式 zsh，例如 ssh 到 spark 之後）。兩層都有字元會被吃掉或展開，見 Step 4。

---

## Step 1 — 確認自己是否在 tmux 內

```bash
echo "$TMUX"
tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}'
```

- `$TMUX` 有值（如 `/tmp/tmux-1000/default,398245,0`）→ 在 tmux 內。`display-message` 會回報你所在的 pane（例如 `0:0.0`），這就是「你自己」。
- `tmux: command not found` 或 `$TMUX` 為空 → **不在 tmux 內**。告知使用者「請先開啟 tmux 再執行 opencode」，然後停止，不要硬試。

## Step 2 — 盤點其他開著的 pane，確認目標

列出所有 session / window / pane：

```bash
tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} | title=#{pane_title} | cmd=#{pane_current_command} | cwd=#{pane_current_path}"
```

判讀：

- `cmd=opencode` 的那個 pane 就是你自己，剩下的才是「其他 pane」。
- 只有一個候選 → 直接用它。
- 多個候選 → 比對使用者提到的線索：pane title（例如 `SER8`）、`pane_current_command`（例如 `ssh`）、`cwd`、或視窗名稱。
- 比對不出來 → **問使用者**要哪一個，不要猜。若使用者只說「跟我一起操作」而沒有指定，列出候選清單讓使用者挑。

## Step 3 — 送出前先確認目標 pane 狀態

送出任何指令前，先看目標 pane 現在長怎樣：

```bash
tmux capture-pane -p -t 0:0.1          # 看目前畫面
tmux display-message -p -t 0:0.1 '#{pane_mode}'
```

- ⚠️ **`pane_current_command` 不可靠**：若目標是 ssh pane，remote 就算正在跑長指令，`cmd` 仍顯示 `ssh`。判斷 remote 是否空閒要用畫面內容：最後一行以 `✎`、`❯`、`$`、`#`、`~` 等 prompt 結尾 → 可以送指令。
- 畫面停在 **fullscreen app**（vim / less / htop / python REPL / 分頁器）→ 不要直接送 shell 指令，先詢問使用者，或改用該 app 自己的按鍵（如 `q`、`:` 指令）。
- `#{pane_mode}` 是 copy-mode → 先送 `q`（或 `Escape`）退出再操作。

## Step 4 — 安全地把指令送進 pane（zsh 陷阱大全）

基本語法：

```bash
tmux send-keys -t <pane> '<payload>' Enter
```

（也可以用 interactive_bash：`send-keys -t <pane> '<payload>' Enter`，效果相同。）

### (a) Local zsh 層——payload 一律用「單引號」包

你執行 bash tool 的 shell 是 **zsh**。用**單引號**包 payload，local 就完全不動裡面的字元：

```bash
# ✅ 正確：單引號 → $HOME 原封不動送到 remote
tmux send-keys -t 0:0.1 'echo $HOME' Enter

# ❌ 錯誤：雙引號 → $HOME、$(...)、反引號會被 local zsh 吃掉/先展開
tmux send-keys -t 0:0.1 "echo $HOME" Enter
```

單引號內要再放單引號（payload 含 `'`）→ 用 `'\''` 組合法：

```bash
# 送：python3 -c 'print("hi!")'
tmux send-keys -t 0:0.1 'python3 -c '\''print("hi!")'\''' Enter
```

多行 payload → 用 zsh 的 ANSI-C 引號 `$'...'`（`\n` 是真正換行）：

```bash
tmux send-keys -t 0:0.1 $'echo LINE1\necho LINE2' Enter
```

### (b) Remote 層——目標互動式 zsh 的坑

單引號只保護了 local；payload 送到目標 pane 後，目標的互動式 shell 會再解析一次。目標是 zsh（如 ssh 進 spark）時：

- **`!` 會觸發 history expansion，而且即使在雙引號內也照樣觸發** → 出現 `zsh: event not found`。要字面 `!` 時，remote 端用單引號包住該段，或寫 `\!`：
  ```bash
  # ✅ remote 端單引號包住 "!"
  tmux send-keys -t 0:0.1 'echo '\''hello!'\''' Enter
  # ✅ 或用 \! 跳脫
  tmux send-keys -t 0:0.1 'echo hello\!' Enter
  ```
- **Glob 會展開**（`*`、`?`、`[`），無相符檔時直接報 `zsh: no matches found`。要字面 `*` 時 remote 端加引號。
- `$VAR`、`$(...)`、反引號會在 **remote** 展開/執行（通常這就是你要的——例如查 remote 的 `$HOME`）。

### (c) 送出新行

payload 字串後面加 `Enter`（或 `C-m`）key 參數代表按下 Enter，不要把換行塞進 payload。

## Step 5 — 讀回輸出並與使用者協作

送出後先等輸出完成，再讀畫面：

```bash
tmux send-keys -t 0:0.1 'echo hello' Enter
sleep 1
tmux capture-pane -p -t 0:0.1 -S -200     # 讀 scrollback 200 行
```

- 以「echo 出的指令行」當錨點：在 capture 結果中找到最後一次出現的指令行，它**下方到下一行 prompt 之間**的內容就是這次的輸出。
- 輸出很長或只要關鍵資訊 → 過濾：
  ```bash
  tmux capture-pane -p -t 0:0.1 -S -200 | grep -a '關鍵字'
  ```
- 指令要跑很久 → 不要只 sleep 一次，改用輪詢：每 1–2 秒 capture 一次，直到最後一行回到 prompt 形狀（`✎/❯/$/#`）。
- 協作節奏：把關鍵輸出整理給使用者看，主動提出下一步並等使用者確認。你和使用者可以**同時**在那個 pane 上作業——先送完、確認輸出，再送下一個，避免互搶輸入行。

## Step 6 — 恢復與中斷

- 指令卡住 / 跑太久 → `tmux send-keys -t <pane> C-c`
- 一行打到一半想重來 → `tmux send-keys -t <pane> C-u`（清掉整行）再送新的
- 卡在分頁 / 搜尋 / REPL → 試 `q` 或 `Escape`

---

## Edge cases

- **多個 tmux session** → pane 一律用完整 `session:window.pane` 指定（如 `0:0.1`），別只寫 `0.1`。
- **ssh pane 的 remote prompt 判斷** → 看 capture 最後一行是否以 prompt 字元結尾，**不要**用 `pane_current_command`。
- **使用者描述的 pane 對不上清單**（title / ssh 目標 / 編號都不是）→ 列候選清單，問使用者。
- **不要主動送**會佔住互動的指令（`vim`、`top`、`htop`、互動式 REPL），除非使用者明確要求。
- **目標 pane 也是 opencode / 其他 agent** → 謹慎，先問使用者意圖。
- **送空白或只有換行** → 可能直接執行緩衝區殘留內容，先 `C-u` 清行再送。
