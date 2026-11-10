#!/usr/bin/env node
// KPHD studio invoice — standard template for every project.
// Approved by Kellie 2026-11-10 from 201.2026.BH-INV-002. No client documents are kept in this public repo.
//
// Usage:
//   node templates/invoice/render-invoice.mjs payload.json [out-dir]
//
// payload.json is one row of finance.v_invoice_render_payload_v1 (column "payload") in Studio Home.
// Writes <invoice_number>.pdf (and .html) to out-dir. Set "draft": true to stamp
// "Draft for review · not yet issued" for dry runs.
//
// Money gate (GOV-20261109-MONEY-GATE-V2): payment instructions never carry bank or routing
// numbers. The payment box only ever says a secure link follows, or shows a link URL.

import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);

const BANK_DETAIL = /\b(routing|aba|account\s*(no|number|#)|acct|iban|swift)\b/i;

const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const money = (n) => {
  const v = Number(n);
  const s = Math.abs(v).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  return (v < 0 ? '−$' : '$') + s;
};
const longDate = (iso) => new Date(iso + 'T12:00:00Z').toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric', timeZone: 'UTC' });

export function renderHtml(p) {
  for (const k of ['invoice_number', 'subtitle', 'bill_to_lines', 'project_name', 'project_number', 'invoice_date', 'due_date', 'terms', 'lines', 'amount_due']) {
    if (p[k] === undefined || p[k] === null) throw new Error(`payload is missing ${k}`);
  }
  const paymentText = p.payment_link
    ? `Pay securely at ${esc(p.payment_link)} by ${longDate(p.due_date)}, referencing ${esc(p.invoice_number)}.`
    : `A secure payment link will be sent separately. Please pay by ${longDate(p.due_date)} and reference ${esc(p.invoice_number)}.`;
  if (BANK_DETAIL.test(JSON.stringify(p))) throw new Error('payload contains bank or routing detail; refused by the money gate');
  const lineSum = p.lines.reduce((s, l) => s + Math.round(Number(l.amount) * 100), 0);
  if (lineSum !== Math.round(Number(p.amount_due) * 100)) {
    throw new Error(`lines sum to ${money(lineSum / 100)} but amount due is ${money(p.amount_due)}; refusing to render`);
  }

  const rows = p.lines.map((l) => `
      <tr>
        <td>${esc(l.description)}${l.detail ? `\n          <div class="sub">${esc(l.detail)}</div>` : ''}</td>
        <td class="r">${money(l.amount)}</td>
      </tr>`).join('');
  const totals = (p.totals || []).map((t) => `
    <div class="row muted"><span>${esc(t.label)}</span><span>${money(t.amount)}</span></div>`).join('');

  const tpl = readFileSync(new URL('./invoice.template.html', import.meta.url), 'utf8');
  return tpl
    .replaceAll('{{invoice_number}}', esc(p.invoice_number))
    .replace('{{draft_banner}}', p.draft ? '<div class="draft">Draft for review · not yet issued</div>' : '')
    .replace('{{subtitle}}', esc(p.subtitle))
    .replace('{{bill_to}}', p.bill_to_lines.map(esc).join('<br>\n      '))
    .replace('{{project_name}}', esc(p.project_name))
    .replace('{{project_number}}', esc(p.project_number))
    .replace('{{invoice_date}}', longDate(p.invoice_date))
    .replace('{{terms}}', esc(p.terms))
    .replace('{{due_date}}', longDate(p.due_date))
    .replace('{{lines}}', rows)
    .replace('{{totals}}', totals)
    .replace('{{amount_due}}', money(p.amount_due))
    .replace('{{payment_text}}', paymentText);
}

async function main() {
  const [, , payloadPath, outDir = '.'] = process.argv;
  if (!payloadPath) { console.error('usage: render-invoice.mjs payload.json [out-dir]'); process.exit(2); }
  const p = JSON.parse(readFileSync(payloadPath, 'utf8'));
  const html = renderHtml(p);
  const dir = resolve(outDir); mkdirSync(dir, { recursive: true });
  const base = p.invoice_number + (p.draft ? '_DRAFT' : '');
  const htmlPath = join(dir, base + '.html');
  writeFileSync(htmlPath, html);
  const { chromium } = require('playwright');
  const b = await chromium.launch();
  const page = await b.newPage();
  await page.goto('file://' + htmlPath);
  await page.pdf({ path: join(dir, base + '.pdf'), format: 'Letter', printBackground: true,
                   margin: { top: '0.75in', bottom: '0.75in', left: '0.75in', right: '0.75in' } });
  await b.close();
  console.log(join(dir, base + '.pdf'));
}

if (import.meta.url === `file://${process.argv[1]}`) main().catch((e) => { console.error(e.message); process.exit(1); });
