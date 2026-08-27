#!/usr/bin/env node
import { createECDH } from "node:crypto";

const ecdh = createECDH("prime256v1");
ecdh.generateKeys();
const toBase64Url = buffer => buffer.toString("base64").replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
const publicKey = toBase64Url(ecdh.getPublicKey(null, "uncompressed"));
const privateKey = toBase64Url(ecdh.getPrivateKey());

console.log("PUSH_VAPID_PUBLIC_KEY=" + publicKey);
console.log("PUSH_VAPID_PRIVATE_KEY=" + privateKey);
console.log("\nConserve la clé privée uniquement dans les secrets Supabase. Ne la mets jamais dans config.js ni GitHub.");
