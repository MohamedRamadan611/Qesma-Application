# Receipt scanning: privacy policy draft text (input for SA13)

Draft, not legal advice. SA13 merges this into the privacy policy and the Play Data safety form. Decisions: A144–A146, A169, A170.

## What the feature does
When you choose "Scan receipt", Qesma sends **the photo you take or pick** to Google's Gemini service (through Firebase AI Logic) so that it can read the items and amounts. The result is shown to you as a draft. You check every number and assign the people; nothing is saved until you save.

## What is sent, and what is not
- Sent: the photo (resized to at most 1600 px on its longest side, JPEG, with location and camera information removed before it leaves the phone), and a fixed instruction text.
- Not sent: your name, the group, the members, any amount you typed, your contacts, your location, or any account identifier. Qesma has no account.
- The request carries a Firebase App Check token (proves the request comes from the genuine app on a genuine device) and the Firebase project identifier. No API key is stored in the app.

## What Qesma keeps
- The photo is never saved by Qesma: it is held in memory, and the temporary copy made by the camera or gallery picker is deleted right after it is read. Photos taken with the camera are not added to your gallery by Qesma.
- On the phone, Qesma stores only: whether you agreed, the date you agreed, today's scan count (limit 20 per day), and a counter used to hide the feature after repeated permission errors. These are not part of the backup and are removed with the app data.
- Qesma logs neither the photo nor the answer.

## What Google may do (free tier)
Qesma uses the free tier of the Gemini Developer API (no billing account). Under Google's Gemini API Additional Terms for unpaid services (effective 2026-03-23, to be re-read before release), Google may use the content you submit and the responses to provide, improve and develop Google products and machine-learning technologies, and human reviewers may read them. Do not photograph anything private (for example a card or an ID). The paid-service terms, which do not use the content this way, do not apply to this app.

## Your choices
- You can always type the items yourself: scanning is optional and the app works fully without it.
- You can turn scanning off at any time in Profile, "Receipt scanning"; the next scan asks again.
- Uninstalling the app removes everything stored on the phone. Qesma cannot delete what Google received; see Google's terms and privacy policy.

## Region note (A170)
The terms say that only paid services may be used when the app is made available to users in the EEA, Switzerland or the United Kingdom. The free-tier launch is therefore limited to Egypt in the Play listing (owner to confirm in SA13); otherwise a billing account (paid terms) is required before those regions are enabled.

## Play Data safety (suggested answers, to verify in SA13)
- Photos: collected, shared with Google (service provider for the feature), optional, not stored by Qesma, encrypted in transit.
- No other data types are collected or shared.
