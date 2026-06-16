# GnuPG signing in CQRLOG

## 1. Overview

CQRLOG can digitally sign exported ADIF files and verify signatures on imported ADIF files or individual QSO records. **OpenPGP** is the standard behind GnuPG (`gpg`); a **digital signature** proves that a log record was produced by whoever holds a specific **private key** tied to a callsign, and that the record has not been changed since signing. CQRLOG only **authenticates** data—it does not encrypt log content. The feature is **disabled by default**; when signing is off, CQRLOG behaves exactly as it did before this feature existed.

## 2. Dependencies

CQRLOG shells out to the system `gpg` binary. No extra libraries are linked into CQRLOG.

**GnuPG** — the `gpg` program, expected at `/usr/bin/gpg` (present on nearly all Linux distributions). Confirm:

```bash
gpg --version
```

**gpg-agent** — a background daemon that caches passphrases and talks to smart cards. On modern desktop Linux it usually starts automatically with your session; no manual setup is required for typical use.

**Hardware token (optional)** — an OpenPGP smart card such as a Nitrokey. `gpg-agent` and `scdaemon` route signing requests to the card when the private key lives on it.

## 3. Finding your existing key fingerprint

A **fingerprint** is a 40-character hexadecimal string that uniquely identifies an OpenPGP key (like a serial number for the key material). List keys on your system:

```bash
gpg --list-keys --fingerprint
```

Example output (abbreviated):

```
pub   ed25519 2024-01-15 [SC]
      ABCD1234EF567890ABCD1234EF567890ABCD1234
uid           [ ultimate ] LA1ABC (Amateur Radio) <LA1ABC@example.com>
sub   cv25519 2024-01-15 [E]
```

The fingerprint is the 40-character line directly under the `pub` line (`ABCD1234…` above). CQRLOG expects the fingerprint **without spaces**.

One-liner to print the first public-key fingerprint without spaces:

```bash
gpg --list-keys --fingerprint | grep -A1 'pub' | grep -v 'pub' | tr -d ' '
```

In CQRLOG, open **Preferences → Station → Signing** and click **Detect**. CQRLOG scans the local keyring for a **secret (signing) key** and fills the fingerprint field when one is found.

## 4. Generating a new key

Generate a new key if you have none, or if your existing key cannot sign (no secret signing subkey).

Recommended: **Ed25519** (modern, fast, small signatures). **brainpoolP256r1** and **RSA** also work with CQRLOG.

```bash
gpg --full-generate-key
```

Prompt guide:

| Prompt | Suggested choice |
|--------|------------------|
| Key type | `(9) ECC (sign and encrypt)`, then `(1) Curve 25519` for Ed25519 |
| Expiry | One year is a reasonable default; you can extend later |
| Real name | Your **callsign** (e.g. `LA1ABC`) — the callsign must appear in the **UID** (user ID) so keyserver searches by callsign work |
| Email | Recommended (e.g. `LA1ABC@example.com`) |
| Passphrase | Strongly recommended; `gpg-agent` caches it for the session |

Confirm the new key:

```bash
gpg --list-keys
```

## 5. Publishing your key

A **keyserver** is a public directory of OpenPGP keys on the Internet. When CQRLOG verifies a signature from a remote callsign, it may need to download that operator's **public key** from a keyserver. If the key was never published, verification ends with a key-not-found result.

Upload your public key (replace `YOUR_FINGERPRINT` with your 40-character fingerprint, no spaces):

```bash
gpg --keyserver hkps://keys.openpgp.org --send-keys YOUR_FINGERPRINT
```

**keys.openpgp.org** sends a verification email before a UID becomes searchable by name or callsign. Follow the link in that message so others can find you by callsign.

For a server that does not require email verification:

```bash
gpg --keyserver hkps://keyserver.ubuntu.com --send-keys YOUR_FINGERPRINT
```

Confirm the key is visible (replace `LA1ABC` with the callsign in the UID):

```bash
gpg --keyserver hkps://keys.openpgp.org --search-keys LA1ABC
```

## 6. Configuring CQRLOG

1. Open **CQRLOG → Preferences → Station**.
2. In the **Signing** section, tick **Enable signing**.
3. Enter your **Key fingerprint** (40 hex characters, no spaces), or click **Detect** to fill it from the local keyring.
4. Set **Keyserver URL**. Default: `hkps://keys.openpgp.org`. Change this only if your key (or the keys you verify) live on another server.
5. Click **OK** / save preferences. CQRLOG checks that the fingerprint exists in the **local keyring** and shows a warning if it does not.

When signing is enabled and a signing key is configured, a **key icon** appears in the **New QSO** window status bar, indicating the local signing key is ready.

## 7. Signing exported ADIF files

With signing enabled, each QSO record written during **ADIF export** is signed automatically. CQRLOG produces a **detached signature**—the signature is stored separately from the QSO fields, not mixed into call, date, or mode data. The signature is embedded in the ADIF file as the application field `APP_CQRLOG_SIGNATURE` on the same record (before `<EOR>`).

Anyone importing the file into CQRLOG (with signing enabled) can verify that each signed record matches the exporter's key and was not altered after export. No extra export steps are required beyond enabling signing in preferences.

## 8. Verifying incoming ADIF files and QSL entries

**On ADIF import:** If an imported file contains `APP_CQRLOG_SIGNATURE` fields and signing is enabled in preferences, CQRLOG verifies each signed record during import. The result is stored on the QSO (`gnupg_sigverify` in the log database).

**On an existing QSO:** Use **QSL → Verify signature** to re-check the selected QSO in the main log view.

### Key lookup order

When the public key is not already available, CQRLOG resolves the remote **CALL** in this order:

1. **Internal key cache** — table `gnupg_key_cache` in the CQRLOG database (fastest; no network).
2. **Local GnuPG keyring** — typically `~/.gnupg/pubring.kbx`.
3. **Configured keyserver** — searched in a **background thread** if the key is still missing; the UI stays responsive. A found key is cached for future lookups.

### Status icons

| Icon | Meaning |
|------|---------|
| key.svg | Local signing key loaded and ready (signing enabled) |
| open.svg | Remote public key found; signature verified successfully |
| key-error.svg | Public key for this callsign not found on the keyserver (or lookup failed) |

After a successful keyserver fetch, the fingerprint is stored in the cache so later verifications for the same callsign avoid another network lookup.

## 9. The key cache

CQRLOG stores remote public key fingerprints in **`cqrlog_common.gnupg_key_cache`** inside the existing CQRLOG MySQL database. The table is created automatically on first run; no manual migration is required.

Columns include callsign, fingerprint, algorithm, and fetched timestamp.

There is no dedicated cache-clearing menu item in CQRLOG at present. To force a fresh keyserver lookup (e.g. after key rotation or revocation), delete the cached entry directly:

```sql
DELETE FROM cqrlog_common.gnupg_key_cache WHERE callsign = 'LA1ABC';
```

Run this against your CQRLOG MySQL instance (same server CQRLOG uses for logging). The next verification for that callsign will search the keyserver again.

## 10. Hardware token (Nitrokey)

If your **private key** resides on a Nitrokey or similar OpenPGP smart card:

1. Insert the token before starting CQRLOG (or before exporting signed ADIF).
2. No CQRLOG-specific configuration is needed—`gpg-agent` delegates signing to the card.
3. If the token requires a **touch** or PIN, respond when prompted during export signing (same as any other `gpg` signing operation).

Nitrokey devices are a common choice because the firmware is open source and user-upgradeable; any OpenPGP-compatible token supported by `gpg` and `scdaemon` should work the same way.

## 11. Troubleshooting

| Symptom | Likely cause | Action |
|---------|--------------|--------|
| Signing section missing in Preferences | Very old CQRLOG build without this feature | Upgrade to a version that includes GnuPG signing |
| Detect finds no key | No secret signing key in local keyring | Generate a key (section 4) or import your private key |
| key-error.svg on verification | Remote callsign's key not on keyserver | Ask the other operator to publish their key (section 5) |
| key-error.svg persists after key published | Stale cache or keyserver propagation delay | Clear cache entry (section 9); wait up to an hour for keyserver sync |
| Verification fails on otherwise valid import | ADIF record edited after signing | Do not modify signed records; re-export from the originating station |
| gpg-agent PIN prompt does not appear | Agent not running | Run `gpg-agent --daemon` or log out and back in |
| Keyserver fetch times out | Network or keyserver outage | Try `hkps://keyserver.ubuntu.com` in Preferences → Signing |
| Signing works but no icon visible | UI not refreshed | Close and reopen the New QSO window; confirm signing is enabled and fingerprint is set |
