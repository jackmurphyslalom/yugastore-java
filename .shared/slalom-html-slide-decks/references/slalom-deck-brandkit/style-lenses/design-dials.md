# Style Lens: Design Dials

Use these dials before authoring when the deck needs a deliberate visual stance.

The dials are planning vocabulary. They do not override Slalom brand rules.

## Dial 1: Design Variance

How much slide geometry and composition should vary?

| Level | Use When | Guidance |
|---|---|---|
| Low | Compliance, appendix, reference, formal executive update | Stable grids, restrained movement, minimal surprise. |
| Medium | Most proposals, POVs, readouts, delivery plans | Vary slide types by job; avoid repeated geometry across adjacent slides. |
| High | HTML-native visual explainer, microsite-like deck, major pitch moment | Stronger resets, more asymmetric layouts, bolder synthesis slides. |

Default: Medium.

## Dial 2: Motion Intensity

How much movement should the live HTML deck use?

| Level | Use When | Guidance |
|---|---|---|
| Static | PowerPoint-like deliverable, heavy review/export needs | No custom motion beyond deck navigation. |
| Restrained | Most HTML decks | Subtle reveals or highlights only when they clarify sequence or focus. |
| Expressive | Interactive explainer or scrollytelling-lite | Motion may build diagrams or reveal stages, but static renders must still work. |

Default: Static to restrained.

## Dial 3: Visual Density

How much information should each slide carry?

| Level | Use When | Guidance |
|---|---|---|
| Sparse | Leadership claim, cover, close, major reset | One claim, one focal visual, minimal support. |
| Standard | Executive POV, pursuit, proposal | Claim plus one structured visual and concise support. |
| Dense | Governance, operating model, workshop artifact, appendix | Use tables, swimlanes, and labels; preserve scanability. |

Default: Standard.

## Recommended Combinations

| Deck Need | Variance | Motion | Density |
|---|---|---|---|
| Executive POV | Medium | Static | Sparse to standard |
| Solution architecture | Medium | Static | Standard |
| HTML visual explainer | High | Restrained to expressive | Standard |
| Tactical operating readout | Low to medium | Static | Dense |
| Redesign refresh | Medium to high | Static or restrained | Match audience |

## Required Declaration

When a dial choice matters, state:

`Design dials: variance=<low|medium|high>, motion=<static|restrained|expressive>, density=<sparse|standard|dense>.`

Then explain the compact deck language in one sentence.

