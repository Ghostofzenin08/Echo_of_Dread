extends Node

# NarrativeData: Lore logs and environmental clues for Echo of Dread
# Chronicles Dr. Aris Thorne's struggle, Project Chronos, and the emergence of Proxy-Zero.

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
	},
	"log_05": {
		"title": "LOG 05: SECURITY OVERWRITE MANDATE",
		"author": "Director Cole, Site Operations",
		"timestamp": "CYCLE 312 - [CLASSIFIED]",
		"content": "AUTOMATED MEMORANDUM: Dr. Thorne has refused extraction orders. He claims the fracture will expand if left uncontained. That is unacceptable.\n\nUnder Facility Protocol Delta-9, Aegis defense sentries have been set to lethal auto-patrol. Any mobile chronal anomaly detected outside quarantine will be neutralized on sight. The loop must not be allowed to bleed past Sector 2."
	},
	"log_06": {
		"title": "LOG 06: THE CHRONOS ACCORD",
		"author": "Dr. Aris Thorne, Personal Audio Diary",
		"timestamp": "CYCLE 405 - 08:14:11",
		"content": "I found Director Cole's encrypted transmissions in the relay room. Project Chronos was never an energy experiment. They wanted a weaponized temporal bubble—a subterranean killbox where soldiers could iterate tactical assaults infinitely until achieving 100% lethality.\n\nThey didn't expect the manifold to reject the human nervous system. We tore open the fabric of causality, and now the facility itself is conscious."
	},
	"log_07": {
		"title": "LOG 07: ELENA'S WARNING",
		"author": "Dr. Elena Vane, Quantum Engineering",
		"timestamp": "CYCLE 529 - CORRUPTED",
		"content": "Aris, listen to me if you are still sane enough to understand. Every loop you initiate is pulling kinetic energy from the surrounding continent. The seismic sensors in Sector 3 are off the charts.\n\nIf you don't dissolve the 50 containment nodes, the loop won't just reset us—it will collapse the entire timeline of the eastern hemisphere into a black hole. You have to destroy the anchor crystals."
	},
	"log_08": {
		"title": "LOG 08: THE DECOY PARADIGM",
		"author": "Dr. Aris Thorne, Tactical Notes",
		"timestamp": "CYCLE 681 - 08:14:24",
		"content": "The security drones are blind to time, but they lock onto chronal heat signatures. If an echo sprints across their field of view, the sentry will pursue the echo, ignoring everything else.\n\nUse your past selves as decoys. Draw the sentries into isolated dead-ends so you can access the bypass switches safely. In this labyrinth, sacrifice is just another calculation."
	},
	"log_09": {
		"title": "LOG 09: DISSOLUTION OF THE SELF",
		"author": "Dr. Aris Thorne, Neural Transcript",
		"timestamp": "CYCLE 890 - --:--:--",
		"content": "I... I cannot picture Elena's face anymore. My biological synapses are burning out under the weight of nine hundred iterations. My body died in Chamber 20 three weeks ago—or was it three seconds ago?\n\nWhat walks these chambers now is not a man. I transferred the last sliver of my consciousness into a tachyonic crystal chassis. I call it Proxy-Zero. If you are reading this... you are me. The last copy."
	},
	"log_10": {
		"title": "LOG 10: BEYOND THE EVENT HORIZON",
		"author": "Dr. Aris Thorne / Proxy-Zero",
		"timestamp": "CYCLE 1000 - CONVERGENCE",
		"content": "Fifty chambers aligned. Fifty chronal nodes stabilized. The manifold core is trembling at absolute resonance.\n\nWhen you step into the Singularity gate ahead, the loop will fracture permanently. The facility will vanish from the historical record, but linear reality will survive.\n\nThank you for enduring the dread. Break the cycle. Walk into the tomorrow we were denied."
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

func get_all_log_ids() -> Array[String]:
	var ids: Array[String] = []
	for k in LOGS.keys():
		ids.append(str(k))
	return ids

func get_log_count() -> int:
	return LOGS.size()
