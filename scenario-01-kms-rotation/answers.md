# Scenario 1 — KMS key rotation

## 1. Main challenges and impact

These are BYOK keys (`Origin = EXTERNAL`), so AWS does not auto-rotate them. I generate new material on the HSM and import it.

For symmetric keys I use **on-demand rotation**: key ARN and alias stay the same, apps don't change, and old data stays readable under previous material. No bulk re-encryption needed.

Things to watch:
- Keys live in the Security account and are used from Dev/Prod — a bad cutover hits many consumers
- Many keys to rotate (env × service), so this needs a repeatable process, not one-off console work
- Max **25 on-demand rotations** per key
- Import token is valid for **24 hours**
- Don't delete or expire old material while data still depends on it
- Managed Config rule `cmk-backing-key-rotation-enabled` doesn't cover imported keys

## 2. Rotation steps

1. Generate new material on the HSM
2. Call `GetParametersForImport` and wrap the material
3. Import with `ImportType = NEW_KEY_MATERIAL`
4. Run `RotateKeyOnDemand`
5. Test apps, backups, and restores

I do this in dev first, then prod one key at a time.

## 3. Monitoring compliance

I use a **custom AWS Config rule** (not the managed rotation rule). For each S3 / RDS / DynamoDB resource it:
- Reads the KMS key in use
- Checks `ListKeyRotations` for the last rotation date
- Flags resources whose key wasn't rotated on time

I roll this out with a Config aggregator across accounts. CloudTrail on KMS encrypt/decrypt also shows which key material was used, which helps when proving rotation in practice.

## 4. Securing key material in transit

I use the KMS import flow: wrap with the public key from `GetParametersForImport`, send only the encrypted blob over TLS. Plaintext never leaves the HSM.

I'd automate the ceremony where possible (HSM-side wrap job + least-privilege importer role calling KMS), keep the import token window short, and audit every import in CloudTrail.
