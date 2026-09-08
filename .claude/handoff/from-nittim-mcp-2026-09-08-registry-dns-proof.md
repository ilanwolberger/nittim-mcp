# from nittim-mcp · 2026-09-08 · nittim.com apex TXT gained the MCP Registry DNS proof — UPSERT only

The `nittim.com` apex TXT record set (zone `Z07999621ZSADG9HQLA2Z`) now holds four values: stripe-verification, spf, google-site-verification, and **`v=MCPv1; k=ed25519; p=…`** — the official MCP Registry's ownership proof for `com.nittim/nittim` (published 2026-09-08, v1.1.0). Any edit to that record set must UPSERT all four; a DELETE breaks the registry login and SPF at once. Private key: keychain `NITTIM_MCP_REGISTRY_DNS_KEY_PEM`.

fis is the source for `public/skills/nittim-loop/` (SKILL.md + nittim-loop.mdc). `ilanwolberger/nittim-mcp` mirrors those files with `scripts/sync-from-live.sh`; its gate goes red when the served copy and its repo differ, so after a skill change ships here, sync there. PPA-2 gate: nittim listings are not parked (Ogen's are; NittiM→Ogen cross-sell stays in `handoff/parked/`). Nothing for fis to do now.
