---
type: research-survey
id: RSCH-0009
title: macOS Built-In Inertial Sensor Readiness
domain: research
status: completed
created_at: "2026-08-10 21:17:28 JST +0900"
updated_at: "2026-08-10 21:17:28 JST +0900"
owner:
question: Can this Mac's built-in accelerometer and gyroscope safely drive Desktop Physics gravity through a public, non-privileged, stable macOS API?
source:
  type: conversation
  link:
  notes:
external_sources:
  - https://developer.apple.com/documentation/coremotion/cmheadphonemotionmanager
  - https://developer.apple.com/documentation/iokit/iohidmanager_h
  - https://developer.apple.com/documentation/iokit/1588670-iohiddeviceopen
  - https://usb.org/document-library/hid-usage-tables-17
  - https://github.com/taigrr/spank
  - https://github.com/taigrr/apple-silicon-accelerometer
  - https://www.bosch-sensortec.com/en/products/downloads
repo_findings:
  - This MacBook Pro Mac14,9 exposes Bosch BMI286 accelerometer and gyroscope endpoints through AppleSPUHIDDevice, but they are motion-restricted services on a vendor-defined HID usage page.
  - The installed macOS 26.5 SDK marks CMMotionManager unavailable on macOS; the public macOS CMHeadphoneMotionManager reports compatible headphone motion, not chassis motion.
  - The installed spank binary is ad-hoc signed, requires root, and depends on reverse-engineered SPU reports and undocumented properties; no persistent spank service is installed.
agent_notes:
  - Defer built-in chassis tilt. Do not add a root helper, LaunchDaemon, private HID provider, or a UI toggle that suggests live supported hardware.
  - Reopen only if Apple publishes a supported chassis-motion API or the owner explicitly scopes a private local-only experiment after reviewing its security and persistence costs.
related_ideas: []
related_evaluations: []
related_adrs: []
related_specs: [SPEC-0002]
related_plans: [PLAN-0003]
related_sessions:
  - 2026-08-10-reusable-desktop-world-and-controls
linked_paths:
  - Examples/DesktopPhysicsDemo
repo_state:
  based_on_commit: 102cac2110afa282633706e80a33c3a60265cc25
  last_reviewed_commit: 102cac2110afa282633706e80a33c3a60265cc25
---

# RSCH-0009 - macOS Built-In Inertial Sensor Readiness

## Question

Can this Mac's built-in accelerometer and gyroscope safely drive Desktop
Physics gravity through a public, non-privileged, stable macOS API?

## Verdict

No. The exact Mac has a physical six-axis inertial measurement unit (IMU)—an
accelerometer plus gyroscope—but macOS does not publish a supported chassis-
motion API for it. The visible local route is a motion-restricted,
vendor-defined Apple Sensor Processing Unit (SPU) Human Interface Device (HID)
contract that prior art opens as root with undocumented properties and report
layouts.

Desktop Physics therefore does not add **Tilt controls gravity**, a sensor
adapter, a helper, a daemon, or any permission request. Enumeration proves
hardware presence only; it does not prove live samples, axes, scale, latency,
power, or gameplay feel.

## Exact Mac Evidence

Read-only inspection on 2026-08-10 found:

- MacBook Pro `Mac14,9`, model `MPHE3X/A`;
- Apple M2 Pro, 10 cores, 16 GB;
- macOS 26.5.2 build `25F84`, arm64;
- `AppleSPUHIDDevice` accelerometer endpoint: Apple vendor/product
  `0x05ac/0x8104`, usage page `0xFF00`, usage `3`;
- `AppleSPUHIDDevice` gyroscope endpoint: the same vendor/product and usage
  page, usage `9`;
- both `AppleSPUHIDDriver` children report Bosch `BMI286`, calibration state
  `2`, rates `50 100 200 400 800`, and `motionRestrictedService = Yes`.

The commands were read-only:

```bash
sw_vers
system_profiler SPHardwareDataType
sysctl -n hw.model
hidutil list --matching '{"VendorID":1452,"ProductID":33028}'
ioreg -r -l -c AppleSPUHIDDevice -w0
```

The [USB Implementers Forum HID Usage Tables](https://usb.org/document-library/hid-usage-tables-17)
reserve `0xFF00` through `0xFFFF` for vendor-defined use. Usage `3` and usage
`9` are therefore not portable sensor contracts.

No live report was opened or requested. Axis signs, units, achieved sample
rate, timestamp behavior, latency, calibration accuracy, power, and thermal
effects remain unknown.

## Public API Boundary

The installed macOS 26.5 Software Development Kit (SDK) declares:

```objc
COREMOTION_EXPORT API_AVAILABLE(ios(4.0)) API_UNAVAILABLE(macos)
@interface CMMotionManager : NSObject
```

`CMMotionManager`, the normal public Core Motion API for onboard
accelerometer, gyroscope, and device motion, is explicitly unavailable on
macOS. Apple publishes
[`CMHeadphoneMotionManager`](https://developer.apple.com/documentation/coremotion/cmheadphonemotionmanager)
on macOS, but it reports motion from compatible headphones rather than the
MacBook chassis.

[`IOHIDManager`](https://developer.apple.com/documentation/iokit/iohidmanager_h)
and [`IOHIDDeviceOpen`](https://developer.apple.com/documentation/iokit/1588670-iohiddeviceopen)
are public IOKit entry points. Their existence does not make Apple's private
SPU usage numbers, report layout, scale, power controls, or access policy a
supported contract.

## Prior Art: Bosch BMI286 And `spank`

The machine already has `/Users/macintoso/go/bin/spank` version 1.2.0. It is
ad-hoc/linker signed with no Team Identifier, is not running, and has no
registered `com.taigrr.spank` system service.

The source for [`taigrr/spank`](https://github.com/taigrr/spank) and its
[`apple-silicon-accelerometer`](https://github.com/taigrr/apple-silicon-accelerometer)
predecessor shows why this is not a product integration path:

- it exits unless the effective user ID is root;
- it opens `AppleSPUHIDDevice` through IOKit;
- it matches vendor usages `0xFF00/3` and `0xFF00/9`;
- it sets undocumented reporting, power, and interval properties;
- it assumes 22-byte reports containing three little-endian 32-bit integers
  from byte offset 6;
- it assumes Q16 scaling by `65,536` for acceleration or angular rate;
- it decimates an asserted roughly 800 Hz native stream to roughly 100 Hz and
  polls at 4 or 10 ms;
- its persistence proposal is a root LaunchDaemon.

These are reverse-engineered conventions, not Apple guarantees. Bosch's
[official download catalog](https://www.bosch-sensortec.com/en/products/downloads)
does not currently expose a public BMI286 datasheet, so no authoritative axis,
range, calibration, or output-data contract was found.

## Sampling, Calibration, Privacy, And Distribution

The driver advertises 50–800 Hz. A gravity-control experiment should need only
about 50–100 Hz, but the rate list does not prove callback timing or data
quality. A 100 Hz callback feeding a 60 Hz simulation might add roughly
10–30 ms before smoothing; that is an engineering estimate, not a measurement.
Signposts from sensor timestamp to presented frame would still be required.

A responsible implementation would need stationary bias calibration, verified
axis order/sign, chassis-to-screen mapping, low-pass filtering, a dead zone,
magnitude and jerk clamps, sleep/wake recovery, stale-sample detection, and an
immediate fallback to ordinary downward gravity. Higher rates would add
callbacks and power cost without a demonstrated gameplay need.

The private SPU route has no documented Transparency, Consent, and Control
(TCC) motion prompt. Root approval is not a clear motion-data consent model.
Desktop Physics is unsandboxed today, but that does not remove the root access
restriction or make the protocol stable. A privileged helper or LaunchDaemon
would materially increase security, maintenance, signing, and distribution
scope and is explicitly outside this experiment.

## Safe Future Boundary

If Apple publishes a supported route, keep raw hardware out of the physics
domain:

```swift
protocol GravityInputProvider {
    var availability: GravityInputAvailability { get }
    func start(_ receive: @escaping (GravitySample) -> Void) throws
    func stop()
}

struct GravitySample {
    let timestamp: ContinuousClock.Instant
    let screenVector: SIMD2<Double>
    let confidence: Double
}
```

The adapter would emit normalized screen-space gravity, store no raw history,
run only behind an explicit normal-window toggle, expose availability,
calibration and sample age, consume only the newest timestamped sample per
physics frame, and fail closed to ordinary downward gravity.

## Recommendation

Defer chassis tilt and keep the current build sensor-free. Reopen this decision
only if Apple publishes a non-privileged chassis-motion API, or if the owner
explicitly approves a private local-only root experiment after reviewing the
security, persistence, calibration, and maintenance costs.

If real tilt control is desired sooner, the supported alternatives are an
iPhone companion using public Core Motion or a public game-controller input,
both placed behind the provider seam above. Headphone motion is public on macOS
but does not naturally represent the laptop's tilt.

The key retrieval rule is simple: physical BMI286 presence is confirmed;
supported non-privileged MacBook chassis motion is not.
