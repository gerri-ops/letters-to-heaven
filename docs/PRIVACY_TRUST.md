# Privacy as a product feature

Privacy is not only a long legal policy. Plain trust messages live in the product.

## Trust messages

1. Your journal is private by default.
2. We do not sell personal memories.
3. No advertisements appear beside your entries.
4. Your writing is not used to train an AI model.
5. You control every export and invitation.
6. Delete your data whenever you choose.
7. Existing memories remain available after cancellation.
8. Letters to Heaven will never pretend to speak as the person you lost.
9. Technology protects and organizes the memory. It does not tell you what the memory means—and it is not grief counseling.

Also see [AI_STANCE.md](AI_STANCE.md): we do not compete through AI grief counseling.

## Where they appear

| Surface | Location |
|---------|----------|
| Onboarding | `/privacy` |
| Settings | Privacy & trust → `/privacy-trust` |
| Premium paywall | Trust band + link to promises |
| Legal policy | Secondary link after promises |

## Analytics trust advantage

Never in analytics payloads:

- Sensitive entry text
- Loved-one names
- Exact locations
- Private media
- Search queries

Enforced in `PrivacySafeAnalytics` (`blockedParameterKeys` + approved event names only). Publish this as a trust advantage once verified in the released build.
