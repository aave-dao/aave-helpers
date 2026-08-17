---
'@aave-dao/aave-helpers-js': patch
---

Derive V4 tokenization test signers from a random key instead of a fixed `makeAddrAndKey` label, so `*WithSig` flows keep working when the well-known address picks up EIP-7702 code on a live network
