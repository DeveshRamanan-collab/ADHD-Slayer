import Foundation

/// Every sentence in the app that has a voice lives here, with 100 hand-written versions each in
/// Copy.json, so the app reads a little differently every day.
///
/// Rules the deck follows: plain words, short sentences, no dashes as punctuation, jokes only where
/// nothing important is at stake, and every joke is one someone with ADHD would laugh at rather than
/// feel poked by. Medication, safety, legal and money wording never jokes and never rotates into
/// anything that changes its meaning; buttons and labels never rotate at all, so muscle memory works.
enum CopySlot: String, CaseIterable, Codable {
    // First launch
    case splashTagline, greetingTitle, greetingBody, accountTitle, accountBody, trialTitle, trialWhy, welcomeHome
    // Coach marks
    case coachPriorities, coachMeds, coachDots, coachSetup, coachDone
    // Home and Today
    case fiveThingsEyebrow, medsAllLogged, medsNothingDue, medsLoggedToast, medsNone
    case nowGap, nowThen, dayLineWarming, dayLineBest, dayLineLighter, dayLineAfter, dayLineRoutine
    case restHeadline, restOneLeft, restUnplaced, shapesHeadline, changeFootnote
    case tinyWinsTitle, tinyWinsEmpty, breatheIntro, socialLine, socialMessage
    // Daily arrival
    case arrivalMorning, arrivalAfternoon, arrivalEvening, arrivalQuestion
    // Plan and Rhythm
    case planWeekHeadline, planWeekExplainer, rhythmIntro, rhythmTuneTitle, rhythmTuneBody, rhythmFooter
    case detailPlanDone, detailBrain, detailHours, detailWindow, detailEstimates, detailSleep, detailLogs
    // Medication, Personalise, Customise, Settings
    case dayTypesIntro, dayTypesLimit, actionButtonPitch, personaliseIntro, categoriesLimit, socialIntro
    case hyperfixationWarning, customiseIntro, settingsIntro
    // Moments
    case focusDoneCheer, fixHeadline, fixSubtitle, emptyPlan

    enum Tone: String, Codable {
        /// Kind and plain, never a joke: anything near medication, health, money or safety.
        case serious
        /// Warm; a gentle smile at most.
        case light
        /// Allowed to be properly funny, in an ADHD way.
        case playful
    }

    struct Spec: Codable {
        let tone: Tone
        let placeholders: [String]
        let maxCharacters: Int
        let context: String
        let example: String
    }

    var spec: Spec {
        switch self {
        case .splashTagline: Spec(tone: .light, placeholders: [], maxCharacters: 48, context: "Under the app name on the animated starting screen, first launch.", example: "Plans that know how your brain works.")
        case .greetingTitle: Spec(tone: .playful, placeholders: [], maxCharacters: 32, context: "Big serif hello on the first screen after the start animation.", example: "Hi. Welcome in.")
        case .greetingBody: Spec(tone: .light, placeholders: [], maxCharacters: 150, context: "One or two sentences under the hello, saying what the app is: a planner built around an ADHD brain and its medication.", example: "This is a planner built around your brain and your medication, not the other way round.")
        case .accountTitle: Spec(tone: .light, placeholders: [], maxCharacters: 44, context: "Heading on the create-account screen.", example: "First, somewhere to keep your stuff.")
        case .accountBody: Spec(tone: .serious, placeholders: [], maxCharacters: 150, context: "Why an account: plans follow you to a new phone; medication is encrypted and never readable by us.", example: "An account lets your plans follow you to a new phone. Your medication is encrypted and we can’t read it.")
        case .trialTitle: Spec(tone: .light, placeholders: [], maxCharacters: 44, context: "Heading on the free-trial screen before the free plan. Must not state a trial length (Apple’s offer shows that).", example: "Try all of it, free, for a month.")
        case .trialWhy: Spec(tone: .light, placeholders: [], maxCharacters: 190, context: "Why the trial exists: ADHD takes time to understand, and so does knowing if an app works for you. If it doesn’t, just cancel. Must end with the idea of cancelling being easy.", example: "Because ADHD takes time to figure out, and so does knowing whether an app actually helps. If it doesn’t, just cancel.")
        case .welcomeHome: Spec(tone: .playful, placeholders: [], maxCharacters: 70, context: "Small toast the first time the home page appears.", example: "You’re in. Have a wander.")
        case .coachPriorities: Spec(tone: .light, placeholders: [], maxCharacters: 90, context: "Coach mark pointing at today’s five priorities.", example: "These are today’s five. Short on purpose.")
        case .coachMeds: Spec(tone: .serious, placeholders: [], maxCharacters: 100, context: "Coach mark pointing at the home medication row: two medication buttons (tap to log, hold for another time) and a more button (every dose today, with Log all).", example: "Your medication lives here. Tap one to log it. More shows the rest.")
        case .coachDots: Spec(tone: .playful, placeholders: [], maxCharacters: 90, context: "Coach mark pointing at the page dots: flick up for the next page.", example: "Flick up for the next page. The dots show where you are.")
        case .coachSetup: Spec(tone: .light, placeholders: [], maxCharacters: 110, context: "Coach mark suggesting they set up medication and day types in You.", example: "Set up your medication and day types in You. It takes about two minutes.")
        case .coachDone: Spec(tone: .playful, placeholders: [], maxCharacters: 70, context: "Last coach mark; they can now explore freely.", example: "That’s the tour. Wander wherever you like.")
        case .fiveThingsEyebrow: Spec(tone: .light, placeholders: [], maxCharacters: 24, context: "Tiny uppercase label above today’s five priorities.", example: "Today, in five")
        case .medsAllLogged: Spec(tone: .light, placeholders: [], maxCharacters: 50, context: "Shown under the medication row when everything set for today is logged.", example: "All logged. Nice.")
        case .medsNothingDue: Spec(tone: .serious, placeholders: ["time"], maxCharacters: 64, context: "Nothing to log right now; says when the next one is set for.", example: "Nothing to log right now. Next at {time}.")
        case .medsLoggedToast: Spec(tone: .light, placeholders: ["count"], maxCharacters: 60, context: "Toast after Log all logs some doses.", example: "Logged {count}. Done and dusted.")
        case .medsNone: Spec(tone: .serious, placeholders: [], maxCharacters: 80, context: "No medication set up yet; invites them to add it.", example: "No medication set up yet. Add it whenever you’re ready.")
        case .nowGap: Spec(tone: .playful, placeholders: [], maxCharacters: 40, context: "Headline when nothing is scheduled right now.", example: "This gap is yours.")
        case .nowThen: Spec(tone: .light, placeholders: ["task", "time"], maxCharacters: 60, context: "Line under the Now card saying what’s next.", example: "Then {task} at {time}.")
        case .dayLineWarming: Spec(tone: .light, placeholders: ["time"], maxCharacters: 52, context: "Status line: medication is warming up, best focus starts at time.", example: "Warming up. Best focus from {time}.")
        case .dayLineBest: Spec(tone: .light, placeholders: ["time"], maxCharacters: 40, context: "Status line: in best focus until time.", example: "Best focus until {time}.")
        case .dayLineLighter: Spec(tone: .light, placeholders: ["time"], maxCharacters: 40, context: "Status line: lighter focus until time.", example: "Lighter focus until {time}.")
        case .dayLineAfter: Spec(tone: .light, placeholders: [], maxCharacters: 50, context: "Status line: the focus window has ended for today.", example: "Focus window’s done for today. Go gently.")
        case .dayLineRoutine: Spec(tone: .serious, placeholders: [], maxCharacters: 60, context: "Status line on a medication-free or not-yet-logged day.", example: "Planning from your routine today.")
        case .restHeadline: Spec(tone: .light, placeholders: ["count"], maxCharacters: 34, context: "Headline: how many things are left today (count is 2 or more).", example: "{count} things left")
        case .restOneLeft: Spec(tone: .playful, placeholders: [], maxCharacters: 34, context: "Headline: exactly one thing left today.", example: "One thing left")
        case .restUnplaced: Spec(tone: .light, placeholders: ["count"], maxCharacters: 110, context: "Some tasks didn’t fit without over-packing; Fix my day can help.", example: "{count} didn’t fit without over-packing. Fix my day can split or move it.")
        case .shapesHeadline: Spec(tone: .light, placeholders: ["done", "total"], maxCharacters: 36, context: "Headline: done of total tasks.", example: "{done} of {total} done")
        case .changeFootnote: Spec(tone: .light, placeholders: [], maxCharacters: 80, context: "Reassurance under Fix my day and Baseline buttons.", example: "Nothing moves until you say so. Undo is always one tap.")
        case .tinyWinsTitle: Spec(tone: .playful, placeholders: [], maxCharacters: 40, context: "Headline on the page listing what they’ve finished today.", example: "Look what you already did.")
        case .tinyWinsEmpty: Spec(tone: .playful, placeholders: [], maxCharacters: 70, context: "Nothing finished yet today. Never shaming.", example: "Nothing ticked off yet. The day is young.")
        case .breatheIntro: Spec(tone: .light, placeholders: [], maxCharacters: 90, context: "Intro to a one-minute paced breathing page where the phone taps along.", example: "In for four, out for six. Your phone will tap along.")
        case .socialLine: Spec(tone: .light, placeholders: ["event", "time"], maxCharacters: 80, context: "Short line on the home page: a plan with other people sits at an awkward time; tap to see a suggestion.", example: "{event} is at {time}. Want to ask to move it?")
        case .socialMessage: Spec(tone: .playful, placeholders: ["name", "event", "time"], maxCharacters: 160, context: "Draft text message the person may send a friend asking to move a plan. Warm, casual, may joke about their own brain. They edit it before sending.", example: "Hey {name}, any chance we could do {event} at {time} instead? My brain’s much better company then.")
        case .arrivalMorning: Spec(tone: .light, placeholders: ["name"], maxCharacters: 40, context: "Morning greeting on the daily starting page.", example: "Good morning, {name}.")
        case .arrivalAfternoon: Spec(tone: .light, placeholders: ["name"], maxCharacters: 40, context: "Afternoon greeting on the daily starting page.", example: "Good afternoon, {name}.")
        case .arrivalEvening: Spec(tone: .light, placeholders: ["name"], maxCharacters: 40, context: "Evening greeting on the daily starting page.", example: "Good evening, {name}.")
        case .arrivalQuestion: Spec(tone: .light, placeholders: [], maxCharacters: 40, context: "The one question on the daily starting page: how their brain feels today (answers are Low, Okay, Good).", example: "How’s your brain today?")
        case .planWeekHeadline: Spec(tone: .light, placeholders: ["count"], maxCharacters: 44, context: "Headline: how many of the last 7 days met their baseline.", example: "{count} of 7 days counted")
        case .planWeekExplainer: Spec(tone: .light, placeholders: [], maxCharacters: 170, context: "Explains a baseline day: the three things that keep life moving; most weeks aren’t 7/7 and that’s fine.", example: "A day counts when your baseline is done. Most weeks aren’t seven out of seven. That’s the whole point of a baseline.")
        case .rhythmIntro: Spec(tone: .light, placeholders: ["count"], maxCharacters: 60, context: "Under ‘Four weeks of you’: how many days counted this week.", example: "This week, {count} of 7 days counted.")
        case .rhythmTuneTitle: Spec(tone: .playful, placeholders: [], maxCharacters: 44, context: "Headline inviting them to edit their learned patterns.", example: "Something here not quite you?")
        case .rhythmTuneBody: Spec(tone: .light, placeholders: [], maxCharacters: 140, context: "What they can change on the Patterns page; plans follow at once.", example: "Change your focus window, how long things take, how full days get and when you eat. Plans follow straight away.")
        case .rhythmFooter: Spec(tone: .serious, placeholders: [], maxCharacters: 70, context: "Footer: patterns, not scores; the data stays on the iPhone.", example: "Patterns, not scores. All of this stays on your iPhone.")
        case .detailPlanDone: Spec(tone: .light, placeholders: [], maxCharacters: 110, context: "Explains the planned vs done chart: grey planned, gold done; gaps are information not failure.", example: "Grey is what you planned, gold is what got done. Gaps are information, not failure.")
        case .detailBrain: Spec(tone: .light, placeholders: [], maxCharacters: 120, context: "Explains the brain weather chart; on low days the app planned a baseline day.", example: "How you said your brain felt each morning. On low days the plan got lighter on its own.")
        case .detailHours: Spec(tone: .light, placeholders: [], maxCharacters: 90, context: "Explains the hour heatmap: each dot is an hour; brighter means more finished.", example: "Each dot is an hour. The brighter it is, the more you finished then.")
        case .detailWindow: Spec(tone: .serious, placeholders: [], maxCharacters: 130, context: "Explains the learned focus curve: how often check-ins said it was working, by hours after logging; the band is certainty.", example: "How often your check-ins said it was working, by hours after logging. The shaded band is how sure the app is.")
        case .detailEstimates: Spec(tone: .playful, placeholders: [], maxCharacters: 100, context: "Explains the estimates chart: your guess, then what it really took; plans add a buffer.", example: "Your guess, then what it actually took. Plans now add the difference for you.")
        case .detailSleep: Spec(tone: .light, placeholders: [], maxCharacters: 100, context: "Explains the sleep chart: bars are hours slept, the line is how much of the plan got done the next day.", example: "Bars are hours slept. The line is how much of the next day’s plan got done.")
        case .detailLogs: Spec(tone: .light, placeholders: [], maxCharacters: 90, context: "Explains the log-times chart: each dot a logged morning; the band is where most fall.", example: "Each dot is a logged morning. The band is where most of them land.")
        case .dayTypesIntro: Spec(tone: .light, placeholders: [], maxCharacters: 110, context: "Intro to day types on the Medication page: different days have different rhythms; name them anything.", example: "Different days, different rhythms. Name them whatever makes sense to you.")
        case .dayTypesLimit: Spec(tone: .light, placeholders: [], maxCharacters: 110, context: "They hit the free plan’s three day types; Plus has unlimited. No pressure wording.", example: "The free plan holds three day types. Plus holds as many as your life has.")
        case .actionButtonPitch: Spec(tone: .light, placeholders: [], maxCharacters: 100, context: "Suggestion right after medication setup: log with one press of the Action button.", example: "Want to log with one press? Your Action button can do it.")
        case .personaliseIntro: Spec(tone: .light, placeholders: [], maxCharacters: 110, context: "Intro to the Personalise page: tell us when you like doing things and the plan leans that way.", example: "Tell us when you like doing things. The plan will lean that way.")
        case .categoriesLimit: Spec(tone: .playful, placeholders: [], maxCharacters: 110, context: "They hit the free plan’s five categories; Plus has unlimited.", example: "Five categories on the free plan. Plus if you need more boxes. We won’t judge.")
        case .socialIntro: Spec(tone: .light, placeholders: [], maxCharacters: 130, context: "Explains social suggestions: the phone spots plans with people and suggests better times; nothing is ever sent for them.", example: "Your phone can spot plans with people and suggest better times. Nothing ever gets sent for you.")
        case .hyperfixationWarning: Spec(tone: .playful, placeholders: [], maxCharacters: 100, context: "Quirky warning at the top of the Customise page: this might become their hyperfixation and eat the next six hours.", example: "Careful. This page might become your hyperfixation and eat the next six hours.")
        case .customiseIntro: Spec(tone: .light, placeholders: [], maxCharacters: 90, context: "Intro to Customise: make it yours; nothing here can break your plan.", example: "Make it yours. Nothing here can break your plan.")
        case .settingsIntro: Spec(tone: .playful, placeholders: [], maxCharacters: 60, context: "Intro to Settings.", example: "The boring but important bits.")
        case .focusDoneCheer: Spec(tone: .playful, placeholders: [], maxCharacters: 50, context: "Small cheer after marking a focus block done.", example: "Done. Brain one, chaos nil.")
        case .fixHeadline: Spec(tone: .light, placeholders: ["count"], maxCharacters: 34, context: "Fix my day headline: count small changes (count is 2 or more).", example: "{count} small changes")
        case .fixSubtitle: Spec(tone: .light, placeholders: ["minutes"], maxCharacters: 110, context: "Fix my day subtitle: running minutes over; this is the smallest change that keeps today on track.", example: "You’re running {minutes} min over. Here’s the smallest change that keeps today on track.")
        case .emptyPlan: Spec(tone: .playful, placeholders: [], maxCharacters: 60, context: "Nothing planned today.", example: "Nothing planned. Suspiciously calm.")
        }
    }
}

@MainActor
enum Copy {
    struct Variant: Codable { let t: String; let f: Bool }

    static var humour: Humour = .little
    static var dailyVariety = true

    private static let deck: [String: [Variant]] = {
        guard let url = Bundle.main.url(forResource: "Copy", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: [Variant]].self, from: data) else { return [:] }
        return decoded
    }()

    static func variants(_ slot: CopySlot) -> [Variant] {
        deck[slot.rawValue] ?? [Variant(t: slot.spec.example, f: false)]
    }

    /// Today's line for a slot, with placeholders filled. Stable all day, different tomorrow.
    static func line(_ slot: CopySlot, _ values: [String: String] = [:], on date: Date = .now) -> String {
        let all = variants(slot)
        var pool = all
        switch humour {
        case .straight: pool = all.filter { !$0.f }
        case .lots: let funny = all.filter(\.f); if funny.count >= 10 { pool = funny }
        case .little: break
        }
        if pool.isEmpty { pool = all }
        let index: Int
        if dailyVariety {
            let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
            let salt = slot.rawValue.unicodeScalars.reduce(0) { $0 &* 31 &+ Int($1.value) }
            index = abs(day &* 7919 &+ salt) % pool.count
        } else {
            index = 0
        }
        var text = pool[index].t
        for (key, value) in values { text = text.replacingOccurrences(of: "{\(key)}", with: value) }
        return text
    }
}
