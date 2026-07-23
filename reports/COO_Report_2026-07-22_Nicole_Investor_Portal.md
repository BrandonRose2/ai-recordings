# COO Meeting Report — Nicole | Investor Portal & K-1 Email Automation
**Date:** Wednesday, July 22, 2026  
**Recording:** V2076-06-22-16-04-38.WAV (60 min) + V2076-06-22-17-04-38.WAV (55 min, personal call — see note)  
**Location:** Office (in-person, with portal demo on screen)  
**Participants:** Brandon Rose (Special Projects), Nicole (COO), Robert (briefly present), Kyle (briefly present, IT/Dev)  
**End Marker Confirmed:** Nicole asks "Are you gonna remember all this?" at [56:34] — confirmed end of business conversation per Brandon's instruction.

---

## Executive Summary

Nicole came to Brandon to discuss automating the K-1 distribution process for Apartment Corp investors. Currently, Nicole manually downloads K-1 PDFs from Sajaka (the company's tax software), emails each investor one at a time, and files documents into Safe. Brandon has already built a preliminary investor portal web app and demonstrated it live during this meeting.

The conversation covered every functional requirement for the portal and its email system. By the end of the meeting, Nicole had signed off on the full scope and Brandon committed to completing the build by end of day July 23, 2026. Nicole's closing remark: *"This is gonna save me a lot of time."* Brandon's recommendation: use Claude (not Manus) for this particular build — *"like you wouldn't cut your hair with a chainsaw, you gotta pick the right tool."*

---

## Note on File 2

The second recording (V2076-06-22-17-04-38.WAV, 55 min) is a **personal phone call** — not a continuation of the Nicole meeting. Brandon is discussing Hanon's recurring GDV episodes (~every 10 days), Royal Canin food, MSG concerns, and piano practice. At [49:57] the other person mentions "Nicole wants done" — a reference to the portal project. This file has been filed to Personal Notes.

---

## Speaker-Labeled Dialogue

### Opening Context (0:00–3:52) — Brandon + Kyle, pre-Nicole

> **Brandon:** "The account stuff on one side. I didn't know where to set up new users."

> **Kyle:** "You gotta go to the three— go to the, uh, users, and then you can add a new user and put in their information. But if you make them an employee, they're gonna be some shady-ass piece of shit company, just like Foxem was, and they're gonna try and backdoor it 'cause they're not willing to pay the 30 grand that you need to pay to integrate with RealPage."

> **Brandon:** "I'm gonna send it to Miles because I'm not managing it. I'm setting it up."

> **Kyle:** "Miles won't know how to do it probably either. I had to do it for Foxem, but Foxem is a bunch of dumb fucks who kept telling me they can't get in."

*[Someone calls Brandon inside. Brief aside. Kyle continues explaining the RealPage backdoor situation.]*

---

### Nicole Arrives — K-1 Portal Origin Story (3:52–4:30)

> **Nicole:** "So I'm in the process of sending K-1s to investors, and Mark just called me about something else, and he's like, 'Oh, well, why don't you have Brandon do that?' And I said, 'Okay, well, you know what? I'll have Brandon create this portal so it has all the information on it.' He actually said something that makes sense. He said, 'Why don't we do something where we can upload the K-1s to the portal, and it sends it out?'"

> **Brandon:** "That's what I did."

> **Nicole:** "You did?"

> **Brandon:** "Yeah. I told you that you can drag and drop — like the W-9, you can do the K-1s, any kind of supporting documents, and it will distribute, customize it, and then you can have a distribution as well. Right here."

> **Nicole:** "Is there a way to get a verification that the email has been sent?"

> **Brandon:** "Yes. Yeah, I mean, if you can think it, you can do it pretty much."

---

### Portal Demo — Document Categories (4:45–7:15)

> **Robert:** "Can you create a clone of Nicole?"

> **Brandon:** "Before you do that — let me go in here. So I need to— I'll show you what you can do. Here's what I set up, and then it has the LP agreements, K-1s, tax forms, and correspondence."

> **Nicole:** "I don't need tax forms. K-1s are the tax forms. And I don't have any correspondence. I might want to send something to all the investors — not you guys."

> **Brandon:** "Okay, so I mean, just the test stuff that I've put in — I just put this here. So it's one thing to upload a document. How does it know—"

*[Co-worker passes through: "Have a good evening, bro." "See you later." "Looks like some serious work going on here. How's your finger?"]*

> **Brandon:** "Navigate here. Scroll bottom, documents, upload documents. Set the category. The file is stored, and then from that, documents—"

---

### Investor List & Email Matching Logic (7:15–32:00)

> **Nicole:** "Do these investors even know how to use this?"

> **Brandon:** "No, it would just email it to you— I mean, to them."

> **Nicole:** "I might want to send something to all the investors, not you guys."

> **Brandon:** "Yeah, you're only gonna send it out to somebody who has an email in the system."

> **Nicole:** "Because, like, a Todd or a Mark or a John McClellan or all these Mennoits entities — the Fam Descendants Trust and Rick Realty and all of those Mennoits entities — don't have an email in there because we're never emailing them. Because they are internal."

> **Brandon:** "Okay. So there's an email address and a name. It'll match the K-1. The K-1 will have the name on it."

> **Nicole:** "Right. So it should be able to match the investor. Though sometimes — for example, there's a guy, his name is Michael Coppins. So the K-1 is made to Michael Coppins, and the investor is actually Coral Village Homes LLC. But then in the notes, I wrote 'Michael Cothrans.' So even if the K-1 name doesn't match exactly the investor, I still want to be able to find it."

> **Brandon:** "Maybe I'll also put a feature right here where you can see the email, preview it, and then maybe a yes or no."

> **Nicole:** "Do you want to be more automated probably?"

> **Brandon:** "Yeah, actually, instead — most of them are straightforward. Like, Steven Gilberg will say Steven Gilberg. Rick Realty will say Rick Realty. S Trust will say S Trust."

> **Nicole:** "I would like an exceptions page. Like, okay, we couldn't match these, or I'm not sure if this is correct — please double-check. I would like to see an exceptions page, but not have to click every single one."

---

### Email System Requirements (32:00–35:00)

> **Nicole:** "And then you want bulk on the email."

> **Brandon:** "I want bulk and individual, because I may have a unique message for one specific person. Like, sometimes people call me, and they ask me information, and I can say, 'Oh, you know, here's your K-1, and by the way, here's the information you called me about.'"

> **Nicole:** "Send me an example now of how your emailing will look."

> **Brandon:** "I just need a very simple message. 'Hi, hope you're doing well. Here's the K-1. Let me know if you have any questions.' That's it. That's all. It's very simple. I don't need any 'Oh, we did really well this year,' or 'Hope you have a good Christmas.' No, no, no."

> **Nicole:** "The other thing is I want to be able to BCC. And I want to be able to CC. And get a verification that the email was sent."

> **Brandon:** "A delivery receipt?"

> **Nicole:** "Not a read receipt, but like a sent receipt. A delivery receipt."

> **Brandon:** "Okay. Are you clear?"

> **Nicole:** "I'm clear."

---

### K-1 Source, MT Entities, and Safe Filing (35:00–54:00)

> **Nicole:** "So I uploaded the Oak Hills ones as an example. Let's — extracting a realistic example email and see if we can figure out what's happening."

*[Extended demo of document upload, matching, and email preview. Discussion of Sajaka as the K-1 source.]*

> **Nicole:** "The MTs I don't need. And sometimes they're not called MT such and such. Sometimes it's property name MT. Like — they finally started getting consistent. But in the beginning, they didn't even put the property name."

> **Brandon:** "I bet you do, yeah."

> **Nicole:** "I have a little cheat sheet that tells me what property this is attached to. There's like five of them."

> **Brandon:** "What about just Mark? Is that just his personal stuff?"

> **Nicole:** "It's a gig of stuff. It's a lot. The MTs — I do want it to pull the information in that first query where I said, 'Okay, download all the K-1s and all the tax returns into this folder called 2025 Tax Returns,' because I am gonna file those into Safe. So I do want everything. But for the investors, I only need the properties that are in there. And I don't need any of the MTs. But some of these other ones like Sparkle — they're our investors. So I do need to send them."

---

### Manual Entry Requirement — Final Portal Scope (54:00–57:25)

> **Brandon:** "Let's go to the investor portal thing. Okay. So we had created — there's the one we're working on. Uh, how did it select 14 properties?"

> **Nicole:** "That's Mark's investments."

> **Brandon:** "No. Let's go back. That's not — those are not the ones that need to be in here. Those, if you click on it, are already here. Yeah, it grabbed it from, like, arbitrarily. 'Cause Mark has invested in more than 14 properties."

> **Nicole:** "I need a manual entry way to add. Those are the Sparkle and the 816 Gulf and the Holly Lane and the Airbnb ones."

> **Brandon:** "So those are already done. Remove what's in it. Yeah, remove that and give me a manual entry. Where I will manually input the properties and who the investors are and how much they own and what their email address is. And then this will be complete in terms of people we need to contact."

> **Nicole:** "Okay. Okay. Are you gonna remember all this?"

> **Brandon:** "Yeah."

> **Nicole:** "All right. Well, you can ask me if you have any questions."

> **Brandon:** "Is there a timeframe?"

> **Nicole:** "I mean, I can probably have it done by the end of tomorrow, but..."

> **Brandon:** "Perfect. This is a great one for Claude, not for Manus. You just — like, tell it what you want. Like you wouldn't cut your hair with a chainsaw. You gotta pick the right tool."

> **Nicole:** "Let's test it out on one or two properties and — I'm gonna see if I got the email yet."

> **Brandon:** "I'll forward it to you if I have it, the email example of the other one. Or I could draft it myself. I mean, it's literally three lines. Um, oh, I'm having to set up an API key. It'll be a minute."

> **Nicole:** "Okay. Well, I will leave you to it. Okay. Then so you don't have to do anything except make sure the email addresses are correct. And even if they're not, you'd get it kicked back. You know what? This is gonna save me a lot of time. 'Cause I gotta go to Sajaka, download the things, email one at a time, take the whole thing, file it into Safe."

> **Brandon:** "Gonna save your life here."

> **Nicole:** "It's exciting."

---

## Portal Requirements — Full Specification

The following table consolidates every requirement confirmed during the meeting:

| # | Feature | Requirement |
|---|---------|-------------|
| 1 | Investor data entry | **Manual entry only** — remove auto-populated data. Fields: property name, investor name, ownership %, email address |
| 2 | K-1 matching | Match K-1 PDF name to investor record; support fuzzy/notes matching for edge cases (e.g., Michael Coppins → Coral Village Homes LLC) |
| 3 | Exceptions page | Show all unmatched K-1s flagged for manual review; no need to click through each one individually |
| 4 | Investor exclusions | Skip investors with no email address (Todd, Mark, John McClellan, Mennoits entities, Fam Descendants Trust, Rick Realty) — they are internal |
| 5 | MT entity handling | Exclude MT entities from investor email distribution; include them in the 2025 Tax Returns download/filing to Safe |
| 6 | Email template | Fixed simple template: *"Hi, hope you're doing well. Here's the K-1. Let me know if you have any questions."* No embellishments |
| 7 | Bulk send | Select multiple investors and send in one action |
| 8 | Individual send | Send to one investor with a custom message |
| 9 | BCC | BCC capability on all emails |
| 10 | CC | CC capability on all emails |
| 11 | Delivery receipt | Confirmation that email was delivered (not a read receipt) |
| 12 | Email preview | Ability to preview the email before sending |
| 13 | Document categories | K-1s, LP agreements, supporting documents — no separate "tax forms" or "correspondence" categories |
| 14 | Properties in scope | Only properties with outside investors: Sparkle, 816 Gulf, Holly Lane, Airbnb properties, and others Nicole will specify |
| 15 | Testing | Test on 1–2 properties before full rollout |

---

## Action Items

### Brandon (Due: End of Day July 23, 2026)

1. **Remove auto-populated investor/property data** from the current portal build — the 14-property auto-pull based on Mark's investments is incorrect and must be cleared.
2. **Build manual entry form** with fields: property name, investor name, ownership percentage, email address.
3. **Build exceptions page** — display all K-1s that could not be auto-matched to an investor record, flagged for Nicole's review without requiring individual clicks.
4. **Implement email system** with bulk send, individual send, BCC, CC, delivery receipt, and email preview.
5. **K-1 matching logic** — support notes-based matching for edge cases (cheat sheet from Nicole covers ~5 cases).
6. **Exclusion rules** — investors without email addresses are skipped for distribution; MT entities excluded from investor emails but included in tax return downloads.
7. **Draft email template** — 3-line template: "Hi, hope you're doing well. Here's the K-1. Let me know if you have any questions."
8. **Use Claude (not Manus)** for this build per Brandon's own recommendation.
9. **Test on Oak Hills** (already uploaded as sample) and one additional property before full rollout.
10. **Set up API key** for email sending (was in progress at end of meeting).

### Nicole

1. Forward an example email from a previous K-1 distribution (or approve Brandon's 3-line draft).
2. Provide the confirmed investor list with email addresses for the in-scope properties.
3. Share the cheat sheet for the ~5 name-mismatch edge cases.

---

## Notable Moments

**Nicole on Mark's suggestion:** Mark called Nicole about something unrelated, then suggested having Brandon create the portal. Nicole's reaction: *"He actually said something that makes sense."* — suggesting this is unusual.

**Nicole on Brandon's prior work:** *"Because we think you're stupid. That's why — until like a few weeks later, 'Oh, that was a good idea.'"* — acknowledging that the portal idea was dismissed earlier.

**Brandon on AI tool selection:** *"This is a great one for Claude, not for Manus. Like you wouldn't cut your hair with a chainsaw. You gotta pick the right tool."* — Brandon is recommending Claude for the structured build task.

**Nicole's current pain point:** *"I gotta go to Sajaka, download the things, email one at a time, take the whole thing, file it into Safe."* — The portal eliminates this entire manual workflow.

**RealPage/Foxem context (pre-Nicole):** Brandon and Kyle discussed a third-party vendor (Foxem) trying to backdoor a RealPage integration rather than paying the $30,000 integration fee. Brandon spent two days on the phone with Emily, Bob, and Ethan to resolve a similar issue for Property Max. This is background context — not directly related to the Nicole portal project.

---

*Report generated: July 23, 2026 | Pipeline: ROSE-REC2 Batch 16 | Analyst: Manus AI*
