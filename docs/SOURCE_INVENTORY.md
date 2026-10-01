# SOURCE INVENTORY — every input document (Phase 0.1 item 2)
Generated: 2026-10-01T13:53:39+1000 by scripts/source_inventory.py · Inputs are immutable (K.3).

## Expected inputs (K.2) — present or missing
| Expected path | Status | SHA-256 (first 16) | Substitute per prompts/SOURCE_MAP.md |
|---|---|---|---|
| docs/design/DESIGN_SPEC.md | MISSING | N/A (file absent) | docs/build-spec/01–11, docs/copy/, docs/system-design.md, docs/api-design.md, docs/design-critique.md, design/figma/README.md (B-001) |
| docs/design/decisions.md | MISSING | N/A (file absent) | docs/build-spec/01–11, docs/copy/, docs/system-design.md, docs/api-design.md, docs/design-critique.md, design/figma/README.md (B-001) |
| docs/design/figma-usage.md | MISSING | N/A (file absent) | docs/build-spec/01–11, docs/copy/, docs/system-design.md, docs/api-design.md, docs/design-critique.md, design/figma/README.md (B-001) |
| docs/design/handoff.md | MISSING | N/A (file absent) | docs/build-spec/01–11, docs/copy/, docs/system-design.md, docs/api-design.md, docs/design-critique.md, design/figma/README.md (B-001) |
| docs/design/metrics.md | MISSING | N/A (file absent) | docs/build-spec/01–11, docs/copy/, docs/system-design.md, docs/api-design.md, docs/design-critique.md, design/figma/README.md (B-001) |
| docs/design/usability-test-plan.md | MISSING | N/A (file absent) | docs/build-spec/01–11, docs/copy/, docs/system-design.md, docs/api-design.md, docs/design-critique.md, design/figma/README.md (B-001) |
| SPEC_CHECKLIST.md | MISSING | N/A (design-session original never existed, B-001) | Planning-run checklist written by spec-drift at 2026-10-01T14:10:02+1000 (D-011): 311 lines, SHA-256 b54b08ad90c8f7c2 — a planning artefact, not an input |
| Main design document, Claude Docs artefact https://claude.ai/code/artifact/3b1b63f2-fca1-45ca-b096-209254c7e970 (K.2 bullet 4) | PRESENT (reachable: Claude Docs connector answered a harmless call [EV: docs/evidence/p00/claude-docs-guide-orchestrator-20261001T135900.md]; content read in Phase 2) | N/A (remote document; no file to hash) | Local PDF export of 28 Sep 2026: research/ADHD planner product design and research.pdf (prompts/SOURCE_MAP.md) |
| research/adhd_struggles.md | present | bf5002e71387ccf5 | N/A (present, no substitute needed) |
| research/interventions_evidence.md | present | a9bbe0d8b3a28c5b | N/A (present, no substitute needed) |
| research/medication_pharmacology.md | present | 33e59451ba787f09 | N/A (present, no substitute needed) |
| research/regulation_privacy_safety.md | present | 28303a36a766ef50 | N/A (present, no substitute needed) |
| research/apple_platform.md | present | ef0204138cc687c3 | N/A (present, no substitute needed) |
| research/learning_and_lifestyles.md | present | ea7569865471927f | N/A (present, no substitute needed) |
| research/competitors_failure_modes.md | present | b1e2324dd7b6e2c8 | N/A (present, no substitute needed) |
| prompts/figma_design_prompt.md | present | 1c3d63784b6374dd | N/A (present, no substitute needed) |
| prompts/figma_urls.md | present | f65216772399701d | N/A (present, no substitute needed) |
| prompts/01_MASTER_PLANNING_PROMPT.md | present | f035de418981b78a | N/A (present, no substitute needed) |
| prompts/02_BUILD_KICKOFF_PROMPT.md | present | 2b60a037e4c7a6ce | N/A (present, no substitute needed) |
| prompts/03_RESUME_PROMPT.md | present | 13c11c5bba02e6ae | N/A (present, no substitute needed) |
| prompts/04_AGENT_BRIEFS_AND_TEMPLATES.md | present | 50a98e2776dcfbee | N/A (present, no substitute needed) |
| prompts/05_SETTINGS_AND_HOOKS.md | present | 94108b87bed3d6e4 | N/A (present, no substitute needed) |
| prompts/06_SCRIPT_SPECS.md | present | f49e9d94683ab438 | N/A (present, no substitute needed) |

## Every file found under the input folders
| Path | Bytes | Lines | SHA-256 | Description (first heading or line) |
|---|---|---|---|---|
| README.md | 2493 | 44 | e5b6fc7c8877979b8302c0b2dbd8a0b84ec1d62b9710b388b5226e764fc029bb | ADHD planner (working title "ADHD Slayer" — see the naming note in the critique) |
| design/figma/README.md | 2312 | 38 | 2758319be2d1bea833493d9e964565c61e39a1d3d5334349de40a96f53e5ea3a | Figma assets |
| design/figma/plugins/focus-day-generator/code.ts | 10384 | 255 | f86ac551544b8cf0e87ddcc30a21ed7d56b27c0397e275dab6a637e8c1521020 | binary/.ts file |
| design/figma/plugins/focus-day-generator/ui.html | 4844 | 126 | d2bbd632fa1ab35551df196921be06452565022ab7b240e0849edd69745376f1 | binary/.html file |
| design/figma/shaders/focus-window-band/main.ts | 7369 | 192 | e185c5871a52de4dc0d85277639c64eb6d19e0eb12ad5332958b1326c87a468e | binary/.ts file |
| docs/api-design.md | 21113 | 458 | 41c980c1200b19c09a767f48a743bd663c58d1052253b876e0d206bd9924cd84 | API and interface design |
| docs/build-spec/01-product-and-features.md | 42927 | 415 | 66c0bfa5db9e323edffca0cb8f3c890e6070adf0481f1b902e744376879d18a3 | Focus: product and features |
| docs/build-spec/02-backend.md | 44960 | 459 | a2d959ab4a19a7f0b5197bc161b9f550f54513400a0123c3d8c5657105e43039 | Backend |
| docs/build-spec/03-data-model.md | 29692 | 434 | 6fea47df570c2b2761c5f633ebe831db1a24123524a045fe8fa9fcf62ecd62f9 | Data model |
| docs/build-spec/04-intelligence.md | 26580 | 271 | 80e9fe876cbf3b092827e6e6f9cc87d7b95c2ad4d3360e82f61b85446942ded1 | Focus: intelligence |
| docs/build-spec/05-platform.md | 28313 | 267 | 626a223af3f0df52b80a44e886a76d36c6c3248e30b5ce970364d27650af1a0d | Focus: Apple platform |
| docs/build-spec/06-compliance-and-safety.md | 36936 | 382 | 2470442d34c9762f77f023c23014be4d61d3f46e19d4a1e72742d0f5f3b99ada | Compliance and safety |
| docs/build-spec/07-problems-and-solutions.md | 33134 | 255 | d9179e420017e068f9b6491c02636737dd6e0dbdcf30aa22e92021919036107d | Problems and solutions |
| docs/build-spec/08-research-requirements.md | 36929 | 374 | c990e4241abb5e7fc59eb08864365c64c1c720e74f8795dbbd5ce07be2f012ea | Research requirements |
| docs/build-spec/09-build-plan.md | 26925 | 345 | d5ccdd2795ed810b6d651ec5191766363dde9009d5e78ec5a83d0d236d5c1d7f | Build plan |
| docs/build-spec/10-live-activities.md | 9309 | 123 | bf90c7356f9e74bd41597c4c554c87c94537b94a655dc1a128e9037eaf11f820 | Live Activities and the Dynamic Island (To build) |
| docs/build-spec/11-backend-contract.md | 12704 | 155 | 07dbddc0cfa55b8aa9eb7abdce52446d6278b5b7047a1adffeee4a3f5a6e5393 | Backend contract (To build) |
| docs/build-spec/_context.md | 10641 | 51 | c3cdb5c1ab045bcba5e5e9fe045cff90a8dbd0a9f22324d6c5a5e597905c2d90 | Build spec: shared context for writers |
| docs/build-spec/_resume.md | 743 | 6 | 38a9c59d1089d0860681fa3c4da95daafcbea419600e872a581dac23b4d227dc | Status (1 Oct 2026) |
| docs/copy/batch1.json | 98137 | 4423 | 8f943b5adf5c05f51d5a643ae68150c7593f180905c42603b931f142c0d4b0da | "splashTagline": [ |
| docs/copy/batch1_slots.json | 2646 | 80 | b2a79573082e6aeca25b56b08b37f886a51da11ba481bcefd6d777828fa16a89 | "splashTagline": { |
| docs/copy/batch1_src.txt | 62557 | 1121 | f8bfb0052cd79da0c413040baac5fa4bde1d98ab5739da652c7232941e1a1330 | @@ splashTagline |
| docs/copy/batch2.json | 91840 | 4423 | 7fbc38c4808d02e6bcc1f20b8017d0ee61587bd8010e5c8f0e07fafaf7ec9a8e | "greetingTitle": [ |
| docs/copy/batch2_slots.json | 2485 | 85 | 6e3ebcbc0bc094360bee36497a311db212808d57c142952425ff910207cd8152 | "greetingTitle": { |
| docs/copy/batch2_src.txt | 57052 | 1111 | c75fb9e894e42262d15bf6fdc80ef1fca03f03940315a2353723e1cacd995a28 | @@ greetingTitle |
| docs/copy/batch3.json | 99702 | 4423 | 4dbaad203325b8dc368ec184799e8ab2ae667522c5a63ace89f12b38337a8c89 | "greetingBody": [ |
| docs/copy/batch3_slots.json | 2671 | 82 | 2acbf152a83e5ba6d91b09b7bb1eb4b3334ed281e65fb85d900acaca632b4a8d | "greetingBody": { |
| docs/copy/batch4.json | 110067 | 4423 | 592d01f30ddb20a72b93c086a79868b042b601f05bc8058c185adf23bad12ebf | "accountTitle": [ |
| docs/copy/batch4_slots.json | 2977 | 91 | 7ff5f128ba30b76b5371f41ef7f5776ebb061d592130b47bb20997c3358ec496 | "accountTitle": { |
| docs/copy/batch4_src.txt | 77449 | 1121 | 4ae15c5dd8034c3623f5fb1f5f7fc83d0460c393cc5ef3f4fbcf25ed0a806828 | @@ accountTitle |
| docs/copy/batch5.json | 116944 | 4423 | 0c9877b893aa0445b4cbf4dc939ec3fe1cddfccfe2fdb230e82cc99d9a848a74 | "accountBody": [ |
| docs/copy/batch5_slots.json | 3009 | 89 | d593382e24106b65c5dbdf12651583983c9896d8b2ee9d737b4a2aa2c025b85a | "accountBody": { |
| docs/copy/batch5_src.txt | 82096 | 1111 | 5a1bd14309f88b98940ca90cd7ea25404c577f8b6a2980b86b82e3782fbe1a59 | @@ accountBody |
| docs/copy/batch6.json | 91373 | 4021 | 84c1ac05cab6c31e5c77e3e759dc7e2ed996baf3db52be8e3bb526916f032a8b | "trialTitle": [ |
| docs/copy/batch6_slots.json | 2402 | 75 | aeaaf99e7a920784f512708047d23100a5d68b5fc7e2102afa8d163dc0f8678f | "trialTitle": { |
| docs/copy/batch6_src.py | 67214 | 1077 | e90712105eceda02702d35c502f937fd444e48746cb735f840d042274935935c | binary/.py file |
| docs/copy/brief.md | 4969 | 54 | 1ec59c116f7ec0984f9d7f40585b329cea3acf5e34f390601b497164b56c8afc | Copy brief: 100 versions of every sentence |
| docs/copy/merge.py | 1997 | 39 | 746e4dddcccc73638513091b02f9c434d34b8a9cc64d9340aea79f4a3e3326f1 | binary/.py file |
| docs/copy/slots.json | 16180 | 497 | ff9090d38ef1020d4dd85dbc0f85e07cb3790a1b969989d29c237eef2f2b0808 | "splashTagline": { |
| docs/design-critique.md | 10953 | 119 | 493769f4a5806dd00df12cffe12050d8846a54118d851778a2b735c85660daa3 | Design critique: ADHD planner — Figma v0.1 + SwiftUI prototype |
| docs/research-notes/apple.md | 84980 | 371 | f6e1a0f69f07d3627f2928b5d516fdc0f59aca4f61010399e2422c1042e98b2a | Apple platform build requirements (extracted from apple_platform.md) |
| docs/research-notes/failure_modes.md | 40768 | 293 | f41be7c9a1c2a685e1ea541afd7966eb5ffef86e1f80e5b2d2775f5a8aa457cd | Failure modes and build lessons (product-agnostic) |
| docs/research-notes/interventions.md | 84022 | 396 | a76ee5a9795f9e6006dc86bf240dfc082780878f626815ab01fa27e9bc0921c8 | Interventions evidence: build requirements |
| docs/research-notes/learning.md | 78672 | 397 | 42f2fb82009f19a3b6f981470fb236eee3f1c718f9639807207051a33f232d79 | Build extraction: personal learning, medication focus window, lifestyles (day types) |
| docs/research-notes/pdf_01_20.md | 62565 | 456 | c8c1918cd196c9ef205cfa0eab4677d1e8150e5046f51235934ce29ac51840fa | ADHD planner PDF extraction: pages 1 to 20 |
| docs/research-notes/pdf_21_40.md | 77463 | 535 | 40ee7d479f553f97cc2474039196e9f12c3d5cba343abfee1e2502f82b5b7261 | Build requirements from PDF pages 21 to 40 |
| docs/research-notes/pdf_41_60.md | 76222 | 529 | 25b0f59b2dd399881718c313dafec2bd753b1ec3b41f6ef343f45bc64884f492 | Build requirements extracted from PDF pages 41 to 60 |
| docs/research-notes/pdf_61_80.md | 51440 | 422 | c553ba2a225b1207581ea0a8df42971d3fa6398da1dc3d1d5af128dce5d75014 | Build requirements: PDF pages 61 to 80 |
| docs/research-notes/pharmacology.md | 76450 | 396 | 6c07d65d006b76fb1c88c6cfe402f48ec9f9a178691a37e09f694eced5902581 | Pharmacology research: build requirements extraction |
| docs/research-notes/regulation.md | 74754 | 557 | fdf510284a4c0fc3450f98fd8c215b17c1d1c075753704aed99c29fb0b6fbf75 | Regulation, privacy and safety: build requirements |
| docs/research-notes/struggles.md | 85077 | 474 | 3888d9464e1e6fd79ae2fc66706d7241e01fefa9a08a54da448d580f6366ee7d | Build requirements extracted from adhd_struggles.md |
| docs/system-design.md | 28640 | 441 | e8ee77b631b3ba2d128ae5c425afee22c678fa6ea09f082b62d021ce103ca15b | System design |
| prompts/00_README_DEVESH.md | 21544 | 129 | 70a714f85bef3fc9eb63bff1bcdf3e257e1b15cf83ec6838ce8fcf25b02eeee6 | READ ME FIRST — how to run the Planner planning and build with Claude Code |
| prompts/01_MASTER_PLANNING_PROMPT.md | 243933 | 978 | f035de418981b78a2662e730afb010f4696136c6b5480efa758e2327e837057d | MASTER PROMPT — PLANNER: FIGMA TO PRODUCTION BUILD PLAN (v3, 1 October 2026) |
| prompts/02_BUILD_KICKOFF_PROMPT.md | 27335 | 109 | 2b60a037e4c7a6ce8e4437a013b22d063b83f9d82a197b1aeb161ba929712ef4 | BUILD KICKOFF — PLANNER (paste after planning is complete and the checkpoint in `prompts/00_README_DEVESH.md`  |
| prompts/03_RESUME_PROMPT.md | 6550 | 46 | 13c11c5bba02e6aed4e9226a3fc9dbe60112fdd0e97ecade29699b629fb31ec6 | RESUME PROMPTS — paste one variant into a fresh Claude Code session started in the project folder with `claude |
| prompts/04_AGENT_BRIEFS_AND_TEMPLATES.md | 27014 | 412 | 50a98e2776dcfbeec134cc2da7e1c99748986b6556799741f4b4b823ffd92387 | AGENT BRIEFS AND TEMPLATES — copied by the orchestrator; never pasted by Devesh |
| prompts/05_SETTINGS_AND_HOOKS.md | 23594 | 366 | 94108b87bed3d6e4020d58e5328a11360bd042aafb5c8a5de1bc461ca063db19 | SETTINGS AND HOOKS — the mechanical enforcement of the operating mode |
| prompts/06_SCRIPT_SPECS.md | 26548 | 299 | f49e9d94683ab438934457acc8f012bc050a2aaeb96b0656029a0e598b6b4c1d | SCRIPT SPECIFICATIONS AND REFERENCE IMPLEMENTATIONS |
| prompts/SOURCE_MAP.md | 3132 | 43 | 16e7b6dfb4133130bd7d833e06335e635baa7c1aa89c87053fc76b1474859b3f | Source map for the planning run |
| prompts/figma_design_prompt.md | 19037 | 181 | 1c3d63784b6374dd0c507399f806d85771da9ab739b8a25f3db6b20b33693dc0 | Claude Code prompt: design the ADHD planner in Figma |
| prompts/figma_urls.md | 904 | 12 | f65216772399701de49569a36916befb538b9ae9c4acb6c85415de01c8fad14c | https://www.figma.com/design/gLuoHFbiiUGajAUpluWXOW/Focus |
| research/ADHD planner product design and research.pdf | 2692762 | 82363 | 2032d37251982d13899ab2226b6188372b5f0e1e6c0cdbb2b7d384cd7003e737 | binary/.pdf file |
| research/adhd_struggles.md | 76520 | 471 | bf5002e71387ccf508a6199c0b5117fa78827224664fc7367d55408f96b084a7 | Day-to-day struggles of adolescents (16+) and adults with ADHD: catalogue for a medication-centred iPhone/Appl |
| research/apple_platform.md | 78746 | 758 | ef0204138cc687c342ff0c3bdc50f5b0c4c6bbf03c22ee42688dbd4cc2e55b31 | Apple platform frameworks for an ADHD planning and medication-window app (iPhone, Watch, Mac, iPad), as of lat |
| research/competitors_failure_modes.md | 67156 | 555 | b1e2324dd7b6e2c88389cac550ab948bc4657f060275a942cd19e9db72a206ae | ADHD planner / medication-tracking / AI-scheduling apps: competitive landscape, gaps, failure modes and mitiga |
| research/interventions_evidence.md | 69222 | 693 | a9bbe0d8b3a28c5b2df15f59142d3ef41a4773bd85f430a88cb484353e9f5d54 | Evidence-based non-drug interventions, behavioural techniques and digital-health design principles for adolesc |
| research/learning_and_lifestyles.md | 64095 | 498 | ea7569865471927fb00a14f5ab91fd24b29b5411050ddb6b874ef5478b887e51 | Learning from one user with small data, plus the "Lifestyle 2" regime toggle (ADHD planner, iPhone/Apple Watch |
| research/medication_pharmacology.md | 70898 | 570 | 33e59451ba787f09db51bcb34ecf3538c1ecfde4d9a5bb84e21ebeba25f31591 | ADHD medication pharmacokinetics and pharmacodynamics for a personalised "medication effect window" model |
| research/regulation_privacy_safety.md | 88406 | 534 | 28303a36a766ef506a390458bdd1b8964282bbd6de931d98397b2efbd7b98bfa | Regulation, privacy, safety and App Store constraints for an ADHD medication-aware planner (iPhone/Apple Watch |

Files listed: 70 · Expected missing: 7

Prototype code under app/ is listed in docs/PREFLIGHT.md and D-003, not here (it is code, not a document).

<!-- END OF FILE -->
