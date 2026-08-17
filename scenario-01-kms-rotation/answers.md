# Scenario 1 — KMS key rotation

## 1. Main challenges and impact

These are BYOK keys (`Origin = EXTERNAL`), so AWS does not auto-rotate them. I generate new material on the HSM and import it.

For symmetric keys I use **on-demand rotation**: key ARN and alias stay the same, apps don't change, and old data stays readable under previous material. No bulk re-encryption needed.

Things to watch:
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

I aggregate across accounts and alert on non-compliant findings.

## 4. Securing key material in transit

I use the KMS import flow: wrap with the public key from `GetParametersForImport`, send only the encrypted blob over TLS. Plaintext key material never leaves the HSM.
