---
source: docs/client_interview_edited.docx
source_type: docx
retrieved: 2026-09-14 15:40
original_filename: client_interview_edited.docx
---

# AI Immersion Meeting-20260914_150758-Meeting Recording

September 14, 2026, 10:07PM

15m 52s

Tristan Leonard   3:32

Okay, I think I'm generally ready.


Young Chul Kim   6:30
Okay.


Tristan Leonard   6:32
Okay, let me try that again. Hi, my name is Tristan and I'm a product owner for Yugabyte. And I'm really excited to see people getting to work and expanding my platform today. Mike, what was the question you had for me earlier?


Young Chul Kim   6:57
We were asking about what the new requirements for the product are. We don't need technical specs, we just need to know like what the business users want to do with the Yuga store and then we will turn those into proposals.


Tristan Leonard   7:03
Okay.


Young Chul Kim   7:18
that you can review.


Tristan Leonard   7:18
Awesome. Okay, cool. So there were three main ideas that we had. You don't have to do all of them, like pick one or two of them, or out of them, I think you can come up with something pretty similar. I'll talk about the first one. It was like constant experiments without engineering as the bottleneck.
So basically, I want to launch a pricing or a homepage experiment on Monday, and I want to read the results by Friday, and I don't want to have to wait on an engineering release trained to do it. Right now, I think product catalog and pricing live inside the product service, and the React UI is this.
the single build. So any experiment means that's what we get a code change, we have to redeploy, and I hate it. It's A bottleneck. It impacts our ability to move fast and iterate. So we could, we totally get you don't want any technical details. I think we could.
try to externalize the pricing and recommendation logic behind configuration or feature flags instead of having it hard-coded into the application. We could have some sort of experimentation like AB layer at the API gateway. We could make the UI read experiment variants from a config service.
We don't, we don't, I don't think we do recommendations yet. Like, I don't know if those exist. Greenfield room for a team to add one. So that's the constant experiments idea. The second idea is when we have a service that starts slowing down or just goes down, I want the storefront to degrade more gracefully.
Yugabytes, our pitch, our goal is to be resilient. And we chose Spring Cloud and we know it has the tools, but I don't think our product is fully implementing those resilience tools. And right now, if we have a slow products or checkout call, it can hang the entire site.
and it's frustrating. So kill the checkout service mid-demo. I still want to see customers browsing and adding to the carts with a clear try again shortly instead of this blank white screen we're getting today. I hope that makes sense. You can take it in terms of like adding circuit breakers or better timeouts or fallbacks and or retries with back off and just letting
letting the users know that we're working on getting us back to work and that things are slower than expected instead of just creating a terrible experience. The last feature idea I had was I hate how we have to redeploy everything when the pricing rules change. And they change all the time. They change on a weekly basis. A merchandiser changes a price rule in a table.
or an admin screen, and I want it to be live in minutes without deploying the code again.
It's basically the same as that first issue I talked about. Pricing is hard-coded in the product service. And we need to move into a better rules and configuration engine. If we can use AI to do it and to do that really quickly, I'm so excited. As long as it keeps the site running and has tests and...
Man, do I love me some unit tests. Like, oh, my grandma always told me 85% code coverage is the sweet spot. And I don't know, she also made really great cornbread. So yeah. Does that answer your question, Mike, or what else you got?


Young Chul Kim   11:01
Yeah, when we talk about resilience, does that also imply adding like an uptime dashboard or other metrics?


Tristan Leonard   11:10
That's a great question. I have to go refresh my memory on what kind of administrative views we have in the site right now. If we do, it would be cool to, oh man, I mean like a feature for non-production would be to like have some sort of adjustment or toggle to like intentionally
add latency. I can't remember what that feature is called, but basically just like adding a bunch of noisy signal and to be able to just say like, yep, behave, behave poorly. Let's see how the site fits or let's say how the site reacts and make sure that the experience is generally positive.


Young Chul Kim   11:53
All right. Hey, Jack Murphy here. Just a quick kind of follow-up on the first question.
When you guys are running experiments and you say you don't want engineering to be a bottleneck, what's kind of the persona of the people who would be running these experiments? Are they still in the engineering org or are these non-technical kind of business stakeholder users?


Tristan Leonard   12:16
Uh.
Um...
That's a good question. Hang on.


Young Chul Kim   12:26
It.


Tristan Leonard   12:28
Don't laugh at me because it's my first day. Uh, let's see.
Standby.
Okay, so...
I think the main people that are running these experiments, these pricing experiments are the merchandisers or the category managers. They get to own the catalog, the pricing, the promotions for a product category. They want to see, they want to change prices on a weekly basis and run promos and
reorder what's featured on the homepage. And right now they have to file this ticket and wait for an engineering deploy before those changes can take effect. So that means that we have to do these on a weekly basis. It puts a lot of pressure upstream to predict, make predictions, but those predictions are often like out of date by the time we get close to the time of the promotion.
So I just, that's a system that I just, I feel like deserves a little more refactor and a little more thought so that we can adapt with better agility.


Young Chul Kim   13:41
Great. And so if we're talking about kind of being able to run experiments across the UX, and then we also have the pricing rules changing on a weekly basis, are those two interrelated or do you visualize those as, you know, discrete paths that you want the product to go down?


Tristan Leonard   14:00
I think those are interrelated or let's just keep it, let's keep them tightly coupled together for now. We might have like merchandise operations or data analyst personas later, but like I think for now the merchandiser or category manager is probably our best one.
If you did need a second one, like a second similar persona, like a pricing or revenue analyst is probably our best bet. They would get to own our pricing strategy, set our intended margin, elasticity testing. What they want to do is test price points and promotion rules against revenue and not just like user clicks.
which overlaps with the merchandiser a bit, but that's it's a lot as a role. It's a lot more analytical and margin focused.


Young Chul Kim   14:52
Wonderful. All right. Well, I know it's your first day, so, you know, no more questions on this side until we can get something in front of you.


Tristan Leonard   14:59
Okay, great. I look forward to seeing what you guys come up with. Nice work, everyone.


Young Chul Kim   15:04
Any other questions on the from the Slalom side here?
No, we're good for now. Okay. Thank you. All right. Thank you so much for your time. Appreciate it.


Tristan Leonard   15:10
All right, thanks all. Talk to you soon.


Young Chul Kim   15:31
Kind of separating different areas of the knowledge base and understand personas and starting to just test drive some of the systems. Yeah, we would probably get just generated that whole thing with that.


Young Chul Kim stopped transcription

<!-- Note: the source .docx embeds 3 small images (image1.png, image2.png, image3.png) reused ~22 times as inline speaker-avatar icons throughout the transcript export. They carry no distinct informational content beyond the speaker names/timestamps already captured in the text above and were omitted from this archive. -->
