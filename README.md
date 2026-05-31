# Security Configuration Analysis Tool

一套自動化分析 Windows 主機安全組態設定是否符合 GCB（政府組態基準）的 Python 工具。

---

## 📋 專案說明

本工具從 Windows 主機收集 `gpresult` 產生的 HTML 報表，解析其中的群組原則安全設定，並與預定義的 GCB/CIS 規則進行比對，最終輸出 CSV 格式的合規報表。

---

## 🗂 專案結構

```
.
├── auto.py                  # 主執行程式（三步驟流程）
├── auto_recoding.py         # 前處理：將原始 HTML 轉換為 UTF-8 編碼
├── SecurityConfiguration.py # 核心解析模組（HTML 解析、原則比對）
├── IniHelper.py             # settings.ini 組態讀取工具（Singleton）
├── ProgressBar.py           # 進度條顯示工具
├── inf_parser.py            # INF 規則檔解析工具
├── settings.ini             # 主要設定檔
├── requirements.txt         # Python 套件需求
├── config/
│   ├── rule_for_windows.csv # Windows GCB 比對規則（中英文原則名稱、期望值、比對運算子）
│   └── ...
├── collected_from_clients/  # 待分析的 HTML 報表（UTF-8 編碼）
├── original_files/          # 原始 HTML 報表（尚未轉碼）
├── raw_data.csv             # Step 1 輸出：所有主機的原則設定值
├── out.csv                  # Step 2 輸出：加入比對結果的原始資料
└── roadmap_v2.csv           # Step 3 輸出：以規則為列、主機為欄的報表
```

---

## ⚙️ 環境需求

- Python 3.8+
- 安裝相依套件：

```bash
pip install -r requirements.txt
```

| 套件 | 版本 |
|------|------|
| pandas | 1.2.4 |
| beautifulsoup4 | 4.9.3 |

---

## 🚀 使用流程

### 前置：轉換 HTML 編碼

將從客戶端收集到的 HTML 報表放入 `original_files/` 資料夾，然後執行：

```bash
python auto_recoding.py
```

此腳本會將所有 HTML 轉換為 UTF-8 編碼並儲存至 `collected_from_clients/`。

---

### 主要分析流程（三步驟）

執行 `auto.py` 將依序執行以下三個步驟：

```bash
python auto.py
```

#### Step 1：擷取安全設定
從 `collected_from_clients/` 中的所有 HTML 報表，解析每台主機的群組原則設定值（Policy / Setting / Winning GPO），輸出為 `raw_data.csv`。

#### Step 2：比對 GCB 規則
讀取 `raw_data.csv` 與 `config/rule_for_windows.csv`，依規則定義的比對運算子（`=`, `!=`, `>`, `<`, `>=`, `<=`, `~` 等）對每條原則進行合規判斷，輸出含比對結果的 `out.csv`。

#### Step 3：產生報表
以規則為列、主機為欄重整資料，產生便於橫向比較各主機合規狀況的 `roadmap_v2.csv` 報表。

---

## 🛠 設定檔說明（settings.ini）

```ini
[Data]
SourcePath=./collected_from_clients/   # HTML 報表來源路徑

[Rule]
Windows=./config/rule_for_windows.csv # Windows GCB 規則檔路徑
Linux=''                               # Linux 規則檔（尚未實作）
```

---

## 📐 規則檔格式（rule_for_windows.csv）

| 欄位 | 說明 |
|------|------|
| Name | 規則顯示名稱 |
| ch | 中文原則名稱 |
| en | 英文原則名稱 |
| rule_main | 主要期望值 |
| rule_sec | 次要期望值（備用） |
| operations | 比對運算子（`=`, `>`, `<`, `>=`, `<=`, `!=`, `~`） |

---

## 🐧 Linux 支援

`ForLinux/` 目錄及 `cis_benchmark-*.sh` Shell Script 提供 Linux 主機的 CIS Benchmark 檢查（CentOS 7，版本 2.1.1 ~ 2.1.3），Linux 自動化分析流程尚在開發中。

---

## 📝 已知問題 / TODO

- Linux 分析流程尚未整合至 `auto.py`
- `step3_make_report` 呼叫存在參數傳遞錯誤（第三引數誤傳函式本身而非檔名）
- 部分 HTML 格式異常時會略過並記錄至 `error_files`，建議執行後檢查錯誤清單

---

## 👤 作者

lungyu
