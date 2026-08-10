---
type: research-survey
id: RSCH-0003
title: Global Gameplay Key Input On macOS
domain: research
status: completed
created_at: "2026-08-10 00:37:45 JST +0900"
updated_at: "2026-08-10 00:42:00 JST +0900"
owner:
question: Which native macOS input mechanism can provide opt-in global movement controls while preserving system shortcuts and a reliable escape path?
source:
  type: conversation
  link:
  notes:
external_sources:
  - https://developer.apple.com/videos/play/wwdc2019/701/
  - https://developer.apple.com/documentation/coregraphics/cgeventtapoptions
  - https://developer.apple.com/documentation/appkit/nsevent/addlocalmonitorforevents(matching:handler:)
  - https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/MonitoringEvents/MonitoringEvents.html
  - https://developer.apple.com/forums/thread/707680
repo_findings:
  - A listen-only global monitor cannot suppress gameplay keys reaching the frontmost application.
  - An active Core Graphics event tap can discard exact events and requires Accessibility permission.
  - A stable signed app is required before requesting permission so trust is associated with a durable identity.
agent_notes:
  - Permission and event-tap creation are mechanism evidence, not proof that Command-Tab or recovery works physically.
related_ideas: []
related_evaluations: []
related_adrs: [ADR-0002]
related_specs: [SPEC-0002]
related_plans: [PLAN-0003]
related_sessions:
  - 2026-08-10-reusable-desktop-world-and-controls
linked_paths:
  - Examples/DesktopPhysicsDemo/Sources/DesktopPhysicsKit/DesktopGameInput.swift
  - Examples/DesktopPhysicsDemo/App/Sources/PhysicsDemoModel.swift
repo_state:
  based_on_commit: 102cac2110afa282633706e80a33c3a60265cc25
  last_reviewed_commit: 102cac2110afa282633706e80a33c3a60265cc25
---

# RSCH-0003 - Global Gameplay Key Input On macOS

## Question

Which native macOS input mechanism can provide opt-in controls while another
application remains frontmost, suppress only the player keys, preserve
Command-Tab, and always fail into a recoverable off state?

## Context

The overlay is deliberately non-activating and pointer-pass-through. Ordinary
AppKit key handling therefore cannot receive movement input while Codex,
Chrome, or another application remains active. The requested mode also should
not type A/D/W/Space into that frontmost application.

## External Sources

- Apple's [macOS privacy session from WWDC 2019](https://developer.apple.com/videos/play/wwdc2019/701/)
  distinguishes passive event listening from modification and says the latter
  requires Accessibility access.
- [`CGEventTapOptions`](https://developer.apple.com/documentation/coregraphics/cgeventtapoptions)
  defines listen-only and active Core Graphics event-tap behavior. An active
  callback may return no event to discard it.
- [`NSEvent.addLocalMonitor`](https://developer.apple.com/documentation/appkit/nsevent/addlocalmonitorforevents(matching:handler:))
  can alter events only inside the current app.
- Apple's [Cocoa event-monitoring guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/MonitoringEvents/MonitoringEvents.html)
  says a global `NSEvent` monitor observes other apps but cannot modify or
  suppress their events.
- Apple Developer Technical Support's [event tap permission explanation](https://developer.apple.com/forums/thread/707680)
  describes listen-event access and sandbox compatibility for passive taps;
  it does not make passive taps suitable for exclusive controls.

## Repo / Internal Findings

- The old `swift run` demo had no stable app bundle identity for Transparency,
  Consent, and Control permission.
- The new app uses bundle ID `com.owensantoso.DesktopPhysicsDemo`, automatic
  Apple Development signing with team `GU93K4U9DN`, hardened runtime, and no
  App Sandbox.
- `DesktopGameInputState` owns a lock-protected held-key set that the SpriteKit
  frame loop polls. Jump is queued only on an up-to-down transition.
- The active tap handles only A, D, W, Space, and arrow movement keys.
  Command, Control, Option, Shift, or Fn causes the event to pass unchanged;
  modifier transitions clear held state to prevent stuck movement.
- Tap timeout/user disable clears input state and stops suppression. The next
  explicit enable attempt tears down the stale tap before creating another.

## Agent Notes

Accessibility is a meaningful product/security boundary. The app must not
enable controls on launch or immediately after a permission grant. The user
returns to the visible window and explicitly enables them again.

## Options Compared

1. `NSResponder` or local `NSEvent` monitor: no permission, but works only when
   this app owns the key event.
2. Global `NSEvent` monitor: observes other apps, but cannot suppress delivery.
3. Listen-only Core Graphics event tap: global observation with Input
   Monitoring permission, but still cannot suppress delivery.
4. Active Core Graphics event tap: globally filters exact events and therefore
   needs Accessibility permission.
5. Carbon hot keys: useful for discrete modified shortcuts, not continuous
   unmodified movement controls.

## Findings

Only an active Core Graphics event tap satisfies the exact requested behavior.
It is appropriate only behind an explicit, visible, off-by-default mode with a
normal-window and Dock recovery path.

## Risks / Unknowns

- A passing pure-state test does not prove macOS admitted the event tap.
- A trusted app can still fail to create a tap or have it disabled by timeout.
- Programmatic modifier bypass does not prove Command-Tab reaches the Window
  Server; that requires a physical acceptance receipt.
- Re-signing with a different certificate or changing bundle identity can make
  an existing Accessibility grant stale.

## Recommendation

Use an active `.cgSessionEventTap` at the head of the session stream. Discard
only exact unmodified gameplay key-down/up events while mode is enabled. Pass
all other events, clear held state on modifiers, stop and invalidate the tap on
disable/quit, and fail off if macOS disables it.

## Follow-Ups

- Physically verify A/D, arrows, W/Up/Space, one jump per press, Command-Tab,
  a Command-modified gameplay letter, visible disable, and key return.
- Keep the exact signed app bundle stable between the permission grant and
  acceptance run.
