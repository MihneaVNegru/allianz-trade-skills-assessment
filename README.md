# Allianz Trade — Skills Assessment

AWS-focused skills assessment responses: architecture notes, design answers, and a Terraform module for the backup scenario.

Responses are kept short and practical, with enough technical detail to explain each decision.

## Scenarios

| # | Topic | Deliverable |
|---|--------|-------------|
| 1 | [Encryption management — KMS key rotation](scenario-01-kms-rotation/answers.md) | Design answers |
| 2 | [APIs-as-a-Product — public & private APIs](scenario-02-apis-as-product/answers.md) | Design answers |
| 3 | [Resilience & monitoring — GitLab](scenario-03-gitlab-resilience/answers.md) | Design answers |
| 4 | [Backup policy — AWS Backup](scenario-04-aws-backup/README.md) | Terraform module |

## How to review

1. Open each scenario folder and read `answers.md` (scenarios 1–3).
2. For scenario 4, start with the [module README](scenario-04-aws-backup/README.md), then inspect `modules/aws-backup-policy/` and `examples/basic/`.

## Notes

- Scenario write-ups paraphrase the given architecture enough to stand alone; they do not reproduce the original assessment materials.
- The Terraform module is intentionally illustrative (skills validation), not a full production landing-zone package.
