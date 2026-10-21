# Backplane draft 1 — schematic review

Reviewed 21 October 2026. **Verdict: NOT READY for fabrication.** The saved schematic has a disconnected Mainboard–Southbridge interface and assembly choices that prevent normal expansion-card discovery. Five confirmed findings are listed first; design risks and platform conflicts follow separately.

This is a schematic review, not a PCB sign-off. No schematic, PCB, project settings, or existing user edits were changed. The review used the saved working tree, including its pre-existing modifications.

## Scope and evidence

Konnect 0.13.0, build `6bbe3e4f890ba1d37c0e5d5f38ccd03d90958c9e`, was used for hierarchy inspection, netlist/PDF export, ERC, per-file connectivity checks, and the aggregate design audit. KiCad CLI was 10.0.6. The dynamically loaded tools were accessed through a separate local Konnect MCP stdio session because this client's tool list did not refresh after loading them.

Coverage: **8 reachable schematic files, 22 sheet instances, 529 exported components, 564 nets**. The files are Backplane, expansions, clock, module_slot, mgmt_ctrl, builtins, power, and usb_socket. Other schematic files in the directory, such as usb-hub-x4 and reset_gate, are not part of this root's reachable hierarchy and were not treated as fitted circuitry.

The platform baseline was fetched through the GitHub plugin and pinned to [`409964e053338dbef86818255a3566c76c760238`](https://github.com/Ashet-Technologies/platform/tree/409964e053338dbef86818255a3566c76c760238). A **conflict** means that the schematic differs from this baseline; it does not by itself establish a design mistake. The older local Specs documents were not substituted for this baseline.

Evidence is saved under [review-draft1](/home/felix/projects/ashet/home-computer/Hardware/Backplane/review-draft1): [rendered schematic](/home/felix/projects/ashet/home-computer/Hardware/Backplane/review-draft1/schematic.pdf), [full netlist](/home/felix/projects/ashet/home-computer/Hardware/Backplane/review-draft1/Backplane.net), [assembly-aware connectivity index](/home/felix/projects/ashet/home-computer/Hardware/Backplane/review-draft1/connectivity.json), [ERC report](/home/felix/projects/ashet/home-computer/Hardware/Backplane/review-draft1/erc.json), [Konnect audits](/home/felix/projects/ashet/home-computer/Hardware/Backplane/review-draft1/konnect-design-review.json), and [source hashes/tool versions](/home/felix/projects/ashet/home-computer/Hardware/Backplane/review-draft1/manifest.json). Sheet references below use hierarchical names because stored page numbers have gaps and the exported PDF consequently contains labels such as “29/22”.

## Confirmed findings

### F01 — P1: Mainboard GP0–GP7 do not reach the Southbridge

Location: root sheet, J1 B13/B14/B16/B17/B19/B20/B22/B23; `/Expansions/`, U2901 P56–P63.

The exported netlist gives all eight J1 GP contacts separate `unconnected-(J1-GP…-Pad…)` nets. The corresponding Propeller pins terminate on eight different, single-pin `/Expansions/FAB_{0}` through `FAB_{7}` nets. Graphical bus entries have not established electrical connections. ERC independently reports the eight unconnected contacts, 16 bus-member warnings, and eight isolated FAB labels.

| Mainboard contact | Intended Southbridge signal | P2 package pin |
| --- | --- | --- |
| J1 B13, GP0 | P56 / FAB0 | 89 |
| J1 B14, GP1 | P57 / FAB1 | 90 |
| J1 B16, GP2 | P58 / FAB2 | 92 |
| J1 B17, GP3 | P59 / FAB3 | 93 |
| J1 B19, GP4 | P60 / FAB4 | 95 |
| J1 B20, GP5 | P61 / FAB5 | 96 |
| J1 B22, GP6 | P62 / FAB6 | 98 |
| J1 B23, GP7 | P63 / FAB7 | 99 |

Consequence: the Mainboard cannot bootstrap the P2 or communicate over this interface. P62/P63, used for serial boot, are among the disconnected pins. This is a functional wiring defect independently of the platform revision.

Action: connect the eight pairs with correctly named individual nets or a declared bus with matching members. Re-export the complete netlist and verify that each row above is one electrical net. Use Konnect wiring/bus tools for the correction.

### F02 — P1: Every slot's I²C pull-ups are DNP

Location: module_slot; R409/R410, R709/R710, R1109/R1110, R1409/R1410, R1709/R1710, R2211/R2212, R2509/R2510.

All fourteen 10 kΩ resistors are marked **DNP** in the exported component properties. Their connection to switched MOD_+3V3 is appropriate, but they are absent in the default assembly. A nearby note explicitly says the card pull-ups will not be populated.

A TCA9548A channel is a pass switch, not a regenerated push-pull HIGH driver. In particular, its 1.8 V supply limits the HIGH level passed from the upstream side; upstream 3.3 V pull-ups cannot substitute for independent downstream pull-ups. An otherwise valid card with an open-drain EEPROM and no onboard pull-ups therefore has no guaranteed 3.3 V HIGH level. Card enumeration may fail or appear to work only with particular cards.

This is also a **conflict** with the platform requirement that the Backplane supplies pull-ups while the slot is powered. The platform now specifies 3.3 V I²C, so the note about leaving the voltage choice to a 5 V card is stale. See [Expansion Bus, I²C](https://github.com/Ashet-Technologies/platform/blob/409964e053338dbef86818255a3566c76c760238/Platform/Expansion%20Bus.md) and [TCA9548A, voltage translation/application guidance](/home/felix/projects/ashet/home-computer/Datasheets/tca9548a.pdf).

Action: populate downstream pull-ups to MOD_+3V3 and choose the values from bus capacitance and target speed. At 10 kΩ, `tr ≈ 0.8473 RC` permits approximately 118 pF for a 1 µs rise time at 100 kHz, but only 35 pF for a 300 ns rise time at 400 kHz. Include connector, card, switch, trace, and probe capacitance. Do not promise 400 kHz merely by fitting the existing 10 kΩ values.

### F03 — P1: The special slots advertise no supported features

Location: slot 0 J402 B7/R403; slot 1 J702 B6/R702; other feature straps throughout module_slot.

HSTX is physically routed from J1 to slot 0. The five audio signals are physically routed from J1 to slot 1. However, **R403 and R702 are both DNP**, as are every slot's AUDIO, VIDEO/HS, FUNC0, and FUNC1 ground straps. A card sampling its feature contacts sees the feature as unsupported. Mainboard J1 advertises both audio and high-speed support through its fitted straps, so the assembly is internally inconsistent.

Action: fit the slot 0 high-speed strap and slot 1 audio strap, keeping unsupported features open. Make the per-slot population explicit in the BOM/assembly data. Because module_slot is reused, consider exposing configuration pins to the parent sheet so the saved schematic itself expresses the different slot capabilities. This also conflicts with the [Computer's five generic + one HS + one audio allocation](https://github.com/Ashet-Technologies/platform/blob/409964e053338dbef86818255a3566c76c760238/Computer/README.md).

### F04 — P1 when populated: Qwiic header numbering is reversed

Location: `/Builtins/`, J1003–J1006.

The numbered electrical connections are `1=SCL, 2=SDA, 3=+3V3, 4=GND`. Qwiic's reference wiring is `1=GND, 2=+3V3, 3=SDA, 4=SCL`. This was checked visually against SparkFun's [reference schematic](https://docs.sparkfun.com/SparkFun_Qwiic_Human_Presence_Sensor-STHS34PF80/assets/board_files/schematic.pdf), not inferred from the drawing's top-to-bottom appearance. The assigned footprint is the standard JST SH BM04B vertical footprint.

The headers are currently DNP/excluded from the BOM, so this does not affect a board that leaves them uninstalled. Populating them as advertised would connect power to a peripheral signal and a peripheral power input to a bus signal; communication fails and electrical contention/back-powering is possible.

Action: correct the numbered nets before populating or exposing these connectors. Confirm the final footprint's circuit-1 orientation against the [JST SH drawing](/home/felix/projects/ashet/home-computer/Datasheets/JST-SH.pdf).

### F05 — P2: J1 B1 ground is unconnected

Location: root sheet, J1 B1, x=158.75 mm/y=32.385 mm.

ERC, the exported netlist, and Konnect's direct pin query agree that this contact has no electrical connection. Many other J1 grounds are connected, so this is not a complete loss of system ground, but it removes an intended connector return contact.

Action: connect B1 to GND and verify it appears on the same net as the other J1 grounds.

## Design risks and required decisions

### W01 — P2: Reset voltage margin and minimum pulse width are not established

Location: builtins, D1001, U1003, Q1004/Q1005, R1014/R1015, C1003/C1004.

D1001 still has the placeholder value **“Something Short-Circuit Safe”** and no selected part. Its orientation is correct: a LOW POWER_OK can pull RESET down, while RESET does not pull POWER_OK down. Nevertheless, the maximum diode forward drop plus the POWER_OK sink's worst-case VOL must be below every reset receiver's VIL. CD74HC221's HC input threshold, and the NL17SZS11 reset gates, both need to be included. A generic silicon diode is not a demonstrated logic-level guarantee.

The 70 ms annotation uses the typical `0.7 × 10 kΩ × 10 µF` formula quoted at 4.5 V, while this circuit runs at 3.3 V. The actual timing capacitors are Samsung CL10A106KP8NNNC, 10 µF ±10%, X5R. Capacitance tolerance, temperature, aging, operating bias, and the monostable's timing coefficient matter. The drawing has not established the platform's **50 ms minimum** over those conditions.

Action: select D1001 with a guaranteed low-current VF margin and evaluate reset timing at the actual voltage and component corners. Prefer a timing arrangement with a specified minimum if the RC margin is insufficient. Scope both short button resets and POWER_OK release during bring-up. The non-retriggerable HC221 feedback topology itself is coherent; I found no self-sustaining reset oscillation. Sources: [CD74HC221](/home/felix/projects/ashet/home-computer/Datasheets/cd74hc221.pdf), [timing capacitor](/home/felix/projects/ashet/home-computer/Datasheets/Samsung-CL10A106KP8NNNC.pdf).

### W02 — P2: Slot power-off depends on the 12 V rail remaining present

Location: repeated Q402/Q403/Q404 power stages and R411; Q401 pulls their shared gate low.

The three P-FET gates are pulled up to MAIN_+12V. If 12 V disappears while 5 V or 3.3 V remains, the lower-rail P-FETs acquire negative VGS and turn on even if POWER_ON is LOW. A brownout or independently sequenced supply can therefore defeat the intended default-off state. The normal gate voltages are within the GSF3407's ±20 V VGS rating; this is a sequencing issue, not a normal gate-overvoltage finding.

Additionally, GSF3407 guarantees RDS(on) at −4.5 V and −10 V, but the 3.3 V switch operates around −3.3 V. Its typical curve does not establish a worst-case conduction drop at that drive.

Action: use source-referenced gate pull-ups/drives or document and enforce the necessary supply sequencing and fault behavior. Select a FET characterized at the actual 3.3 V gate drive. If removal/hot-swap is supported, also assess inrush, reverse current, and discharge; a single P-FET has a body diode and is not reverse-current isolation. Source: [GSF3407](/home/felix/projects/ashet/home-computer/Datasheets/GSF3407.pdf).

### W03 — P2: PTC losses and temperature derating need a rail budget

Location: 21 slot SMD1206B050TF/15 devices and USB F2101/F2201; upstream F2901–F2903.

The slot/USB PTC is a **0.5 A hold / 1 A trip** part at 23 °C, not a precise 0.5 A current limiter. Its table specifies R1max=0.75 Ω after the stated recovery/reflow conditions. At 0.5 A that is 0.375 V of drop before the connector/FET/wiring losses. The equivalent nominal 3.3 V delivered level could be around 2.925 V under that resistance condition. Hold current decreases with temperature, and fault clearing is thermal rather than immediate.

The two USB sockets share the main 5 V distribution with expansion loads. Their 0.5 A hold fuses do not demonstrate connector-voltage compliance or isolate short-duration faults quickly. Nor does a 4 A hold main fuse establish the actual PSU, header-contact, or PCB capacity.

Action: budget worst-case supply voltage, resistance, temperature, normal full load, and fault energy for each rail. Check both simultaneous USB loads and seven fully loaded slots. Compare an appropriately sized electronic load switch/eFuse if low drop or prompt fault isolation is required. Source: [SMD1206B050TF/15, electrical table and derating](/home/felix/projects/ashet/home-computer/Datasheets/SMD1206B050TF_15.pdf).

### W04 — P2: Local bypassing is under-specified

Builtins has no dedicated supply bypass capacitor for U1003 (HC221) or U1004 (RTC). There are also no dedicated bypass capacitors for U3001/U3002 and the seven slot clock gates; the clock-generator block has only its shared 100 nF/10 nF pair for the oscillator and four gates. Each management block has a 100 nF capacitor for the MCU but also contains another gate.

There are many correctly connected 100 nF capacitors elsewhere, especially the P2 bank. This is not a claim that +3V3 has no capacitors. The concern is reserving local parts and short return loops for the actual IC locations, particularly with 48 MHz switching.

Action: assign local bypass capacitors to the logic/RTC and sufficient nearby bulk storage. Verify physical placement and return paths in a separate PCB review. The schematic cannot prove placement distance.

### W05 — P2: USB connector power/transient behavior needs completion

Location: both usb_socket instances.

D+/D− and USB pin numbering are correct. VBUS is permanently supplied through a PTC, with no capacitor on either post-fuse VBUS net and no backplane-visible overcurrent reporting/control. C2901 is on the other side of the power-distribution network and does not by itself establish connector-local transient performance. There is no connector-side ESD array in this hierarchy.

Action: evaluate the complete host implementation, including what protection/reporting the Mainboard provides, VBUS droop during attach, cable/load transients, and any required port power control. Add appropriate VBUS bypassing and user-accessible-port protection. The USB guidance calls for downstream bulk storage per hub; it does not justify blindly adding 120 µF separately to every port. See [TI USB power distribution guidance](https://www.ti.com/lit/an/slva049/slva049.pdf). Internal-only ports may warrant different ESD exposure assumptions, but the power behavior still needs checking.

### W06 — P2: The nominal “1.8 V” regulator is set to 1.85 V

Location: power, U2902, R2901=75 kΩ and R2902=36 kΩ.

The [AP3445L](/home/felix/projects/ashet/home-computer/Datasheets/AP3445L.pdf) equation gives `0.6 × (1 + 75/36) = 1.85 V`. Using the drawn ±1% resistor tolerances and the specified feedback-reference range 0.591–0.609 V gives approximately **1.798–1.903 V**, before bias-current effects, ripple, and transients. The selected distributor code for R2902 actually identifies a tighter-tolerance ERA resistor; the calculation deliberately uses the schematic's stated 1% allowance.

This is not an established P2 absolute-maximum violation: the available P2 documents specify a nominal 1.8 V supply without providing a sufficient complete electrical corner table for that conclusion. It is an unexplained setpoint/margin choice that should be closed explicitly.

The inductor is a real selected part, INPAQ WIP252012S-2R2MLDG: the fetched datasheet gives 3.2 A minimum saturation current and 2.2 A minimum heat-rating current under its test conditions. Size the converter/inductor/thermal path for the intended P2 workload and frequency, not the “Power_500mA” net-class name. Check effective MLCC capacitance and loop layout.

TP2906 is intentionally an **open solder jumper**, annotated “Solder when power OK”; it disconnects the downstream +1V8 rail until bridged. Keep this deliberate bring-up step in the assembly/test procedure and verify continuity after closing it. It is not an accidental open net.

### W07 — P2: The power connector's protection contract is incomplete

J2902 is a generic unkeyed 2×8 header, with no concrete current-rated part selected. The drawing explicitly chooses a pinout that shorts supplies to ground on 180° reversal. Those shorts occur at the connector side of F2901–F2903, so the board PTCs do not establish protection for the reversed cable/connector.

Action: specify the header, cable, mating orientation, per-contact current, and PSU short-circuit behavior, then verify the fault deliberately with a current-limited source. A keyed connector removes this dependence. This is a documented design tradeoff requiring an actual supply/cable contract, not an accidental cross-rail short reported by ERC.

## Platform conflicts — intent decisions, not automatic mistakes

| ID | Schematic | Pinned platform | Consequence / decision |
| --- | --- | --- | --- |
| C01 | U102 is TCA9548A, A0/A1/A2 all GND: address **0x70** | PCA9547 at **0x77** | Firmware must select the actual device/address. TCA9548A uses a channel bitmask and resets with all channels deselected; PCA9547 uses a different channel-control encoding/reset behavior. Merely changing the address constant is insufficient. Decide which interface is normative. |
| C02 | Expansion A8 MOD_SENSE is pulled up by R414 and equivalents to **switched MOD_+3V3** | Expansion A8 is **always** pulled to +3V3 through 10 kΩ | Role detection has no valid HIGH while slot power is off or still ramping. Define sampling timing or change the bias. Mainboard A8's 10 kΩ pull-down is present and agrees with the platform. |
| C03 | No configuration EEPROM exists anywhere in the exported BOM | Backplane configuration EEPROM at **0x57** on management subnet | Add one, explicitly emulate it with an always-available controller, or revise the system contract. An emulation is not evidenced by the schematic alone. |
| C04 | Per-rail PTC plus separately commanded discrete P-FET switching | Each slot rail protected by an **eFuse** | Passive thermal protection is a distinct implementation with different trip, inrush, reporting and fault behavior. It may be intentional, but does not implement that literal contract. |
| C05 | Physical slot address straps are reversed relative to usual A0-as-LSB interpretation | Management addresses **0x20 + slot** | With A0=bit0, hardware reads slot order **0,4,2,6,1,5,3**, while the Backplane reads 7. Firmware can reverse the bits or explicitly map these values. Confirm/document the mapping before treating ERC's deliberately open HIGH straps as mistakes. |

Sources: [Mainboard interface](https://github.com/Ashet-Technologies/platform/blob/409964e053338dbef86818255a3566c76c760238/Platform/Mainboard.md), [pinout](https://github.com/Ashet-Technologies/platform/blob/409964e053338dbef86818255a3566c76c760238/Platform/Pinout.md), [I²C topology decision](https://github.com/Ashet-Technologies/platform/blob/409964e053338dbef86818255a3566c76c760238/Platform/Decisions/0002-per-slot-i2c-pca9547.md), [management address allocation](https://github.com/Ashet-Technologies/platform/blob/409964e053338dbef86818255a3566c76c760238/Platform/System%20Management%20I2C.md), [Expansion Bus power contract](https://github.com/Ashet-Technologies/platform/blob/409964e053338dbef86818255a3566c76c760238/Platform/Expansion%20Bus.md). F02 and F03 also have platform conflicts, with independently observable assembly consequences described above.

## Firmware and provisioning requirements

These are conditions for correct operation, not assertions that unseen firmware already violates them.

| Area | Required behavior |
| --- | --- |
| CH32 external reset | Program the option-byte `RST_MODE[4:3]` to a setting that enables PD7 reset. The reference manual's default `11` leaves PD7 as GPIO, so the external reset-gate circuit alone does not guarantee reset on a fresh MCU. Include this in programming and test. |
| TCA reset voltage | U2004 PD3 directly connects to U102 RESET, pulled up by R1114 to +1V8. Configure that GPIO as **open-drain**, not 3.3 V push-pull. TCA9548A's recommended RESET HIGH range ends at VCC+0.5 V, approximately 2.35 V at the nominal regulator output. Its overall 7 V absolute input limit does not establish valid operation at a 3.3 V push-pull HIGH. |
| Management bus recovery | TCA9548A resets with every downstream channel off. Select channel 7 before contacting the RTC/management MCUs, and reselect it after resetting the switch. Recovery logic must not assume the controller behind the switch remains reachable through the reset. |
| Clock enable polarity | `~MOD_CLK_EN` is electrically **active HIGH**: an AND gate passes the clock when the MCU output is HIGH and mutes it to GND when LOW. Rename/document this to avoid an inverted firmware implementation. The pulldown correctly defaults the clock off. |
| Clock switching | Enable the clock while the card is held in reset, wait for stability, then release reset. An asynchronous enable change on a combinational AND gate can create a partial clock pulse; do not assume glitchless runtime switching. |
| Slot activation | Assert card reset before turning on POWER_ON; wait for rail settling, discover the EEPROM, configure interfaces, and maintain the minimum reset duration. P2 GP and Mainboard audio/HSTX signals must remain high-impedance until the card is powered/configured. Hardware power switching alone does not prevent signal back-powering. |
| Address straps | Enable internal pull-ups on PC0/PC3/PC4 and sample them as inputs. Do not briefly configure grounded address pins as push-pull HIGH outputs. Implement the agreed C05 bit interpretation. |
| RTC | Y1001's selected code is a **12.5 pF** crystal. Configure PCF8523 CAP_SEL accordingly; its default selection is 7 pF. Also configure Control_3 PM bits to enable battery switch-over: the reset state `111` disables it. Merely fitting BT1001 does not establish backup operation. |

Sources: [CH32V003 reference manual, option bytes](/home/felix/projects/ashet/home-computer/Datasheets/CH32V003-ReferenceManual.pdf), [TCA9548A §§5.3 and device operation](/home/felix/projects/ashet/home-computer/Datasheets/tca9548a.pdf), [PCF8523 Control_1/Control_3 and power management](/home/felix/projects/ashet/home-computer/Datasheets/PCF8523.pdf).

## Checks that passed, and false positives not promoted

- The seven GP groups map consecutively to P2 P0–P55 as intended. The disconnected **upstream** P56–P63 connection is F01; the slot-side groups are intact.
- HSTX reaches only slot 0; audio reaches only slot 1. Their physical mapping matches the intended special-slot allocation, apart from F03's feature advertisement.
- The oscillator is 48 MHz and the Mainboard, P2 and slot clock paths have three gate stages. Each branch has three intended consumers. This agrees with the current 48 MHz platform requirement.
- R202 is DNP, so the oscillator enable is not a fitted 10 kΩ/10 kΩ divider. R201 pulls it HIGH. R201 is, however, excluded from the BOM despite being fitted; include it in an explicit assembly procedure or correct that BOM exclusion.
- Card reset is an open-drain S3134K stage with a 20 V VDS rating, compatible in principle with card-provided pull-ups up to 12 V. No Backplane pull-up is fitted on those reset nets.
- The three measurement dividers produce approximately 2.512 V, 2.500 V and 2.517 V at nominal rails. CH32V003's ADC permits VSS–VDD input; these values are valid with a 3.3 V supply. A supposed 2.4 V ADC limit is not supported by the provided datasheet. Their 100 nF filters are present.
- All P2 VDD and I/O power pins appear on the intended rails with 16 bypass capacitors per bank; TEST and exposed ground are grounded. The local converter EN is tied to +5V, not to its own POWER_OK output: no enable/power-good deadlock was found.
- RTC battery polarity and crystal pin connections are coherent. Its open-drain INT/CLKOUT testpoint needs a pull-up in the measurement setup if clock output is used for trimming.
- Konnect hierarchical pin validation reported zero mismatches. Named-net short checks found none in any of the eight unique files. Three orphan-looking wire ends on power are deliberate net-class marker stubs, not broken rails.

## ERC interpretation and review limits

KiCad reported **27 errors and 727 warnings**, total 754. The warning categories are 638 off-grid endpoints, 46 library-symbol mismatches, 16 bus-member warnings, 14 isolated pin/label warnings, 12 pin-type warnings, and one missing-library warning. The 27 errors comprise 18 unconnected pins/sheet pins, four undriven signal inputs, four undriven power inputs, and one output/output conflict.

The raw count is not the number of independent hardware defects:

- The eight J1 GP opens and J1 B1 are real, as described above.
- Nine open MOD_A sheet pins are intentionally HIGH through MCU internal pull-ups. They need an ERC explanation/waiver, not automatic wiring to a rail. The resulting bit order still needs C05's decision.
- The J1/J702 audio pin-type conflict and four undriven audio-clock/data-input reports arise from using connector symbols with fixed card-facing electrical directions at both ends. The actual default data paths are connected. Give J1 a Mainboard-role symbol or suitable passive/bidirectional contact types so ERC expresses the real driver roles.
- VBAT and the two USB VBUS power-driver reports need correct power-source modeling and targeted flags after the physical paths are checked. Passive fuses and intentional net ties are not evidence of missing supply copper.
- Three measurement testpoints TP1005/TP1006/TP1007 on builtins are genuinely isolated from the similarly named nets inside the child management sheet: local labels do not cross that hierarchy boundary. The usable ADC testpoints are in the management child. Connect these parent testpoints through explicit hierarchical pins or remove/relabel them. This is a debug-access defect, not a failed ADC circuit.
- BRD_IN0/BRD_IN1 are otherwise unused inputs and require a defined firmware bias. BRD_RESET's standalone default resistor is not connected to an actual reset input and does not implement reset behavior.

Resolve or document the remaining ERC/library warnings so genuine errors remain visible. In particular, the environment lacks the `MCU_WCH_CH32V0` library and reports embedded-versus-installed symbol differences. The embedded symbols were nevertheless resolved for export. Do not blindly update symbols without reviewing pin mappings.

Konnect's aggregate audit completed 32/32 checks, with no failures or unresolved symbol placements, and returned NOT READY. Its 15 error/27 warning heuristic totals include per-sheet capacitor/power-source assumptions and missing formal MPN properties even where Value/distributor fields identify parts. Those were not copied as 42 independent faults. Direct netlist/ERC and datasheet evidence determined the findings above.

No PCB DRC, routing, impedance, return-path, trace-current, copper-temperature, connector-mechanical, or physical bypass-placement verification was performed. The 300 MHz HSTX/GP capability and clock skew cannot be certified from this schematic. Likewise, actual reset duration, inrush, P2 load current, thermal behavior and EMI require bench/layout verification. The platform itself leaves rail tolerances, hot-swap details and several timing contracts open; see [Open Topics](https://github.com/Ashet-Technologies/platform/blob/409964e053338dbef86818255a3566c76c760238/Open%20Topics.md).

## Recommended next revision and bring-up order

1. Repair F01/F05, populate slot pull-ups, and encode the two special-slot straps. Correct Qwiic numbering before enabling those optional headers.
2. Resolve C01–C05 explicitly between hardware and platform/firmware. Select D1001 and the actual power connector; close reset timing and rail-drop budgets.
3. Add/assign bypassing and USB VBUS support; record CH32 option bytes, open-drain mux-reset behavior, address mapping, and RTC initialization in provisioning requirements.
4. Re-export through Konnect, check every GP connection against F01's table, and clear/justify ERC findings. Confirm the final DNP/BOM state by reference, not just by schematic appearance.
5. On a current-limited supply, initially leave TP2906 open, measure the buck output/ripple, then bridge it and verify downstream +1V8/POWER_OK. Load and test the management MCUs, select mux channel 7, check RTC backup, then prove Mainboard-to-P2 serial bootstrap.
6. Bring up one slot at a time: prove reset-before-power sequencing, rail voltage at 500 mA, I²C rise time/discovery, clock enable, then GP/audio/HSTX. Repeat with worst-case simultaneous loads and the agreed supply-fault scenarios.

Missing selected-part/family datasheets retrieved during the review are listed in [the datasheet provenance file](/home/felix/projects/ashet/home-computer/Datasheets/Backplane-review-sources.md). Placeholder parts such as D1001, GREEN LEDs, Button 12mm and the generic power header still need exact MPN selection before a corresponding exact datasheet can be obtained. No Zig command was needed or run.
