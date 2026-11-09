<#
作者 startgo (startgo@yia.app)
授權預設 GPLv3
時間: 2026-11-09 18:30:00 UTC+8
版本: v1.31.10
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Get-AvailablePort {
    $listener = New-Object System.Net.Sockets.TcpListener ([System.Net.IPAddress]::Loopback, 0)
    try {
        $listener.Start()
        $assignedPort = ([System.Net.IPEndPoint]$listener.LocalEndpoint).Port
        $listener.Stop()
        return $assignedPort
    }
    catch {
        throw "無法動態取得可用 TCP 連接埠: $($_.Exception.Message)"
    }
}

try {
    $CurrentDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    if (-not $CurrentDir) { $CurrentDir = Get-Location }
    $HtmlFilePath = Join-Path -Path $CurrentDir -ChildPath "index.html"

    $Port = Get-AvailablePort
    $Prefix = "http://127.0.0.1:$Port/"

    $HtmlSource = @'
<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>MarkItDown (Pyodide WASM Engine)</title>
  <script src="https://cdn.jsdelivr.net/pyodide/v0.26.2/full/pyodide.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/pdf-lib/dist/pdf-lib.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/@pdf-lib/fontkit/dist/fontkit.umd.min.js"></script>
  <style>
    :root {
      --bg-color: #0f172a;
      --panel-bg: #1e293b;
      --border-color: #334155;
      --accent: #38bdf8;
      --text: #f8fafc;
      --text-dim: #94a3b8;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Hiragino Kaku Gothic ProN", "Hiragino Sans", Meiryo, sans-serif;
      background: var(--bg-color);
      color: var(--text);
      display: flex;
      flex-direction: column;
      height: 100vh;
      overflow: hidden;
    }
    header {
      padding: 8px 16px;
      background: var(--panel-bg);
      border-bottom: 1px solid var(--border-color);
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-shrink: 0;
      gap: 12px;
    }
    .brand-group { display: flex; align-items: center; gap: 10px; min-width: 0; flex-shrink: 1; }
    h1 { font-size: 0.95rem; font-weight: 600; color: var(--accent); white-space: nowrap; }
    #status { font-size: 0.78rem; color: var(--text-dim); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .nav-actions { display: flex; align-items: center; gap: 6px; flex-shrink: 0; }
    select, button, label.btn {
      background: #0284c7;
      color: #fff;
      border: 1px solid transparent;
      padding: 4px 9px;
      border-radius: 4px;
      font-size: 0.78rem;
      cursor: pointer;
      transition: background 0.15s, border-color 0.15s;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      outline: none;
      white-space: nowrap;
      user-select: none;
    }
    select {
      background: #334155;
      border-color: var(--border-color);
    }
    button:hover, label.btn:hover { background: #0369a1; }
    button.secondary, label.btn.secondary { background: #334155; border-color: var(--border-color); }
    button.secondary:hover, label.btn.secondary:hover { background: #475569; }
    button:disabled { background: #475569; cursor: not-allowed; opacity: 0.6; }
    input[type="file"] { display: none; }
    main {
      display: flex;
      flex: 1;
      gap: 12px;
      padding: 12px;
      overflow: hidden;
    }
    .panel {
      flex: 1;
      background: var(--panel-bg);
      border: 1px solid var(--border-color);
      border-radius: 8px;
      display: flex;
      flex-direction: column;
      overflow: hidden;
      min-width: 0;
    }
    .panel-header {
      padding: 6px 12px;
      border-bottom: 1px solid var(--border-color);
      display: flex;
      justify-content: space-between;
      align-items: center;
      background: rgba(255, 255, 255, 0.02);
      flex-shrink: 0;
      gap: 8px;
    }
    .panel-title-group {
      display: flex;
      align-items: center;
      gap: 8px;
      flex-shrink: 0;
    }
    .panel-title {
      font-size: 0.82rem;
      font-weight: 600;
      white-space: nowrap;
    }
    .tab-group {
      display: inline-flex;
      background: #0f172a;
      padding: 2px;
      border-radius: 4px;
      border: 1px solid var(--border-color);
      gap: 2px;
    }
    button.tab-btn {
      background: transparent;
      color: var(--text-dim);
      border: none;
      padding: 2px 8px;
      font-size: 0.74rem;
      border-radius: 3px;
      cursor: pointer;
      transition: background 0.15s, color 0.15s;
      line-height: 1.2;
    }
    button.tab-btn.active {
      background: var(--accent);
      color: #0f172a;
      font-weight: 600;
    }
    .actions {
      display: flex;
      gap: 5px;
      align-items: center;
      flex-wrap: nowrap;
      flex-shrink: 0;
    }
    .panel-content {
      flex: 1;
      position: relative;
      display: flex;
      overflow: hidden;
    }
    textarea {
      flex: 1;
      width: 100%;
      height: 100%;
      background: transparent;
      border: none;
      color: var(--text);
      padding: 12px;
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
      font-size: 0.82rem;
      resize: none;
      outline: none;
      line-height: 1.5;
    }
    .md-preview-pane {
      flex: 1;
      width: 100%;
      height: 100%;
      overflow-y: auto;
      padding: 16px 20px;
      background: #0b1329;
      color: #e2e8f0;
      line-height: 1.65;
      font-size: 0.86rem;
      display: none;
    }
    .md-preview-pane h1, .md-preview-pane h2, .md-preview-pane h3 {
      color: var(--accent);
      margin: 14px 0 6px 0;
      border-bottom: 1px solid var(--border-color);
      padding-bottom: 4px;
    }
    .md-preview-pane p { margin-bottom: 10px; }
    .md-preview-pane ul, .md-preview-pane ol { padding-left: 20px; margin-bottom: 10px; }
    .md-preview-pane blockquote {
      border-left: 3px solid var(--accent);
      margin: 10px 0;
      padding-left: 10px;
      color: var(--text-dim);
    }
    .md-preview-pane pre {
      background: #1e293b;
      padding: 10px;
      border-radius: 4px;
      overflow-x: auto;
      margin-bottom: 10px;
      border: 1px solid var(--border-color);
    }
    .md-preview-pane code {
      font-family: ui-monospace, monospace;
      background: #1e293b;
      padding: 2px 4px;
      border-radius: 3px;
      font-size: 0.78rem;
    }
    .md-preview-pane table {
      border-collapse: collapse;
      width: 100%;
      margin: 10px 0;
    }
    .md-preview-pane th, .md-preview-pane td {
      border: 1px solid var(--border-color);
      padding: 5px 8px;
      text-align: left;
    }
    .md-preview-pane th {
      background: rgba(255, 255, 255, 0.05);
    }
    .modal-overlay {
      display: none;
      position: fixed;
      top: 0; left: 0; width: 100vw; height: 100vh;
      background: rgba(0, 0, 0, 0.7);
      backdrop-filter: blur(2px);
      z-index: 1000;
      justify-content: center;
      align-items: center;
    }
    .modal-card {
      background: var(--panel-bg);
      border: 1px solid var(--border-color);
      border-radius: 8px;
      width: 620px;
      max-width: 92%;
      max-height: 82vh;
      display: flex;
      flex-direction: column;
      box-shadow: 0 10px 25px rgba(0,0,0,0.5);
    }
    .modal-header {
      padding: 12px 16px;
      border-bottom: 1px solid var(--border-color);
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .modal-header h2 { font-size: 0.92rem; color: var(--accent); }
    .modal-body {
      padding: 16px;
      overflow-y: auto;
      font-size: 0.81rem;
      color: var(--text-dim);
      line-height: 1.6;
    }
    .license-block { margin-bottom: 12px; }
    .license-author { color: var(--accent); font-weight: 600; margin-bottom: 6px; }
    .ref-section { border-top: 1px solid var(--border-color); padding-top: 10px; }
    .ref-title { font-weight: 600; color: var(--text); margin-bottom: 8px; }
    .ref-list { list-style: none; display: grid; grid-template-columns: 1fr 1fr; gap: 6px; }
    .ref-list li { margin-bottom: 2px; }
    .ref-list a { color: var(--accent); text-decoration: none; }
    .ref-list a:hover { text-decoration: underline; }
    .modal-footer {
      padding: 10px 16px;
      border-top: 1px solid var(--border-color);
      display: flex;
      justify-content: flex-end;
    }
  </style>
</head>
<body>
  <header>
    <div class="brand-group">
      <h1 data-i18n="app_title">MarkItDown (Pyodide WASM Engine)</h1>
      <div id="status"></div>
    </div>
    <div class="nav-actions">
      <select id="lang-select" onchange="changeLanguage(this.value)">
        <option value="zh-TW">繁體中文</option>
        <option value="en">English</option>
      </select>
      <label class="btn secondary" for="lang-file-input" data-i18n="btn_load_i18n">載入語系包</label>
      <input type="file" id="lang-file-input" accept=".json">
      <button class="secondary" onclick="toggleLicenseModal(true)" data-i18n="btn_license">開源授權</button>
    </div>
  </header>

  <main>
    <section class="panel">
      <div class="panel-header">
        <span class="panel-title" data-i18n="panel_doc_to_md">文件解析轉 Markdown</span>
        <div class="actions">
          <label class="btn" for="doc-input" id="doc-btn-label" data-i18n="btn_select_file">選擇檔案 (PDF/HTML)</label>
          <input type="file" id="doc-input" accept=".pdf, .html, .htm" disabled>
        </div>
      </div>
      <div class="panel-content">
        <textarea id="output-md" data-i18n-placeholder="placeholder_output_md" placeholder="轉換後的 Markdown 將顯示於此..." readonly></textarea>
      </div>
    </section>

    <section class="panel">
      <div class="panel-header">
        <div class="panel-title-group">
          <span class="panel-title" data-i18n="panel_md_export">Markdown 編輯與預覽</span>
          <div class="tab-group">
            <button id="tab-btn-edit" class="tab-btn active" onclick="switchMdTab('edit')" data-i18n="tab_edit">編輯</button>
            <button id="tab-btn-preview" class="tab-btn" onclick="switchMdTab('preview')" data-i18n="tab_preview">預覽</button>
          </div>
        </div>
        <div class="actions">
          <label class="btn secondary" for="md-input-file" data-i18n="btn_load_md">載入 MD</label>
          <input type="file" id="md-input-file" accept=".md, .markdown, text/markdown, text/plain">
          <button id="btn-export-html" class="secondary" onclick="exportMdToHtml()" data-i18n="btn_export_html">匯出 HTML</button>
          <button id="btn-export-pdf" onclick="exportFullEnginePdf()" data-i18n="btn_export_pdf">輸出可逆 PDF</button>
        </div>
      </div>
      <div class="panel-content">
        <textarea id="input-md" data-i18n-placeholder="placeholder_input_md" placeholder="於此輸入 Markdown 文本..."></textarea>
        <div id="preview-pane" class="md-preview-pane"></div>
      </div>
    </section>
  </main>

  <div class="modal-overlay" id="license-modal">
    <div class="modal-card">
      <div class="modal-header">
        <h2 data-i18n="license_title">開源授權協議 (License)</h2>
        <button class="secondary" onclick="toggleLicenseModal(false)">✕</button>
      </div>
      <div class="modal-body">
        <div class="license-author" data-i18n="license_author">作者: startgo (startgo@yia.app)</div>
        <div class="license-block" data-i18n-html="license_desc">本專案預設採用 <a href="https://www.gnu.org/licenses/gpl-3.0.html" target="_blank" rel="noopener noreferrer" style="color: var(--accent);">GNU General Public License v3.0 (GPLv3)</a> 授權發布。這是一套自由軟體，您可以依據自由軟體基金會發布的 GPLv3 條款進行修改與重新散布。</div>
        <div class="license-block" data-i18n="license_warranty">本程式發布之目的在於提供實用價值，但不提供任何明示或暗示之擔保，亦不保證適銷性或特定目的之適用性。詳情請參照官方 GNU 通用公共授權條款全文。</div>
        
        <div class="ref-section">
          <div class="ref-title" data-i18n="ref_components_title">核心元件參照 (Core Components)：</div>
          <ul class="ref-list">
            <li>• <a href="https://github.com/microsoft/markitdown" target="_blank" rel="noopener noreferrer">MarkItDown</a> (MIT)</li>
            <li>• <a href="https://github.com/pyodide/pyodide" target="_blank" rel="noopener noreferrer">Pyodide Engine</a> (MPL-2.0)</li>
            <li>• <a href="https://github.com/Hopding/pdf-lib" target="_blank" rel="noopener noreferrer">pdf-lib Vector</a> (MIT)</li>
            <li>• <a href="https://github.com/pdf-lib/fontkit" target="_blank" rel="noopener noreferrer">fontkit Engine</a> (Apache-2.0)</li>
            <li>• <a href="https://github.com/markedjs/marked" target="_blank" rel="noopener noreferrer">Marked Parser</a> (MIT)</li>
            <li>• <a href="https://github.com/pdfminer/pdfminer.six" target="_blank" rel="noopener noreferrer">pdfminer.six</a> (MIT)</li>
            <li>• <a href="https://github.com/matthewwithanm/python-markdownify" target="_blank" rel="noopener noreferrer">markdownify</a> (MIT)</li>
            <li>• <a href="https://www.crummy.com/software/BeautifulSoup/" target="_blank" rel="noopener noreferrer">BeautifulSoup4</a> (MIT)</li>
          </ul>
        </div>
      </div>
      <div class="modal-footer">
        <button onclick="toggleLicenseModal(false)" data-i18n="btn_close">關閉</button>
      </div>
    </div>
  </div>

  <script>
    let pyodide = null;
    let currentLang = 'zh-TW';
    let currentStatusKey = 'status_init';
    let statusExtraData = '';
    let currentTab = 'edit';

    const i18nDictionary = {
      'zh-TW': {
        app_title: "MarkItDown (Pyodide WASM Engine)",
        status_init: "載入 Pyodide 核心環境...",
        status_wasm: "初始化 WebAssembly 環境...",
        status_deps: "安裝相依模組 (markitdown dependencies)...",
        status_ready: "MarkItDown 引擎準備就緒 (Ready)",
        status_parsing: "解析檔案中...",
        status_loading_font: "載入繁中向量字型庫...",
        status_generating_pdf: "排版編譯中 (JIS 禁則排版 + 雙軌分支向量拓撲)...",
        status_done: "解析完成: ",
        status_done_lossless: "100% 無損還原成功 (PDF/A-3 核心): ",
        status_err: "錯誤發生",
        btn_select_file: "選擇檔案 (PDF/HTML)",
        btn_load_md: "載入 MD",
        btn_export_pdf: "輸出可逆 PDF",
        btn_export_html: "匯出 HTML",
        btn_license: "開源授權",
        btn_load_i18n: "載入語系包",
        panel_doc_to_md: "文件解析轉 Markdown",
        panel_md_export: "Markdown 編輯與預覽",
        tab_edit: "編輯",
        tab_preview: "預覽",
        placeholder_output_md: "轉換後的 Markdown 將顯示於此...",
        placeholder_input_md: "於此輸入 Markdown 文本...",
        license_title: "開源授權協議 (License)",
        license_author: "作者: startgo (startgo@yia.app)",
        license_desc: "本專案預設採用 <a href=\"https://www.gnu.org/licenses/gpl-3.0.html\" target=\"_blank\" rel=\"noopener noreferrer\" style=\"color: var(--accent);\">GNU General Public License v3.0 (GPLv3)</a> 授權發布。這是一套自由軟體，您可以依據自由軟體基金會發布的 GPLv3 條款進行修改與重新散布。",
        license_warranty: "本程式發布之目的在於提供實用價值，但不提供任何明示或暗示之擔保，亦不保證適銷性或特定目的之適用性。詳情請參照官方 GNU 通用公共授權條款全文。",
        ref_components_title: "核心元件參照 (Core Components)：",
        btn_close: "關閉",
        alert_empty_md: "請輸入 Markdown 內容",
        converting: "轉換中...",
        convert_fail: "轉換失敗: "
      },
      'en': {
        app_title: "MarkItDown (Pyodide WASM Engine)",
        status_init: "Loading Pyodide core...",
        status_wasm: "Initializing WebAssembly environment...",
        status_deps: "Installing dependencies (markitdown dependencies)...",
        status_ready: "MarkItDown Engine Ready",
        status_parsing: "Parsing file...",
        status_loading_font: "Loading CJK Vector Font...",
        status_generating_pdf: "Compiling PDF (JIS Typography + Dual-Track Vector Branching)...",
        status_done: "Parsed: ",
        status_done_lossless: "100% Lossless Restored (PDF/A-3 Core): ",
        status_err: "Error occurred",
        btn_select_file: "Select File (PDF/HTML)",
        btn_load_md: "Load MD",
        btn_export_pdf: "Export Reversible PDF",
        btn_export_html: "Export HTML",
        btn_license: "License",
        btn_load_i18n: "Load i18n Pack",
        panel_doc_to_md: "Document Parser to Markdown",
        panel_md_export: "Markdown Edit & Preview",
        tab_edit: "Edit",
        tab_preview: "Preview",
        placeholder_output_md: "Converted Markdown will appear here...",
        placeholder_input_md: "Input Markdown text here...",
        license_title: "Open Source License",
        license_author: "Author: startgo (startgo@yia.app)",
        license_desc: "This project is published under the terms of <a href=\"https://www.gnu.org/licenses/gpl-3.0.html\" target=\"_blank\" rel=\"noopener noreferrer\" style=\"color: var(--accent);\">GNU General Public License v3.0 (GPLv3)</a>. It is free software, and you may modify and redistribute it under the conditions of the GPLv3.",
        license_warranty: "This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the official GNU GPLv3 for details.",
        ref_components_title: "Core Components Reference:",
        btn_close: "Close",
        alert_empty_md: "Please enter Markdown content",
        converting: "Converting...",
        convert_fail: "Conversion failed: "
      }
    };

    const statusEl = document.getElementById('status');
    const docInput = document.getElementById('doc-input');
    const mdFileInput = document.getElementById('md-input-file');
    const outputMd = document.getElementById('output-md');
    const inputMd = document.getElementById('input-md');
    const previewPane = document.getElementById('preview-pane');
    const tabBtnEdit = document.getElementById('tab-btn-edit');
    const tabBtnPreview = document.getElementById('tab-btn-preview');

    function switchMdTab(tab) {
      currentTab = tab;
      if (tab === 'edit') {
        inputMd.style.display = 'block';
        previewPane.style.display = 'none';
        tabBtnEdit.classList.add('active');
        tabBtnPreview.classList.remove('active');
      } else {
        renderPreview();
        inputMd.style.display = 'none';
        previewPane.style.display = 'block';
        tabBtnEdit.classList.remove('active');
        tabBtnPreview.classList.add('active');
      }
    }

    function renderPreview() {
      const mdText = inputMd.value;
      previewPane.innerHTML = marked.parse(mdText || '');
    }

    function setEngineStatus(key, extra = '') {
      currentStatusKey = key;
      statusExtraData = extra;
      const dict = i18nDictionary[currentLang] || i18nDictionary['en'];
      const baseText = dict[key] || key;
      statusEl.textContent = baseText + statusExtraData;
    }

    function updateI18nUI() {
      const dict = i18nDictionary[currentLang] || i18nDictionary['en'];
      document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        if (dict[key]) el.textContent = dict[key];
      });
      document.querySelectorAll('[data-i18n-html]').forEach(el => {
        const key = el.getAttribute('data-i18n-html');
        if (dict[key]) el.innerHTML = dict[key];
      });
      document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
        const key = el.getAttribute('data-i18n-placeholder');
        if (dict[key]) el.placeholder = dict[key];
      });
      setEngineStatus(currentStatusKey, statusExtraData);
    }

    function changeLanguage(langKey) {
      currentLang = langKey;
      updateI18nUI();
    }

    document.getElementById('lang-file-input').addEventListener('change', async (e) => {
      const file = e.target.files[0];
      if (!file) return;
      try {
        const content = await file.text();
        const pack = JSON.parse(content);
        const langCode = pack.langCode || 'custom';
        i18nDictionary[langCode] = Object.assign({}, i18nDictionary['en'], pack.translations);
        
        const select = document.getElementById('lang-select');
        let opt = select.querySelector(`option[value="${langCode}"]`);
        if (!opt) {
          opt = document.createElement('option');
          opt.value = langCode;
          opt.textContent = pack.langName || langCode;
          select.appendChild(opt);
        }
        select.value = langCode;
        changeLanguage(langCode);
      } catch (err) {
        alert('語系包解析錯誤: ' + err.message);
      }
    });

    function toggleLicenseModal(show) {
      document.getElementById('license-modal').style.display = show ? 'flex' : 'none';
    }

    async function initEngine() {
      try {
        setEngineStatus('status_wasm');
        pyodide = await loadPyodide();
        
        setEngineStatus('status_deps');
        await pyodide.loadPackage(['micropip', 'beautifulsoup4']);
        const micropip = pyodide.pyimport('micropip');
        await micropip.install(['pdfminer.six', 'markdownify']);

        pyodide.runPython(`
import io
import re
from bs4 import BeautifulSoup
from markdownify import markdownify
from pdfminer.high_level import extract_pages
from pdfminer.layout import LTTextContainer, LTChar
from pdfminer.pdfparser import PDFParser
from pdfminer.pdfdocument import PDFDocument
from pdfminer.pdftypes import resolve1

class DocumentConverterResult:
    def __init__(self, title=None, text_content="", is_lossless=False):
        self.title = title
        self.text_content = text_content
        self.is_lossless = is_lossless

class HtmlConverter:
    def convert_stream(self, stream):
        content = stream.read()
        if isinstance(content, bytes):
            content = content.decode('utf-8', errors='replace')
        soup = BeautifulSoup(content, 'html.parser')
        title = soup.title.string if soup.title else None
        for element in soup(["script", "style"]):
            element.decompose()
        md = markdownify(str(soup), heading_style="ATX", strip=['script', 'style'])
        cleaned_md = re.sub(r'\\n{3,}', '\\n\\n', md).strip()
        return DocumentConverterResult(title=title, text_content=cleaned_md)

class PdfConverter:
    def _extract_embedded_source(self, stream):
        try:
            stream.seek(0)
            parser = PDFParser(stream)
            doc = PDFDocument(parser)
            if 'Names' not in doc.catalog:
                return None
            names = resolve1(doc.catalog['Names'])
            if 'EmbeddedFiles' not in names:
                return None
            ef = resolve1(names['EmbeddedFiles'])
            if 'Names' not in ef:
                return None
            name_array = resolve1(ef['Names'])
            
            for idx in range(0, len(name_array), 2):
                file_spec = resolve1(name_array[idx + 1])
                if 'EF' in file_spec:
                    ef_dict = resolve1(file_spec['EF'])
                    if 'F' in ef_dict:
                        stream_obj = resolve1(ef_dict['F'])
                        raw_bytes = stream_obj.get_data()
                        return raw_bytes.decode('utf-8', errors='replace')
            return None
        except Exception:
            return None

    def convert_stream(self, stream):
        lossless_source = self._extract_embedded_source(stream)
        if lossless_source is not None:
            return DocumentConverterResult(title=None, text_content=lossless_source, is_lossless=True)

        stream.seek(0)
        pages_output = []
        font_sizes = []
        extracted_blocks = []

        for page_layout in extract_pages(stream):
            page_elements = []
            for element in page_layout:
                if isinstance(element, LTTextContainer):
                    text = element.get_text().strip()
                    if not text:
                        continue
                    
                    chars = [c for line in element if hasattr(line, '__iter__') for c in line if isinstance(c, LTChar)]
                    avg_size = sum(c.height for c in chars) / len(chars) if chars else 10.0
                    font_sizes.append(avg_size)
                    
                    page_elements.append({
                        "bbox": element.bbox,
                        "text": text,
                        "size": avg_size
                    })

            page_elements.sort(key=lambda item: -item["bbox"][1])
            extracted_blocks.append(page_elements)

        base_size = 10.0
        if font_sizes:
            sorted_sizes = sorted(font_sizes)
            base_size = sorted_sizes[len(sorted_sizes) // 2]

        for page_elements in extracted_blocks:
            page_md = []
            i = 0
            while i < len(page_elements):
                block = page_elements[i]
                txt = block["text"]
                sz = block["size"]

                if sz >= base_size * 1.5:
                    page_md.append(f"# {txt}")
                    i += 1
                    continue
                elif sz >= base_size * 1.25:
                    page_md.append(f"## {txt}")
                    i += 1
                    continue
                elif sz >= base_size * 1.1:
                    page_md.append(f"### {txt}")
                    i += 1
                    continue

                lines = [l.strip() for l in txt.splitlines() if l.strip()]
                
                is_table = False
                if len(lines) >= 2:
                    rows = [[c.strip() for c in re.split(r"\\s{2,}", l) if c.strip()] for l in lines]
                    if all(len(r) >= 2 for r in rows):
                        is_table = True
                        max_c = max(len(r) for r in rows)
                        padded = [r + [""] * (max_c - len(r)) for r in rows]
                        header = "| " + " | ".join(padded[0]) + " |"
                        div = "| " + " | ".join(["---"] * max_c) + " |"
                        body = ["| " + " | ".join(r) + " |" for r in padded[1:]]
                        page_md.append("\\n".join([header, div] + body))

                if is_table:
                    i += 1
                    continue

                processed_lines = []
                for l in lines:
                    list_m = re.match(r"^([•\\-\\*]|\\d+\\.)\\s+(.*)", l)
                    if list_m:
                        m, c = list_m.group(1), list_m.group(2)
                        marker = m if m.endswith(".") else "-"
                        processed_lines.append(f"{marker} {c}")
                    else:
                        processed_lines.append(l)

                page_md.append("\\n".join(processed_lines))
                i += 1

            pages_output.append("\\n\\n".join(page_md))

        full_content = "\\n\\n---\\n\\n".join(pages_output).strip()
        return DocumentConverterResult(title=None, text_content=full_content, is_lossless=False)

class MarkItDown:
    def __init__(self):
        self.pdf_converter = PdfConverter()
        self.html_converter = HtmlConverter()

    def convert_stream(self, stream, ext):
        ext = ext.lower().strip('.')
        if ext == 'pdf':
            return self.pdf_converter.convert_stream(stream)
        elif ext in ['html', 'htm']:
            return self.html_converter.convert_stream(stream)
        else:
            raise ValueError(f"不支援的副檔名: {ext}")

_markitdown_instance = MarkItDown()

def execute_markitdown(file_bytes, filename):
    if hasattr(file_bytes, "to_py"):
        raw_data = bytes(file_bytes.to_py())
    else:
        raw_data = bytes(file_bytes)
        
    stream = io.BytesIO(raw_data)
    ext = filename.split('.')[-1] if '.' in filename else ''
    res = _markitdown_instance.convert_stream(stream, ext)
    return {
        "text": res.text_content,
        "is_lossless": res.is_lossless
    }
`);

        setEngineStatus('status_ready');
        docInput.disabled = false;
      } catch (err) {
        setEngineStatus('status_err', ': ' + err.message);
        console.error(err);
      }
    }

    docInput.addEventListener('change', async (e) => {
      const dict = () => i18nDictionary[currentLang] || i18nDictionary['en'];
      const file = e.target.files[0];
      if (!file) return;

      const isPdf = file.name.toLowerCase().endsWith('.pdf');
      const isHtml = file.name.toLowerCase().endsWith('.html') || file.name.toLowerCase().endsWith('.htm');

      if (!isPdf && !isHtml) {
        alert('請上傳 .pdf 或 .html / .htm 格式檔案');
        return;
      }

      setEngineStatus('status_parsing');
      outputMd.value = dict().converting;

      try {
        if (!pyodide) throw new Error('WASM Engine 未就緒');
        const arrayBuffer = await file.arrayBuffer();
        const uint8Array = new Uint8Array(arrayBuffer);
        const executeFunc = pyodide.globals.get('execute_markitdown');
        const pyRes = executeFunc(uint8Array, file.name);
        const res = pyRes.toJs();

        outputMd.value = res.get('text');
        inputMd.value = res.get('text');
        if (currentTab === 'preview') renderPreview();
        
        if (res.get('is_lossless')) {
          setEngineStatus('status_done_lossless', file.name);
        } else {
          setEngineStatus('status_done', file.name);
        }
      } catch (err) {
        outputMd.value = dict().convert_fail + err.message;
        setEngineStatus('status_err', ': ' + err.message);
        console.error(err);
      }
    });

    mdFileInput.addEventListener('change', async (e) => {
      const file = e.target.files[0];
      if (!file) return;
      try {
        const text = await file.text();
        inputMd.value = text;
        if (currentTab === 'preview') renderPreview();
        setEngineStatus('status_done', file.name);
      } catch (err) {
        alert('讀取 Markdown 檔案失敗: ' + err.message);
      }
    });

    function sanitizeLigatures(text) {
      if (!text) return '';
      let s = text.normalize('NFKC');
      s = s.replace(/[\uFB00-\uFB06]/g, m => {
        return { 'ﬀ': 'ff', 'ﬁ': 'fi', 'ﬂ': 'fl', 'ﬃ': 'ffi', 'ﬄ': 'ffl', 'ﬅ': 'st', 'ﬆ': 'st' }[m] || m;
      });
      return s;
    }

    // 排版引擎核心 (v1.31.10)：完全過濾 HTML 註解、頁內錨點淨化、單字保護、雙軌向量拓撲
    async function exportFullEnginePdf() {
      const dict = () => i18nDictionary[currentLang] || i18nDictionary['en'];
      let mdText = inputMd.value;
      if (!mdText.trim()) {
        alert(dict().alert_empty_md);
        return;
      }

      // 徹底剔除 HTML 註解 (如 <!-- 作者... -->)
      mdText = mdText.replace(/<!--[\s\S]*?-->/g, '');
      mdText = sanitizeLigatures(mdText);

      try {
        setEngineStatus('status_loading_font');

        const fontUrl = 'https://cdn.jsdelivr.net/gh/adobe-fonts/source-han-sans@release/OTF/TraditionalChinese/SourceHanSansTC-Regular.otf';
        const fontRes = await fetch(fontUrl);
        if (!fontRes.ok) throw new Error('無法取得繁體中文字型庫');
        const fontBytes = await fontRes.arrayBuffer();

        setEngineStatus('status_generating_pdf');

        const { PDFDocument, rgb, PDFName, PDFString } = PDFLib;
        const pdfDoc = await PDFDocument.create();
        pdfDoc.registerFontkit(fontkit);

        const cjkFont = await pdfDoc.embedFont(fontBytes, { subset: true });

        const pageWidth = 595.28;
        const pageHeight = 841.89;
        const margin = 45;
        const usableWidth = pageWidth - (margin * 2);

        let currentPage = pdfDoc.addPage([pageWidth, pageHeight]);
        let cursorY = pageHeight - margin;

        function ensureSpace(requiredHeight) {
          if (cursorY - requiredHeight < margin) {
            currentPage = pdfDoc.addPage([pageWidth, pageHeight]);
            cursorY = pageHeight - margin;
          }
        }

        function addPdfHyperlink(page, x, y, width, height, uri) {
          const linkAnnot = pdfDoc.context.obj({
            Type: 'Annot',
            Subtype: 'Link',
            Rect: [x, y - 2, x + width, y + height + 2],
            Border: [0, 0, 0],
            C: [0, 0.45, 0.8],
            A: {
              Type: 'Action',
              S: 'URI',
              URI: PDFString.of(uri)
            }
          });
          const linkRef = pdfDoc.context.register(linkAnnot);

          let annots = page.node.get(PDFName.of('Annots'));
          if (!annots) {
            annots = pdfDoc.context.obj([]);
            page.node.set(PDFName.of('Annots'), annots);
          }
          annots.push(linkRef);
        }

        function drawRichTextLine(rawText, size, color, indent = 0, lineSpacing = 4) {
          const h = size + lineSpacing;
          ensureSpace(h);

          // 支援外鏈 (https://) 及 頁內錨點 (#)
          const linkRegex = /\[([^\]]+)\]\(([^)]+)\)|(https?:\/\/[^\s\)]+)/g;
          let lastIdx = 0;
          let curX = margin + indent;
          const drawY = cursorY - size;
          let match;

          while ((match = linkRegex.exec(rawText)) !== null) {
            const preText = rawText.substring(lastIdx, match.index);
            if (preText) {
              currentPage.drawText(preText, { x: curX, y: drawY, size, font: cjkFont, color });
              curX += cjkFont.widthOfTextAtSize(preText, size);
            }

            const linkText = match[1] || match[3];
            const linkUrl = match[2] || match[3];
            const isWebUrl = /^https?:\/\//i.test(linkUrl);
            const linkWidth = cjkFont.widthOfTextAtSize(linkText, size);

            if (isWebUrl) {
              // 原生可點擊 Web 超連結
              currentPage.drawText(linkText, {
                x: curX,
                y: drawY,
                size,
                font: cjkFont,
                color: rgb(0.01, 0.45, 0.85)
              });

              currentPage.drawLine({
                start: { x: curX, y: drawY - 1 },
                end: { x: curX + linkWidth, y: drawY - 1 },
                thickness: 0.5,
                color: rgb(0.01, 0.45, 0.85)
              });

              addPdfHyperlink(currentPage, curX, drawY, linkWidth, size, linkUrl);
            } else {
              // 頁內錨點 (如 [#繁體中文](#繁體中文))：消除括號語法，以優雅文字呈現
              currentPage.drawText(linkText, {
                x: curX,
                y: drawY,
                size,
                font: cjkFont,
                color: rgb(0.2, 0.3, 0.4)
              });
            }

            curX += linkWidth;
            lastIdx = match.index + match[0].length;
          }

          const remainText = rawText.substring(lastIdx);
          if (remainText) {
            currentPage.drawText(remainText, { x: curX, y: drawY, size, font: cjkFont, color });
          }

          cursorY -= h;
        }

        function drawParagraphBlock(text, size, color, indent = 0, lineSpacing = 4, bottomMargin = 6) {
          const clean = sanitizeLigatures(text);
          const maxW = usableWidth - indent;

          const kinsokuLineHead = "、。，．）〕］｝々ーァィゥェォッャュョヮヵヶ!?！？)]},.:;?!";
          const kinsokuLineEnd = "（〔［｛「『【([{";

          // 改進分詞：保持完整詞組與檔名 (如 Run-MarkItDownServer.ps1)，避免在破折號處拆碎單字
          const tokenRegex = /\[[^\]]+\]\([^\)]+\)|https?:\/\/[^\s\)]+|[a-zA-Z0-9_\-\.\@\:]+|\s+|[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]|./g;
          const tokens = clean.match(tokenRegex) || [clean];

          const lines = [];
          let curLine = '';

          for (let tIdx = 0; tIdx < tokens.length; tIdx++) {
            const token = tokens[tIdx];
            const testLine = curLine + token;
            const visibleTest = testLine.replace(/\[([^\]]+)\]\([^\)]+\)/g, '$1');

            if (cjkFont.widthOfTextAtSize(visibleTest, size) > maxW && curLine.trim().length > 0) {
              if (kinsokuLineHead.includes(token.trim()) && curLine.length > 1) {
                const pullChar = curLine.slice(-1);
                lines.push(curLine.slice(0, -1).trimEnd());
                curLine = pullChar + token;
              } else {
                lines.push(curLine.trimEnd());
                curLine = token.trimStart();
              }
            } else {
              curLine = testLine;
            }
          }
          if (curLine.trim().length > 0) {
            lines.push(curLine.trimEnd());
          }

          for (const l of lines) {
            drawRichTextLine(l, size, color, indent, lineSpacing);
          }
          cursorY -= bottomMargin;
        }

        // 原生向量拓撲繪製 (支援 Mermaid DAG 與 Text Diagram 節點)
        function drawVectorFlowchart(chartLines) {
          const nodeDict = new Map();
          for (const line of chartLines) {
            const trimmed = line.trim();
            if (!trimmed || trimmed.toLowerCase().includes('chart') || trimmed.toLowerCase().startsWith('graph')) continue;

            const nodeRegex = /([a-zA-Z0-9_\u4e00-\u9fa5]+)\s*(\[|\{|\(\()([^\]\}\)]+)(\]|\}|\)\))/g;
            let match;
            while ((match = nodeRegex.exec(trimmed)) !== null) {
              const id = match[1];
              const shape = match[2] === '{' ? 'diamond' : 'rect';
              const label = match[3].replace(/^["']|["']$/g, '').trim();
              if (!nodeDict.has(id)) {
                nodeDict.set(id, { id, shape, label });
              }
            }
          }

          const nodes = Array.from(nodeDict.values());
          if (nodes.length === 0) return;

          const boxW = Math.min(usableWidth * 0.85, 420);
          const boxH = 22;
          const gap = 14;
          const startX = margin + (usableWidth - boxW) / 2;

          for (let idx = 0; idx < nodes.length; idx++) {
            const node = nodes[idx];
            ensureSpace(boxH + gap + 4);

            const isDiamond = node.shape === 'diamond';

            currentPage.drawRectangle({
              x: startX,
              y: cursorY - boxH,
              width: boxW,
              height: boxH,
              color: isDiamond ? rgb(0.99, 0.98, 0.94) : rgb(0.94, 0.97, 1.0),
              borderColor: isDiamond ? rgb(0.85, 0.65, 0.13) : rgb(0.22, 0.58, 0.85),
              borderWidth: isDiamond ? 1 : 0.8
            });

            const labelText = node.label.substring(0, 48);
            const textW = cjkFont.widthOfTextAtSize(labelText, 8.5);
            const textX = startX + Math.max(6, (boxW - textW) / 2);
            const textY = cursorY - (boxH / 2) - 3.2;

            currentPage.drawText(labelText, {
              x: textX,
              y: textY,
              size: 8.5,
              font: cjkFont,
              color: isDiamond ? rgb(0.45, 0.3, 0.05) : rgb(0.02, 0.22, 0.42)
            });

            cursorY -= boxH;

            if (idx < nodes.length - 1) {
              const arrowMidX = startX + boxW / 2;
              const arrowStartY = cursorY;
              const arrowEndY = cursorY - gap;

              currentPage.drawLine({
                start: { x: arrowMidX, y: arrowStartY },
                end: { x: arrowMidX, y: arrowEndY },
                thickness: 0.8,
                color: rgb(0.4, 0.5, 0.6)
              });
              currentPage.drawLine({
                start: { x: arrowMidX - 3, y: arrowEndY + 4 },
                end: { x: arrowMidX, y: arrowEndY },
                thickness: 0.8,
                color: rgb(0.4, 0.5, 0.6)
              });
              currentPage.drawLine({
                start: { x: arrowMidX + 3, y: arrowEndY + 4 },
                end: { x: arrowMidX, y: arrowEndY },
                thickness: 0.8,
                color: rgb(0.4, 0.5, 0.6)
              });

              cursorY -= gap;
            }
          }
          cursorY -= 12;
        }

        // 文字框線圖（ASCII/Unicode Text Diagram）原生雙軌分支向量重組引擎
        function drawAsciiTextDiagram(diagramLines) {
          const pipeline = [];

          for (const line of diagramLines) {
            // 僅過濾真正的框線字元，嚴格保留連字號 (-) 與加號 (+)
            const cleaned = line.replace(/[\u2500-\u257F\u2580-\u259F\u25A0-\u25FF]/g, ' ').trim();
            if (cleaned.length < 2) continue;

            const isNote = cleaned.startsWith('(') || cleaned.includes('.NET') || cleaned.includes('▼') || cleaned.includes('->');
            
            if (isNote) {
              pipeline.push({ type: 'note', text: cleaned.replace(/^[\|\▼\s]+/, '').trim() });
              continue;
            }

            // 檢測是否為水平並排雙分支（以 3 個以上空白分割，或各自被 [] 括住）
            const multiCols = cleaned.split(/\s{3,}/).map(s => s.trim()).filter(s => s.length > 0);
            if (multiCols.length >= 2) {
              pipeline.push({ type: 'split', items: multiCols });
            } else {
              pipeline.push({ type: 'node', text: cleaned });
            }
          }

          if (pipeline.length === 0) return;

          const totalW = Math.min(usableWidth * 0.92, 480);
          const startX = margin + (usableWidth - totalW) / 2;
          const singleH = 24;

          for (let idx = 0; idx < pipeline.length; idx++) {
            const step = pipeline[idx];

            if (step.type === 'note') {
              ensureSpace(18);
              const midX = startX + totalW / 2;

              currentPage.drawLine({
                start: { x: midX, y: cursorY },
                end: { x: midX, y: cursorY - 14 },
                thickness: 0.8,
                color: rgb(0.2, 0.5, 0.7)
              });
              currentPage.drawLine({
                start: { x: midX - 3, y: cursorY - 10 },
                end: { x: midX, y: cursorY - 14 },
                thickness: 0.8,
                color: rgb(0.2, 0.5, 0.7)
              });
              currentPage.drawLine({
                start: { x: midX + 3, y: cursorY - 10 },
                end: { x: midX, y: cursorY - 14 },
                thickness: 0.8,
                color: rgb(0.2, 0.5, 0.7)
              });

              if (step.text) {
                currentPage.drawText(step.text, {
                  x: midX + 8,
                  y: cursorY - 10,
                  size: 7.5,
                  font: cjkFont,
                  color: rgb(0.35, 0.45, 0.55)
                });
              }
              cursorY -= 18;
            } else if (step.type === 'node') {
              ensureSpace(singleH + 4);
              currentPage.drawRectangle({
                x: startX,
                y: cursorY - singleH,
                width: totalW,
                height: singleH,
                color: rgb(0.96, 0.98, 1.0),
                borderColor: rgb(0.22, 0.58, 0.85),
                borderWidth: 0.8
              });

              const textW = cjkFont.widthOfTextAtSize(step.text, 8.8);
              const textX = startX + Math.max(6, (totalW - textW) / 2);
              const textY = cursorY - (singleH / 2) - 3.2;

              currentPage.drawText(step.text, {
                x: textX,
                y: textY,
                size: 8.8,
                font: cjkFont,
                color: rgb(0.02, 0.18, 0.38)
              });

              cursorY -= (singleH + 2);
            } else if (step.type === 'split') {
              // 左右對稱雙卡片排版
              ensureSpace(singleH + 4);
              const numCols = step.items.length;
              const colGap = 12;
              const colW = (totalW - colGap * (numCols - 1)) / numCols;

              for (let c = 0; c < numCols; c++) {
                const cardX = startX + c * (colW + colGap);
                const isEgress = c === 1;

                currentPage.drawRectangle({
                  x: cardX,
                  y: cursorY - singleH,
                  width: colW,
                  height: singleH,
                  color: isEgress ? rgb(0.99, 0.98, 0.94) : rgb(0.94, 0.97, 1.0),
                  borderColor: isEgress ? rgb(0.85, 0.65, 0.13) : rgb(0.22, 0.58, 0.85),
                  borderWidth: 0.8
                });

                const label = step.items[c];
                const textW = cjkFont.widthOfTextAtSize(label, 8.2);
                const textX = cardX + Math.max(4, (colW - textW) / 2);
                const textY = cursorY - (singleH / 2) - 3.2;

                currentPage.drawText(label, {
                  x: textX,
                  y: textY,
                  size: 8.2,
                  font: cjkFont,
                  color: isEgress ? rgb(0.45, 0.3, 0.05) : rgb(0.02, 0.22, 0.42)
                });
              }
              cursorY -= (singleH + 2);
            }
          }
          cursorY -= 10;
        }

        function drawMarkdownTable(tableLines) {
          const rows = tableLines
            .map(l => l.trim())
            .filter(l => l.startsWith('|') && l.endsWith('|'))
            .map(l => l.slice(1, -1).split('|').map(c => c.trim()));

          if (rows.length < 2) return;
          const header = rows[0];
          const dataRows = rows.slice(1).filter(r => !r.every(c => c.match(/^:?-+:?$/)));

          const colCount = header.length;
          const firstColW = Math.min(130, usableWidth * 0.28);
          const otherColW = (usableWidth - firstColW) / Math.max(1, colCount - 1);
          const colWidths = [firstColW];
          for (let c = 1; c < colCount; c++) colWidths.push(otherColW);

          const allRows = [header, ...dataRows];
          for (let rIdx = 0; rIdx < allRows.length; rIdx++) {
            const row = allRows[rIdx];
            const isHeader = rIdx === 0;

            const cellLines = row.map((cellText, cIdx) => {
              const maxW = colWidths[cIdx] - 10;
              const chars = Array.from(sanitizeLigatures(cellText));
              const lines = [];
              let cur = '';
              for (const ch of chars) {
                const test = cur + ch;
                if (cjkFont.widthOfTextAtSize(test, 8.5) > maxW && cur.length > 0) {
                  lines.push(cur);
                  cur = ch;
                } else {
                  cur = test;
                }
              }
              if (cur.length > 0) lines.push(cur);
              return lines.length > 0 ? lines : [''];
            });

            const maxLines = Math.max(...cellLines.map(l => l.length));
            const rowH = maxLines * 12 + 8;
            ensureSpace(rowH + 2);

            if (isHeader) {
              currentPage.drawRectangle({
                x: margin,
                y: cursorY - rowH,
                width: usableWidth,
                height: rowH,
                color: rgb(0.94, 0.96, 0.98)
              });
            }

            let curX = margin;
            for (let cIdx = 0; cIdx < colCount; cIdx++) {
              const w = colWidths[cIdx];
              const lines = cellLines[cIdx] || [];
              let lineY = cursorY - 11;

              for (const l of lines) {
                currentPage.drawText(l, {
                  x: curX + 5,
                  y: lineY,
                  size: 8.5,
                  font: cjkFont,
                  color: isHeader ? rgb(0.02, 0.08, 0.16) : rgb(0.12, 0.16, 0.22)
                });
                lineY -= 12;
              }
              curX += w;
            }

            currentPage.drawLine({
              start: { x: margin, y: cursorY - rowH },
              end: { x: margin + usableWidth, y: cursorY - rowH },
              thickness: isHeader ? 1 : 0.5,
              color: rgb(0.8, 0.85, 0.9)
            });

            cursorY -= rowH;
          }
          cursorY -= 10;
        }

        const allLines = mdText.split('\n');
        let i = 0;

        while (i < allLines.length) {
          const rawLine = allLines[i];
          const trimmed = rawLine.trim();

          if (!trimmed) {
            i++;
            continue;
          }

          if (trimmed.startsWith('```')) {
            const fenceTag = trimmed.slice(3).trim().toLowerCase();
            i++;
            const innerLines = [];
            while (i < allLines.length && !allLines[i].trim().startsWith('```')) {
              innerLines.push(allLines[i]);
              i++;
            }
            if (i < allLines.length) i++;

            const innerText = innerLines.join('\n');

            // 辨識是否為 ASCII / Text Diagram 框線流程圖
            const isAsciiBoxDiagram = /[\u2500-\u257F\u2580-\u259F\u25A0-\u25FF]/.test(innerText) || 
                                     (innerText.includes('+-') && innerText.includes('-+')) ||
                                     (innerText.includes('┌') && innerText.includes('└'));

            // 辨識是否為 Mermaid 語法
            const isFenceFlow = fenceTag.includes('mermaid') || 
                                fenceTag.includes('flow') || 
                                /owchart|graph/i.test(innerText) || 
                                (innerText.includes('-->') && /[\[\{\(]/.test(innerText));

            if (isAsciiBoxDiagram) {
              // 自動將文字框線圖轉為 PDF 向量拓撲圖
              drawAsciiTextDiagram(innerLines);
            } else if (isFenceFlow) {
              drawVectorFlowchart(innerLines);
            } else {
              // 一般純代碼區塊：自適應摺行，保證長行不截斷
              const codeMaxW = usableWidth - 16;
              const wrappedCodeLines = [];
              for (const line of innerLines) {
                if (!line) { wrappedCodeLines.push(''); continue; }
                let cur = '';
                for (const ch of Array.from(line)) {
                  if (cjkFont.widthOfTextAtSize(cur + ch, 8) > codeMaxW && cur.length > 0) {
                    wrappedCodeLines.push(cur);
                    cur = '  ' + ch;
                  } else {
                    cur += ch;
                  }
                }
                if (cur.length > 0) wrappedCodeLines.push(cur);
              }

              const codeH = wrappedCodeLines.length * 11 + 12;
              ensureSpace(codeH);
              currentPage.drawRectangle({
                x: margin,
                y: cursorY - codeH,
                width: usableWidth,
                height: codeH,
                color: rgb(0.96, 0.97, 0.98),
                borderColor: rgb(0.8, 0.85, 0.9),
                borderWidth: 0.5
              });
              cursorY -= 8;
              for (const l of wrappedCodeLines) {
                drawRichTextLine(l, 8, rgb(0.15, 0.2, 0.25), 6, 3);
              }
              cursorY -= 6;
            }
            continue;
          }

          const hasChartWord = /owchart|graph/i.test(trimmed);
          const hasArrowSyntax = trimmed.includes('-->') && /[\[\{\(]/.test(trimmed);
          const nextHasArrow = (i + 1 < allLines.length) && allLines[i + 1].includes('-->');

          if ((hasChartWord && (hasArrowSyntax || nextHasArrow)) || hasArrowSyntax) {
            const chartLines = [trimmed];
            i++;
            while (i < allLines.length) {
              const nextL = allLines[i].trim();
              if (!nextL || nextL.startsWith('#') || nextL.startsWith('|') || nextL.startsWith('```') || nextL.match(/^(\d+\.|\-|\*)/)) {
                break;
              }
              chartLines.push(nextL);
              i++;
            }
            drawVectorFlowchart(chartLines);
            continue;
          }

          if (trimmed.startsWith('|') && trimmed.endsWith('|')) {
            const tableLines = [trimmed];
            i++;
            while (i < allLines.length && allLines[i].trim().startsWith('|') && allLines[i].trim().endsWith('|')) {
              tableLines.push(allLines[i].trim());
              i++;
            }
            drawMarkdownTable(tableLines);
            continue;
          }

          if (trimmed.startsWith('# ')) {
            cursorY -= 4;
            drawRichTextLine(trimmed.replace(/^#\s+/, ''), 15, rgb(0.01, 0.41, 0.63), 0, 6);
            ensureSpace(8);
            currentPage.drawLine({
              start: { x: margin, y: cursorY },
              end: { x: pageWidth - margin, y: cursorY },
              thickness: 1.2,
              color: rgb(0.01, 0.52, 0.78)
            });
            cursorY -= 10;
            i++;
            continue;
          }

          if (trimmed.startsWith('## ')) {
            cursorY -= 3;
            drawRichTextLine(trimmed.replace(/^##\s+/, ''), 12.5, rgb(0.01, 0.52, 0.78), 0, 5);
            ensureSpace(6);
            currentPage.drawLine({
              start: { x: margin, y: cursorY },
              end: { x: pageWidth - margin, y: cursorY },
              thickness: 0.8,
              color: rgb(0.8, 0.85, 0.9)
            });
            cursorY -= 8;
            i++;
            continue;
          }

          if (trimmed.startsWith('### ')) {
            drawRichTextLine(trimmed.replace(/^###\s+/, ''), 11, rgb(0.12, 0.16, 0.22), 0, 5);
            cursorY -= 3;
            i++;
            continue;
          }

          if (trimmed === '---' || trimmed === '***') {
            ensureSpace(12);
            cursorY -= 3;
            currentPage.drawLine({
              start: { x: margin, y: cursorY },
              end: { x: pageWidth - margin, y: cursorY },
              thickness: 0.5,
              color: rgb(0.8, 0.85, 0.9)
            });
            cursorY -= 8;
            i++;
            continue;
          }

          const olMatch = trimmed.match(/^(\d+)\.\s+(.*)/);
          if (olMatch) {
            const num = olMatch[1];
            const content = olMatch[2];
            drawParagraphBlock(`${num}. ${content}`, 9, rgb(0.12, 0.16, 0.22), 10, 4, 3);
            i++;
            continue;
          }

          const ulMatch = trimmed.match(/^([•\-\*])\s+(.*)/);
          if (ulMatch) {
            const content = ulMatch[2];
            drawParagraphBlock(`• ${content}`, 9, rgb(0.12, 0.16, 0.22), 10, 4, 3);
            i++;
            continue;
          }

          if (trimmed.startsWith('>')) {
            drawParagraphBlock(trimmed.replace(/^>\s*/, ''), 8.5, rgb(0.3, 0.35, 0.4), 14, 4, 4);
            i++;
            continue;
          }

          drawParagraphBlock(trimmed, 9, rgb(0.12, 0.16, 0.22), 0, 4, 5);
          i++;
        }

        const utf8Bytes = new TextEncoder().encode(inputMd.value);
        await pdfDoc.attach(utf8Bytes, 'source.md', {
          mimeType: 'text/markdown',
          description: 'MarkItDown 原始無損 Markdown 來源',
          creationDate: new Date(),
          modificationDate: new Date()
        });

        pdfDoc.setTitle('MarkItDown Reversible Document');
        pdfDoc.setAuthor('startgo (startgo@yia.app)');

        const finalPdfBytes = await pdfDoc.save();
        const blob = new Blob([finalPdfBytes], { type: 'application/pdf' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `MarkItDown_Selectable_${Date.now()}.pdf`;
        a.click();
        URL.revokeObjectURL(url);

        setEngineStatus('status_ready');
      } catch (err) {
        alert('向量 PDF 匯出失敗: ' + err.message);
        setEngineStatus('status_err', ': ' + err.message);
        console.error(err);
      }
    }

    function exportMdToHtml() {
      const dict = () => i18nDictionary[currentLang] || i18nDictionary['en'];
      const mdText = inputMd.value;
      if (!mdText.trim()) {
        alert(dict().alert_empty_md);
        return;
      }

      const parsedContent = marked.parse(mdText);
      const fullHtml = `<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="UTF-8">
  <title>Exported Markdown</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; line-height: 1.6; max-width: 800px; margin: 40px auto; padding: 0 20px; color: #1e293b; }
    pre { background: #f1f5f9; padding: 12px; border-radius: 6px; overflow-x: auto; }
    code { font-family: monospace; background: #f1f5f9; padding: 2px 4px; border-radius: 4px; }
    blockquote { border-left: 4px solid #0284c7; margin: 0; padding-left: 16px; color: #475569; }
    table { border-collapse: collapse; width: 100%; margin: 16px 0; }
    th, td { border: 1px solid #cbd5e1; padding: 8px 12px; text-align: left; }
    th { background: #f8fafc; }
  </style>
</head>
<body>
${parsedContent}
</body>
</html>`;

      const blob = new Blob([fullHtml], { type: 'text/html;charset=utf-8;' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `converted_${Date.now()}.html`;
      a.click();
      URL.revokeObjectURL(url);
    }

    updateI18nUI();
    initEngine();
  </script>
</body>
</html>
'@

    [System.IO.File]::WriteAllText($HtmlFilePath, $HtmlSource, [System.Text.Encoding]::UTF8)
    Write-Host "[OK] 靜態頁面產生完成: $HtmlFilePath" -ForegroundColor Green

    $Listener = New-Object System.Net.HttpListener
    $Listener.Prefixes.Add($Prefix)
    $Listener.Start()

    Write-Host "[INFO] 伺服器成功掛載於 $Prefix" -ForegroundColor Cyan
    Write-Host "[INFO] 正在開啟瀏覽器..." -ForegroundColor Cyan
    Start-Process $Prefix

    Write-Host "[RUNNING] 伺服器運作中。請勿關閉此視窗（按下 Ctrl+C 結束）..." -ForegroundColor Yellow

    while ($Listener.IsListening) {
        $Context = $Listener.GetContext()
        $Request = $Context.Request
        $Response = $Context.Response

        if ($Request.Url.AbsolutePath -eq "/" -or $Request.Url.AbsolutePath -eq "/index.html") {
            $Buffer = [System.IO.File]::ReadAllBytes($HtmlFilePath)
            $Response.ContentType = "text/html; charset=utf-8"
            $Response.ContentLength64 = $Buffer.Length
            $Response.OutputStream.Write($Buffer, 0, $Buffer.Length)
        } else {
            $Response.StatusCode = 404
        }

        $Response.OutputStream.Close()
    }
}
catch {
    Write-Host "`n[FATAL ERROR] 執行過程拋出異常:" -ForegroundColor Red
    Write-Host $_.Exception.ToString() -ForegroundColor DarkRed
    Write-Host "`n按下 Enter 鍵以退出視窗..." -ForegroundColor Gray
    [void][System.Console]::ReadLine()
}
finally {
    if ($Listener -ne $null -and $Listener.IsListening) {
        $Listener.Stop()
        $Listener.Close()
    }
    Write-Host "[STOP] 伺服器 Socket 已安全釋放。" -ForegroundColor DarkGray
}