extends Node

# NarrativeData: Lore logs and environmental clues for Echo Rooms

const LOGS: Dictionary = {
	"log_01": {
		"title": "LOG 01: TACHYON MANIFOLD BREACH",
		"author": "Dr. Aris Thorne, Lead Temporal Physicist",
		"timestamp": "CYCLE 001 - 08:14:02",
		"content": "Resonance containment has suffered catastrophic failure. The tachyon manifold fractured, collapsing Sub-Level 4 into a closed causal curve. Exactly 30 seconds before reality snaps back.\n\nPreliminary scans reveal something astonishing: actions taken during a loop leave physical quantum imprints. A temporal 'Echo'. If you stand on an activation pad, your echo will remain there when time resets.\n\nUse your past to forge a path forward."
	},
	"log_02": {
		"title": "LOG 02: CAUSAL COUPLING & SYNCHRONY",
		"author": "Dr. Aris Thorne, Lead Temporal Physicist",
		"timestamp": "CYCLE 043 - 08:14:19",
		"content": "The echoes possess genuine physical mass and interact with facility sensors. In Chamber 02, the central blast door requires dual authorization across separated observation wings.\n\nA single human cannot be in two places at once in linear time. But within this loop, you are your own teammate. Coordinate your timing. When the loop resets, let your previous self hold the switch while you advance."
	},
	"log_03": {
		"title": "LOG 03: CAPACITOR TIMING & DEVIATIONS",
		"author": "Dr. Aris Thorne, Lead Temporal Physicist",
		"timestamp": "CYCLE 118 - 08:14:27",
		"content": "Warning: The security protocols are decaying. The capacitor switches have limited operational windows—they deactivate after only a few seconds.\n\nTo cross the high-frequency laser barriers into the Vault, you must execute a strict chronological sequence. Your echo must trigger the primary capacitor at the precise second you arrive at the security threshold."
	},
	"log_04": {
		"title": "LOG 04: THE ESCAPE RESONANCE",
		"author": "Dr. Aris Thorne, Lead Temporal Physicist",
		"timestamp": "CYCLE 240 - 08:14:30",
		"content": "If you are reading this in the Core Chamber, you are minutes away from breaking the loop. The facility lock cannot be broken by running away; it must be satisfied.\n\nFour terminal nodes must be harmonized simultaneously across multiple temporal iterations. When all four nodes are held in alignment, the chronal boundary will rupture, restoring linear flow.\n\nDo not hesitate. Step into the rift when the blast doors open."
	}
}

func get_log(log_id: String) -> Dictionary:
	if LOGS.has(log_id):
		return LOGS[log_id]
	return {
		"title": "UNKNOWN DATA LOG",
		"author": "Corrupted Data Stream",
		"timestamp": "--:--:--",
		"content": "Data sectors corrupted by temporal decay..."
	}
