# Batch 11 analysis notes (scan_run12.json)

3 new ROSE-REC2 files. NOTE: device clock glitch — filenames say year 2076 ("V2076-06-07-...") but content is clearly July 7, 2026 evening (continues afternoon conversations: cost seg project, Ellie/Victoria shopping, colleague leaving). Mention this in report; suggest checking device date settings.

IDs to mark done (scan_run12.json):
- 1o-s3M-GDhGUySJSYisCL7NJBorUxJE9_ ROSE-REC2_V2076-06-07-15-46-04.WAV
- 1mUm_Lqf9gf9fn6qfJZrMJJGr4tp_3mwS ROSE-REC2_V2076-06-07-16-46-05.WAV
- 1pzGHSen8vLvWvkSP9o5oN_hygnVcZgeT ROSE-REC2_V2076-06-07-17-13-45.WAV

## File 1: 15-46-04 (1h, transcript 3375 bytes — sparse)
- Mostly quiet/office ambient; fragments: shopping talk with Ellie/Victoria mention, swim trunks, Nathan in kitchen, crude banter, "Huble" gadget/watch banter, Porterhouse.
- KEY WORK SEGMENT 42:00-43:02: AI credits discussion — colleague asks "How many credits did you use today?" $400/week hoarding concern; Brandon: almost done with cost seg thing; "Grace has twenty-six buildings... hundreds of sheets"; Marc can look at logs; Brandon has own personal account (8k credits), pays for it himself. Justifiable if used for cost seg.
- Sort: Meetings (work content) or Other? — has work discussion (AI credits/cost seg) → Meetings.

## File 2: 16-46-05 (25 min, transcript 75 bytes = effectively silent)
- No speech content. → Other (recommend deletion).

## File 3: 17-13-45 (23 min, transcript 31KB — rich)
- End-of-day office conversation, likely with Ethan (spam filter/IT context) + Tony (new voice? older colleague: "He communicates through Robert to me... I think he just wants to walk over people, I'm not the guy").
- 01:37-03:36: FedEx/shipping frustration; Mark yells if packages go out wrong; Nicole says "he won't ask"; "damned if you do, damned if you don't"; Mark unreasonable re: spam filter urgent requests then "I'm busy now, I'll look in half an hour"; "He'll just forget about it... you were just pretending to be me."
- 05:35-06:21: Colleague (Tony?) on Mark: communicates through Robert, doesn't call directly, "wants to walk over people."
- More Marc temper/behavior evidence (secondhand accounts) → add to profiles.json temper_evidence.
- Sort: Meetings.

## Marc profile additions:
- "Jul 7 (device-dated 2076-06-07) 17-13 at 01:37-03:36 — staff FedEx dilemma: Mark yells about shipping, makes urgent spam-filter demands then forgets ('you were just pretending to be me')"
- "Jul 7 17-13 at 05:35-06:21 — colleague (possibly Tony): Mark 'communicates through Robert', 'wants to walk over people'"

## New observed person:
- Tony (older colleague? pushes back on Mark, Mark stopped daily calls to him) — add to observed_people_not_yet_profiled.
- Nathan (office, in kitchen) — add.

## Report filing:
- 15-46-04 → Meetings (AI credits / cost seg discussion)
- 16-46-05 → Other (silent, delete)
- 17-13-45 → Meetings (Marc behavior discussion, end-of-day)
- Flag device clock issue (2076) to user.
