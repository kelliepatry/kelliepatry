# Studio invoice template

The standard KPHD invoice for every project. Kellie approved it on 10 November 2026 from
**201.2026.BH-INV-002** (Bear Hug), the first invoice sent through the billing loop. Client documents are never stored in this
public repository: the approved original stays in Studio Home (`finance.invoices.metadata.sent_artifact`,
with its SHA-256) and in the studio's sent mail.

Governing rules in Studio Home: `GOV-20261109-MONEY-GATE-V2` and `GOV-20261110-INVOICE-TEMPLATE-STANDARD-A1`.

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

**Every invoice carries a payment link** (Kellie, 10 November 2026). Put it in the invoice metadata as
`payment_link` (an `https://` link from Stripe or the client portal). A final invoice without one will not render;
a draft can. The only exception is an invoice settled before this rule, marked `payment_link_required: false`.

Invoice metadata can also carry `subtitle`, `bill_to_lines`, `display_lines` (for example, the fee less a deposit
received), `totals` and `payment_link`.

## Built-in checks

The renderer refuses to produce a PDF when:

- a final invoice has no `https://` payment link;
- the lines do not add up to the amount due;
- anything in the payload looks like a bank account, routing, IBAN or SWIFT number. Payment goes only
  through a secure link (money gate, rule 10).
