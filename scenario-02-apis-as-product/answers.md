# Scenario 2 — Public and private APIs

## 1. Weaknesses in the current architecture

- Internal APIs are public for no reason
- Regional API Gateway can be hit directly, bypassing CloudFront / global WAF
- One shared public entry point for many teams — bigger blast radius
- Internal calls go out to the internet and back in through CloudFront

## 2. Proposed architecture

I'd split APIs by who uses them, and keep the backends as they are:

- **Internal-only:** private API Gateway + `execute-api` VPC endpoint (`aws:SourceVpce` in the resource policy). Reachable from our VPCs, and from on-prem over VPN / Direct Connect into that PrivateLink path.
- **Public + internal:** CloudFront for external users; private endpoint + private DNS for internal users (same hostname if possible, skip CloudFront)

That removes the internet hairpin for internal traffic with little app change.

## 3. Routing CloudFront to multiple API Gateways

In the current setup, CloudFront is what splits traffic across the team API Gateways — not a single Gateway routing everything.

That means one origin per API Gateway, plus path-based behaviours:

- `/policies/*`, `/claims/*`, `/quotes/*` → each team's API Gateway
- More specific paths first, default last
- Caching disabled for APIs; forward auth headers, but not the viewer `Host` header to `execute-api`

## 4. Preventing users from bypassing CloudFront

Best fix: make the API private so there is no public `execute-api` URL to hit.

If the regional endpoint must stay public for now: CloudFront adds a secret custom header, and a regional WAF blocks anything without it. I wouldn't rely on the CloudFront IP prefix list on its own, since it doesn't tell our distribution apart from anyone else's.
