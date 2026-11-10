# Studio invoice template

The standard KPHD invoice for every project. Kellie approved it on 10 November 2026 from
**201.2026.BH-INV-002** (Bear Hug), the first invoice sent through the billing loop. Client documents are never stored in this
public repository: the approved original stays in Studio Home (`finance.invoices.metadata.sent_artifact`,
with its SHA-256) and in the studio's sent mail.

Governing rules in Studio Home: `GOV-20261109-MONEY-GATE-V2` and `GOV-20261110-INVOICE-TEMPLATE-STANDARD`.

## Files

| File | What it is |
|---|---|
| `invoice.template.html` | The layout: [KP/HD] masthead, bill-to and details, line table, totals, payment box, footer. |
| `render-invoice.mjs` | Fills the template from one invoice payload and writes the PDF. |

## Making an invoice

1. In Studio Home, read the payload: `select payload from finance.v_invoice_render_payload_v1 where invoice_number = '…';`
2. Save it as `payload.json` and run `node templates/invoice/render-invoice.mjs payload.json out/`.
3. A draft invoice renders with the "Draft for review · not yet issued" stamp. Set `render_final` in the
   invoice metadata only once it is approved to send.

Invoice metadata can carry `subtitle`, `bill_to_lines`, `display_lines` (for example, the fee less a deposit
received), `totals` and `payment_link`.

## Built-in checks

The renderer refuses to produce a PDF when:

- the lines do not add up to the amount due;
- anything in the payload looks like a bank account, routing, IBAN or SWIFT number. Payment goes only
  through a secure link (money gate, rule 10).
