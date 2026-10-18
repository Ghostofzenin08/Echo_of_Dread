class_name ChamberDatabase
extends RefCounted

# ChamberDatabase: Central registry of all 50 puzzle chambers across 5 thematic Sectors.
# Defines layout geometries, wall colliders, triggers, doors, lasers, drones, and story terminals.

const SECTORS: Dictionary = {
	1: {"name": "SECTOR 1: ALPHA WING", "subtitle": "Temporal Resonance", "range": [1, 10]},
	2: {"name": "SECTOR 2: BETA WING", "subtitle": "High-Voltage Relays", "range": [11, 20]},
	3: {"name": "SECTOR 3: GAMMA WING", "subtitle": "Optical Manifolds", "range": [21, 30]},
	4: {"name": "SECTOR 4: DELTA WING", "subtitle": "Blackout Protocol", "range": [31, 40]},
	5: {"name": "SECTOR 5: OMEGA WING", "subtitle": "The Singularity Breach", "range": [41, 50]}
}

static func get_sector_id(chamber_id: int) -> int:
	return clampi(((chamber_id - 1) / 10) + 1, 1, 5)

static func get_sector_name(sector_id: int) -> String:
	if SECTORS.has(sector_id):
		return SECTORS[sector_id]["name"]
	return "UNKNOWN SECTOR"

static func get_sector_subtitle(sector_id: int) -> String:
	if SECTORS.has(sector_id):
		return SECTORS[sector_id]["subtitle"]
	return ""

static func get_sector_chambers(sector_id: int) -> Array[int]:
	var result: Array[int] = []
	var start_idx := (sector_id - 1) * 10 + 1
	for i in range(start_idx, start_idx + 10):
		if i <= 50:
			result.append(i)
	return result

static func get_chamber_count() -> int:
	return 50

static func get_par_loops(chamber_id: int) -> int:
	var data := get_chamber(chamber_id)
	return data.get("par_loops", 2)

static func get_chamber(chamber_id: int) -> Dictionary:
	var c_id := clampi(chamber_id, 1, 50)
	var sector := get_sector_id(c_id)
	
	# Common room baseline
	var base := {
		"id": c_id,
		"sector": sector,
		"room_size": Vector2(1280, 720),
		"spawn_pos": Vector2(160, 360),
		"exit_pos": Vector2(1120, 360),
		"interior_walls": [] as Array[Rect2],
		"plates": [],
		"switches": [],
		"timed_buttons": [],
		"doors": [],
		"lasers": [],
		"drones": [],
		"terminals": [],
		"wires": [],
		"par_loops": 2,
		"title": "CHAMBER %02d" % c_id
	}
	
	match c_id:
		# =========================================================================
		# SECTOR 1: ALPHA WING (Chambers 01 - 10)
		# =========================================================================
		1:
			base["title"] = "CHAMBER 01: TEMPORAL RESONANCE"
			base["par_loops"] = 1
			base["interior_walls"] = [Rect2(624, 32, 32, 296), Rect2(624, 392, 32, 296)]
			base["plates"] = [{"id": "plate_1", "pos": Vector2(240, 520), "target": "door_1"}]
			base["doors"] = [{"id": "door_1", "pos": Vector2(640, 360), "rot": 1.5708, "logic": "AND", "req_count": 1}]
			base["terminals"] = [{"pos": Vector2(240, 200), "log_id": "log_01"}]
			base["wires"] = [{"from": Vector2(240, 520), "to": Vector2(640, 360), "trigger_id": "plate_1"}]
		2:
			base["title"] = "CHAMBER 02: SYNCHRONIZED ISOLATION"
			base["par_loops"] = 2
			base["interior_walls"] = [
				Rect2(400, 32, 32, 480), Rect2(400, 576, 32, 112),
				Rect2(800, 32, 32, 200), Rect2(800, 320, 32, 368)
			]
			base["plates"] = [
				{"id": "plate_a", "pos": Vector2(250, 240), "target": "door_main"},
				{"id": "plate_b", "pos": Vector2(600, 480), "target": "door_main"}
			]
			base["switches"] = [{"id": "switch_bypass", "pos": Vector2(600, 180), "target": "door_sub"}]
			base["doors"] = [
				{"id": "door_sub", "pos": Vector2(400, 530), "rot": 1.5708, "logic": "AND", "req_count": 1},
				{"id": "door_main", "pos": Vector2(800, 260), "rot": 1.5708, "logic": "AND", "req_count": 2}
			]
			base["drones"] = [{"pos": Vector2(460, 620), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(260, 0)]), "patrol_speed": 75.0}]
			base["terminals"] = [{"pos": Vector2(200, 160), "log_id": "log_02"}]
		3:
			base["title"] = "CHAMBER 03: THE VAULT & CAPACITORS"
			base["par_loops"] = 2
			base["interior_walls"] = [
				Rect2(360, 32, 32, 280), Rect2(360, 400, 32, 288),
				Rect2(880, 32, 32, 280), Rect2(880, 400, 32, 288)
			]
			base["timed_buttons"] = [
				{"id": "btn_cap_1", "pos": Vector2(200, 200), "duration": 7.0, "target": "laser_1"},
				{"id": "btn_cap_2", "pos": Vector2(200, 520), "duration": 7.0, "target": "door_exit"}
			]
			base["doors"] = [{"id": "door_exit", "pos": Vector2(880, 360), "rot": 1.5708, "logic": "AND", "req_count": 1}]
			base["lasers"] = [{"id": "laser_1", "pos": Vector2(360, 360), "length": 96.0, "orientation": "vertical", "target": "btn_cap_1"}]
			base["drones"] = [{"pos": Vector2(620, 200), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, 320)]), "patrol_speed": 85.0}]
			base["terminals"] = [{"pos": Vector2(620, 150), "log_id": "log_03"}]
		4:
			base["title"] = "CHAMBER 04: THE RESONANCE CORE"
			base["par_loops"] = 3
			base["interior_walls"] = [
				Rect2(320, 32, 32, 260), Rect2(320, 420, 32, 268),
				Rect2(920, 32, 32, 260), Rect2(920, 420, 32, 268),
				Rect2(480, 200, 320, 32), Rect2(480, 480, 320, 32)
			]
			base["plates"] = [
				{"id": "pad_nw", "pos": Vector2(200, 180), "target": "core_door"},
				{"id": "pad_sw", "pos": Vector2(200, 540), "target": "core_door"},
				{"id": "pad_ne", "pos": Vector2(1040, 180), "target": "core_door"},
				{"id": "pad_se", "pos": Vector2(1040, 540), "target": "core_door"}
			]
			base["doors"] = [{"id": "core_door", "pos": Vector2(640, 360), "rot": 0.0, "logic": "AND", "req_count": 4}]
			base["drones"] = [
				{"pos": Vector2(400, 140), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(480, 0)]), "patrol_speed": 90.0},
				{"pos": Vector2(880, 580), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(-480, 0)]), "patrol_speed": 90.0}
			]
			base["terminals"] = [{"pos": Vector2(640, 260), "log_id": "log_04"}]
		5:
			base["title"] = "CHAMBER 05: SPLIT FREQUENCY"
			base["par_loops"] = 2
			base["interior_walls"] = [
				Rect2(280, 32, 32, 656),
				Rect2(280, 344, 720, 32),
				Rect2(1000, 32, 32, 320), Rect2(1000, 400, 32, 288)
			]
			base["plates"] = [
				{"id": "plate_north", "pos": Vector2(640, 180), "target": "door_exit"},
				{"id": "plate_south", "pos": Vector2(640, 520), "target": "door_exit"}
			]
			base["doors"] = [{"id": "door_exit", "pos": Vector2(1000, 360), "rot": 1.5708, "logic": "AND", "req_count": 2}]
			base["drones"] = [{"pos": Vector2(450, 180), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(380, 0)]), "patrol_speed": 80.0}]
		6:
			base["title"] = "CHAMBER 06: THE SENTRY GAUNTLET"
			base["par_loops"] = 2
			base["interior_walls"] = [
				Rect2(360, 32, 32, 450),
				Rect2(720, 240, 32, 448)
			]
			base["plates"] = [{"id": "plate_mid", "pos": Vector2(540, 540), "target": "door_exit"}]
			base["doors"] = [{"id": "door_exit", "pos": Vector2(1000, 360), "rot": 1.5708, "logic": "AND", "req_count": 1}]
			base["drones"] = [
				{"pos": Vector2(480, 150), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(140, 250)]), "patrol_speed": 90.0}
			]
		7:
			base["title"] = "CHAMBER 07: DUAL THRESHOLD"
			base["par_loops"] = 2
			base["interior_walls"] = [
				Rect2(500, 32, 32, 280), Rect2(500, 400, 32, 288)
			]
			base["timed_buttons"] = [{"id": "btn_timed", "pos": Vector2(250, 200), "duration": 6.0, "target": "door_main"}]
			base["plates"] = [{"id": "plate_stay", "pos": Vector2(250, 520), "target": "door_main"}]
			base["doors"] = [{"id": "door_main", "pos": Vector2(500, 360), "rot": 1.5708, "logic": "AND", "req_count": 2}]
		8:
			base["title"] = "CHAMBER 08: SECURITY OVERWRITE"
			base["par_loops"] = 3
			base["interior_walls"] = [
				Rect2(420, 32, 32, 320), Rect2(420, 420, 32, 268),
				Rect2(820, 32, 32, 300), Rect2(820, 420, 32, 268)
			]
			base["plates"] = [{"id": "pad_sec", "pos": Vector2(620, 220), "target": "door_exit"}]
			base["switches"] = [{"id": "sw_sec", "pos": Vector2(240, 540), "target": "door_exit"}]
			base["doors"] = [{"id": "door_exit", "pos": Vector2(820, 360), "rot": 1.5708, "logic": "AND", "req_count": 2}]
			base["drones"] = [
				{"pos": Vector2(540, 560), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(160, -280)]), "patrol_speed": 100.0}
			]
			base["terminals"] = [{"pos": Vector2(620, 540), "log_id": "log_05"}]
		9:
			base["title"] = "CHAMBER 09: CAUSAL CROSSROAD"
			base["par_loops"] = 3
			base["interior_walls"] = [
				Rect2(400, 180, 480, 32),
				Rect2(400, 500, 480, 32)
			]
			base["plates"] = [
				{"id": "p_left", "pos": Vector2(240, 360), "target": "door_end"},
				{"id": "p_top", "pos": Vector2(640, 100), "target": "door_end"},
				{"id": "p_bot", "pos": Vector2(640, 620), "target": "door_end"}
			]
			base["doors"] = [{"id": "door_end", "pos": Vector2(980, 360), "rot": 1.5708, "logic": "AND", "req_count": 3}]
			base["drones"] = [{"pos": Vector2(500, 360), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(280, 0)]), "patrol_speed": 85.0}]
		10:
			base["title"] = "CHAMBER 10: ALPHA APEX"
			base["par_loops"] = 3
			base["interior_walls"] = [
				Rect2(340, 32, 32, 280), Rect2(340, 400, 32, 288),
				Rect2(840, 32, 32, 280), Rect2(840, 400, 32, 288),
				Rect2(520, 240, 160, 240)
			]
			base["plates"] = [
				{"id": "p_apex1", "pos": Vector2(200, 200), "target": "door_1"},
				{"id": "p_apex2", "pos": Vector2(200, 520), "target": "door_2"}
			]
			base["timed_buttons"] = [{"id": "btn_apex", "pos": Vector2(740, 360), "duration": 5.0, "target": "door_2"}]
			base["doors"] = [
				{"id": "door_1", "pos": Vector2(340, 360), "rot": 1.5708, "logic": "AND", "req_count": 1},
				{"id": "door_2", "pos": Vector2(840, 360), "rot": 1.5708, "logic": "AND", "req_count": 2}
			]
			base["drones"] = [
				{"pos": Vector2(440, 120), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, 480)]), "patrol_speed": 95.0},
				{"pos": Vector2(760, 600), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, -480)]), "patrol_speed": 95.0}
			]

		# =========================================================================
		# SECTOR 2: BETA WING (Chambers 11 - 20)
		# =========================================================================
		11:
			base["title"] = "CHAMBER 11: LASER INGRESS"
			base["par_loops"] = 2
			base["interior_walls"] = [Rect2(580, 32, 32, 260), Rect2(580, 430, 32, 258)]
			base["timed_buttons"] = [{"id": "btn_laser_11", "pos": Vector2(280, 240), "duration": 6.0, "target": "laser_11"}]
			base["lasers"] = [{"id": "laser_11", "pos": Vector2(580, 360), "length": 140.0, "orientation": "vertical", "target": "btn_laser_11"}]
			base["plates"] = [{"id": "pad_exit_11", "pos": Vector2(280, 480), "target": "door_exit_11"}]
			base["doors"] = [{"id": "door_exit_11", "pos": Vector2(960, 360), "rot": 1.5708, "logic": "AND", "req_count": 1}]
		12:
			base["title"] = "CHAMBER 12: CHRONOS RELAY"
			base["par_loops"] = 3
			base["interior_walls"] = [
				Rect2(380, 32, 32, 400),
				Rect2(780, 280, 32, 408)
			]
			base["timed_buttons"] = [
				{"id": "btn_fast", "pos": Vector2(200, 540), "duration": 4.5, "target": "laser_12"}
			]
			base["lasers"] = [{"id": "laser_12", "pos": Vector2(780, 140), "length": 216.0, "orientation": "vertical", "target": "btn_fast"}]
			base["plates"] = [{"id": "pad_12", "pos": Vector2(560, 520), "target": "door_12"}]
			base["doors"] = [{"id": "door_12", "pos": Vector2(1040, 360), "rot": 1.5708, "logic": "AND", "req_count": 1}]
			base["drones"] = [{"pos": Vector2(580, 200), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, 260)]), "patrol_speed": 110.0}]
			base["terminals"] = [{"pos": Vector2(580, 120), "log_id": "log_06"}]
		13:
			base["title"] = "CHAMBER 13: STAGGERED GATE"
			base["par_loops"] = 3
			base["interior_walls"] = [
				Rect2(360, 32, 32, 280), Rect2(360, 400, 32, 288),
				Rect2(640, 160, 32, 400),
				Rect2(920, 32, 32, 280), Rect2(920, 400, 32, 288)
			]
			base["timed_buttons"] = [
				{"id": "btn_stagger_1", "pos": Vector2(200, 240), "duration": 6.0, "target": "laser_s1"},
				{"id": "btn_stagger_2", "pos": Vector2(500, 540), "duration": 5.0, "target": "laser_s2"}
			]
			base["lasers"] = [
				{"id": "laser_s1", "pos": Vector2(360, 360), "length": 96.0, "orientation": "vertical", "target": "btn_stagger_1"},
				{"id": "laser_s2", "pos": Vector2(920, 360), "length": 96.0, "orientation": "vertical", "target": "btn_stagger_2"}
			]
			base["plates"] = [{"id": "p_stagger", "pos": Vector2(500, 180), "target": "door_stagger"}]
			base["doors"] = [{"id": "door_stagger", "pos": Vector2(1040, 360), "rot": 1.5708, "logic": "AND", "req_count": 1}]
		14:
			base["title"] = "CHAMBER 14: ELENA'S CORRIDOR"
			base["par_loops"] = 3
			base["interior_walls"] = [
				Rect2(400, 32, 32, 340), Rect2(400, 430, 32, 258),
				Rect2(760, 32, 32, 260), Rect2(760, 350, 32, 338)
			]
			base["switches"] = [{"id": "sw_elena", "pos": Vector2(240, 200), "target": "door_elena"}]
			base["plates"] = [{"id": "pad_elena", "pos": Vector2(580, 540), "target": "door_elena"}]
			base["doors"] = [{"id": "door_elena", "pos": Vector2(760, 305), "rot": 1.5708, "logic": "AND", "req_count": 2}]
			base["drones"] = [{"pos": Vector2(580, 200), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, 220)]), "patrol_speed": 95.0}]
			base["terminals"] = [{"pos": Vector2(240, 520), "log_id": "log_07"}]
		15:
			base["title"] = "CHAMBER 15: PRESSURE SIPHON"
			base["par_loops"] = 3
			base["interior_walls"] = [Rect2(520, 32, 32, 656)]
			base["plates"] = [{"id": "p_siphon", "pos": Vector2(300, 240), "target": "laser_siphon"}]
			base["timed_buttons"] = [{"id": "btn_siphon", "pos": Vector2(300, 480), "duration": 5.0, "target": "door_siphon"}]
			base["lasers"] = [{"id": "laser_siphon", "pos": Vector2(520, 360), "length": 128.0, "orientation": "vertical", "target": "p_siphon"}]
			base["doors"] = [{"id": "door_siphon", "pos": Vector2(880, 360), "rot": 1.5708, "logic": "AND", "req_count": 1}]
		16:
			base["title"] = "CHAMBER 16: INTERCEPTOR ALLEY"
			base["par_loops"] = 3
			base["interior_walls"] = [
				Rect2(360, 180, 560, 32),
				Rect2(360, 500, 560, 32)
			]
			base["timed_buttons"] = [{"id": "btn_alley", "pos": Vector2(200, 360), "duration": 6.5, "target": "door_alley"}]
			base["doors"] = [{"id": "door_alley", "pos": Vector2(1000, 360), "rot": 1.5708, "logic": "AND", "req_count": 1}]
			base["drones"] = [
				{"pos": Vector2(440, 360), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(400, 0)]), "patrol_speed": 125.0, "chase_speed": 160.0}
			]
		17:
			base["title"] = "CHAMBER 17: TRIPLE PHASE"
			base["par_loops"] = 3
			base["interior_walls"] = [
				Rect2(420, 32, 32, 280), Rect2(420, 400, 32, 288),
				Rect2(800, 32, 32, 280), Rect2(800, 400, 32, 288)
			]
			base["timed_buttons"] = [
				{"id": "btn_phase_1", "pos": Vector2(240, 200), "duration": 7.0, "target": "laser_p1"},
				{"id": "btn_phase_2", "pos": Vector2(240, 520), "duration": 5.0, "target": "laser_p2"},
				{"id": "btn_phase_3", "pos": Vector2(620, 360), "duration": 3.5, "target": "door_p"}
			]
			base["lasers"] = [
				{"id": "laser_p1", "pos": Vector2(420, 360), "length": 96.0, "orientation": "vertical", "target": "btn_phase_1"},
				{"id": "laser_p2", "pos": Vector2(800, 360), "length": 96.0, "orientation": "vertical", "target": "btn_phase_2"}
			]
			base["doors"] = [{"id": "door_p", "pos": Vector2(1040, 360), "rot": 1.5708, "logic": "AND", "req_count": 1}]
		18:
			base["title"] = "CHAMBER 18: HIGH-VOLTAGE LABYRINTH"
			base["par_loops"] = 4
			base["interior_walls"] = [
				Rect2(320, 160, 32, 400), Rect2(620, 32, 32, 400), Rect2(920, 280, 32, 408)
			]
			base["plates"] = [
				{"id": "p_lab_1", "pos": Vector2(180, 520), "target": "door_lab"},
				{"id": "p_lab_2", "pos": Vector2(480, 120), "target": "door_lab"},
				{"id": "p_lab_3", "pos": Vector2(780, 560), "target": "door_lab"}
			]
			base["doors"] = [{"id": "door_lab", "pos": Vector2(1080, 360), "rot": 1.5708, "logic": "AND", "req_count": 3}]
			base["drones"] = [
				{"pos": Vector2(470, 360), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, 240)]), "patrol_speed": 95.0},
				{"pos": Vector2(770, 200), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, 260)]), "patrol_speed": 105.0}
			]
		19:
			base["title"] = "CHAMBER 19: THE CAPACITANCE LOOP"
			base["par_loops"] = 4
			base["interior_walls"] = [
				Rect2(360, 32, 32, 280), Rect2(360, 400, 32, 288),
				Rect2(740, 32, 32, 280), Rect2(740, 400, 32, 288)
			]
			base["timed_buttons"] = [
				{"id": "btn_c1", "pos": Vector2(200, 200), "duration": 4.5, "target": "las_c1"},
				{"id": "btn_c2", "pos": Vector2(550, 200), "duration": 4.5, "target": "las_c2"},
				{"id": "btn_c3", "pos": Vector2(550, 520), "duration": 4.5, "target": "door_c"}
			]
			base["lasers"] = [
				{"id": "las_c1", "pos": Vector2(360, 360), "length": 96.0, "orientation": "vertical", "target": "btn_c1"},
				{"id": "las_c2", "pos": Vector2(740, 360), "length": 96.0, "orientation": "vertical", "target": "btn_c2"}
			]
			base["doors"] = [{"id": "door_c", "pos": Vector2(1000, 360), "rot": 1.5708, "logic": "AND", "req_count": 1}]
		20:
			base["title"] = "CHAMBER 20: BETA APEX: THE TRANSFORMER"
			base["par_loops"] = 4
			base["interior_walls"] = [
				Rect2(360, 32, 32, 656),
				Rect2(800, 32, 32, 656)
			]
			base["timed_buttons"] = [
				{"id": "b_trans_1", "pos": Vector2(200, 180), "duration": 6.0, "target": "las_trans_1"},
				{"id": "b_trans_2", "pos": Vector2(580, 180), "duration": 5.0, "target": "las_trans_2"}
			]
			base["plates"] = [{"id": "p_trans_exit", "pos": Vector2(580, 540), "target": "door_trans"}]
			base["lasers"] = [
				{"id": "las_trans_1", "pos": Vector2(360, 360), "length": 140.0, "orientation": "vertical", "target": "b_trans_1"},
				{"id": "las_trans_2", "pos": Vector2(800, 360), "length": 140.0, "orientation": "vertical", "target": "b_trans_2"}
			]
			base["doors"] = [{"id": "door_trans", "pos": Vector2(1040, 360), "rot": 1.5708, "logic": "AND", "req_count": 1}]
			base["drones"] = [
				{"pos": Vector2(580, 360), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, 150), Vector2(0, -150)]), "patrol_speed": 110.0}
			]

		# =========================================================================
		# SECTOR 3: GAMMA WING (Chambers 21 - 30)
		# =========================================================================
		21:
			base["title"] = "CHAMBER 21: INVERSION FIELD"
			base["par_loops"] = 3
			base["interior_walls"] = [Rect2(500, 32, 32, 280), Rect2(500, 400, 32, 288)]
			base["switches"] = [
				{"id": "sw_inv_1", "pos": Vector2(260, 220), "target": "door_inv"},
				{"id": "sw_inv_2", "pos": Vector2(260, 500), "target": "door_inv"}
			]
			base["doors"] = [{"id": "door_inv", "pos": Vector2(500, 360), "rot": 1.5708, "logic": "AND", "req_count": 2}]
		22:
			base["title"] = "CHAMBER 22: CHRONAL BLEED"
			base["par_loops"] = 3
			base["interior_walls"] = [Rect2(440, 160, 400, 32), Rect2(440, 520, 400, 32)]
			base["plates"] = [
				{"id": "p_bleed_1", "pos": Vector2(220, 360), "target": "door_bleed"},
				{"id": "p_bleed_2", "pos": Vector2(640, 100), "target": "door_bleed"}
			]
			base["doors"] = [{"id": "door_bleed", "pos": Vector2(960, 360), "rot": 1.5708, "logic": "AND", "req_count": 2}]
			base["drones"] = [{"pos": Vector2(640, 360), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(200, 0)]), "patrol_speed": 90.0}]
			base["terminals"] = [{"pos": Vector2(640, 600), "log_id": "log_07"}]
		23:
			base["title"] = "CHAMBER 23: THE PRISM BARRIER"
			base["par_loops"] = 3
			base["interior_walls"] = [Rect2(360, 32, 32, 300), Rect2(360, 390, 32, 298), Rect2(820, 32, 32, 300), Rect2(820, 390, 32, 298)]
			base["plates"] = [
				{"id": "p_prism_1", "pos": Vector2(200, 200), "target": "las_prism_1"},
				{"id": "p_prism_2", "pos": Vector2(200, 520), "target": "las_prism_2"}
			]
			base["lasers"] = [
				{"id": "las_prism_1", "pos": Vector2(360, 345), "length": 90.0, "orientation": "vertical", "target": "p_prism_1"},
				{"id": "las_prism_2", "pos": Vector2(820, 345), "length": 90.0, "orientation": "vertical", "target": "p_prism_2"}
			]
			base["switches"] = [{"id": "sw_prism", "pos": Vector2(590, 360), "target": "door_prism"}]
			base["doors"] = [{"id": "door_prism", "pos": Vector2(1040, 360), "rot": 1.5708, "logic": "AND", "req_count": 1}]
		24:
			base["title"] = "CHAMBER 24: SENTRY INTERSECT"
			base["par_loops"] = 3
			base["interior_walls"] = [Rect2(640, 200, 32, 320)]
			base["plates"] = [{"id": "p_intersect", "pos": Vector2(260, 360), "target": "door_intersect"}]
			base["doors"] = [{"id": "door_intersect", "pos": Vector2(1040, 360), "rot": 1.5708, "logic": "AND", "req_count": 1}]
			base["drones"] = [
				{"pos": Vector2(500, 180), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(280, 0)]), "patrol_speed": 100.0},
				{"pos": Vector2(780, 540), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(-280, 0)]), "patrol_speed": 100.0}
			]
		25:
			base["title"] = "CHAMBER 25: CAUSAL BRIDGE"
			base["par_loops"] = 3
			base["interior_walls"] = [
				Rect2(360, 32, 32, 656), Rect2(880, 32, 32, 656)
			]
			base["plates"] = [
				{"id": "p_bridge_1", "pos": Vector2(200, 240), "target": "las_b1"},
				{"id": "p_bridge_2", "pos": Vector2(620, 240), "target": "las_b2"}
			]
			base["lasers"] = [
				{"id": "las_b1", "pos": Vector2(360, 360), "length": 160.0, "orientation": "vertical", "target": "p_bridge_1"},
				{"id": "las_b2", "pos": Vector2(880, 360), "length": 160.0, "orientation": "vertical", "target": "p_bridge_2"}
			]
			base["switches"] = [{"id": "sw_bridge", "pos": Vector2(620, 480), "target": "door_bridge"}]
			base["doors"] = [{"id": "door_bridge", "pos": Vector2(1060, 360), "rot": 1.5708, "logic": "AND", "req_count": 1}]
		26:
			base["title"] = "CHAMBER 26: STAGGERED MANIFOLD"
			base["par_loops"] = 4
			base["interior_walls"] = [Rect2(300, 160, 32, 400), Rect2(600, 32, 32, 400), Rect2(900, 280, 32, 408)]
			base["plates"] = [
				{"id": "p_m1", "pos": Vector2(180, 200), "target": "door_man"},
				{"id": "p_m2", "pos": Vector2(450, 540), "target": "door_man"},
				{"id": "p_m3", "pos": Vector2(750, 180), "target": "door_man"}
			]
			base["doors"] = [{"id": "door_man", "pos": Vector2(1060, 360), "rot": 1.5708, "logic": "AND", "req_count": 3}]
			base["drones"] = [{"pos": Vector2(450, 200), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, 260)]), "patrol_speed": 105.0}]
		27:
			base["title"] = "CHAMBER 27: THE DECOY CHAMBER"
			base["par_loops"] = 3
			base["interior_walls"] = [Rect2(540, 32, 32, 656)]
			base["timed_buttons"] = [{"id": "btn_decoy", "pos": Vector2(240, 540), "duration": 5.0, "target": "las_decoy"}]
			base["lasers"] = [{"id": "las_decoy", "pos": Vector2(540, 360), "length": 140.0, "orientation": "vertical", "target": "btn_decoy"}]
			base["doors"] = [{"id": "door_decoy", "pos": Vector2(980, 360), "rot": 1.5708, "logic": "AND", "req_count": 1}]
			base["plates"] = [{"id": "p_decoy_open", "pos": Vector2(740, 240), "target": "door_decoy"}]
			base["drones"] = [{"pos": Vector2(740, 500), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(160, 0)]), "patrol_speed": 120.0}]
		28:
			base["title"] = "CHAMBER 28: QUAD MATRIX"
			base["par_loops"] = 4
			base["interior_walls"] = [Rect2(624, 32, 32, 656), Rect2(32, 344, 1216, 32)]
			base["plates"] = [
				{"id": "qm_1", "pos": Vector2(250, 180), "target": "door_qm"},
				{"id": "qm_2", "pos": Vector2(950, 180), "target": "door_qm"},
				{"id": "qm_3", "pos": Vector2(250, 540), "target": "door_qm"}
			]
			base["doors"] = [{"id": "door_qm", "pos": Vector2(950, 540), "rot": 0.0, "logic": "AND", "req_count": 3}]
			base["drones"] = [
				{"pos": Vector2(400, 180), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, 120)]), "patrol_speed": 95.0},
				{"pos": Vector2(800, 540), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, -120)]), "patrol_speed": 95.0}
			]
		29:
			base["title"] = "CHAMBER 29: HARMONIC DIVERGENCE"
			base["par_loops"] = 4
			base["interior_walls"] = [Rect2(400, 32, 32, 300), Rect2(800, 388, 32, 300)]
			base["timed_buttons"] = [
				{"id": "b_div1", "pos": Vector2(220, 200), "duration": 4.5, "target": "door_div"},
				{"id": "b_div2", "pos": Vector2(600, 520), "duration": 4.5, "target": "door_div"}
			]
			base["doors"] = [{"id": "door_div", "pos": Vector2(1040, 360), "rot": 1.5708, "logic": "AND", "req_count": 2}]
			base["drones"] = [{"pos": Vector2(600, 200), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(180, 0)]), "patrol_speed": 110.0}]
		30:
			base["title"] = "CHAMBER 30: GAMMA APEX: REACTOR CORE"
			base["par_loops"] = 4
			base["interior_walls"] = [
				Rect2(360, 32, 32, 260), Rect2(360, 428, 32, 260),
				Rect2(900, 32, 32, 260), Rect2(900, 428, 32, 260),
				Rect2(520, 260, 240, 200)
			]
			base["plates"] = [
				{"id": "core_g1", "pos": Vector2(200, 200), "target": "las_cg1"},
				{"id": "core_g2", "pos": Vector2(200, 520), "target": "las_cg2"},
				{"id": "core_g3", "pos": Vector2(640, 160), "target": "door_cg"}
			]
			base["lasers"] = [
				{"id": "las_cg1", "pos": Vector2(360, 344), "length": 168.0, "orientation": "vertical", "target": "core_g1"},
				{"id": "las_cg2", "pos": Vector2(900, 344), "length": 168.0, "orientation": "vertical", "target": "core_g2"}
			]
			base["doors"] = [{"id": "door_cg", "pos": Vector2(1060, 360), "rot": 1.5708, "logic": "AND", "req_count": 1}]
			base["drones"] = [
				{"pos": Vector2(440, 160), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, 400)]), "patrol_speed": 105.0},
				{"pos": Vector2(820, 560), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, -400)]), "patrol_speed": 105.0}
			]

		# =========================================================================
		# SECTOR 4: DELTA WING (Chambers 31 - 40)
		# =========================================================================
		31:
			base["title"] = "CHAMBER 31: BLACKOUT PROTOCOL"
			base["par_loops"] = 3
			base["interior_walls"] = [Rect2(480, 32, 32, 450), Rect2(780, 238, 32, 450)]
			base["plates"] = [{"id": "p_bo1", "pos": Vector2(260, 360), "target": "door_bo"}]
			base["switches"] = [{"id": "sw_bo2", "pos": Vector2(630, 160), "target": "door_bo"}]
			base["doors"] = [{"id": "door_bo", "pos": Vector2(1020, 360), "rot": 1.5708, "logic": "AND", "req_count": 2}]
			base["drones"] = [
				{"pos": Vector2(630, 450), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, 180)]), "patrol_speed": 120.0}
			]
			base["terminals"] = [{"pos": Vector2(260, 180), "log_id": "log_08"}]
		32:
			base["title"] = "CHAMBER 32: THE DECOY PARADIGM"
			base["par_loops"] = 3
			base["interior_walls"] = [Rect2(400, 200, 480, 32), Rect2(400, 488, 480, 32)]
			base["timed_buttons"] = [{"id": "b_dp", "pos": Vector2(200, 360), "duration": 5.5, "target": "door_dp"}]
			base["doors"] = [{"id": "door_dp", "pos": Vector2(1040, 360), "rot": 1.5708, "logic": "AND", "req_count": 1}]
			base["drones"] = [
				{"pos": Vector2(640, 360), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(220, 0)]), "patrol_speed": 130.0, "chase_speed": 170.0}
			]
		33:
			base["title"] = "CHAMBER 33: THE GUILLOTINE"
			base["par_loops"] = 4
			base["interior_walls"] = [Rect2(360, 32, 32, 656), Rect2(720, 32, 32, 656)]
			base["timed_buttons"] = [
				{"id": "b_g1", "pos": Vector2(200, 200), "duration": 4.5, "target": "las_g1"},
				{"id": "b_g2", "pos": Vector2(540, 540), "duration": 4.0, "target": "las_g2"}
			]
			base["lasers"] = [
				{"id": "las_g1", "pos": Vector2(360, 360), "length": 140.0, "orientation": "vertical", "target": "b_g1"},
				{"id": "las_g2", "pos": Vector2(720, 360), "length": 140.0, "orientation": "vertical", "target": "b_g2"}
			]
			base["plates"] = [{"id": "p_gexit", "pos": Vector2(540, 200), "target": "door_gexit"}]
			base["doors"] = [{"id": "door_gexit", "pos": Vector2(980, 360), "rot": 1.5708, "logic": "AND", "req_count": 1}]
		34:
			base["title"] = "CHAMBER 34: BLIND SPOT"
			base["par_loops"] = 4
			base["interior_walls"] = [Rect2(500, 160, 32, 400), Rect2(820, 32, 32, 400)]
			base["plates"] = [
				{"id": "p_bs1", "pos": Vector2(250, 240), "target": "door_bs"},
				{"id": "p_bs2", "pos": Vector2(660, 500), "target": "door_bs"}
			]
			base["doors"] = [{"id": "door_bs", "pos": Vector2(1040, 360), "rot": 1.5708, "logic": "AND", "req_count": 2}]
			base["drones"] = [
				{"pos": Vector2(660, 200), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(120, 0)]), "patrol_speed": 115.0}
			]
		35:
			base["title"] = "CHAMBER 35: HIGH ALERT"
			base["par_loops"] = 4
			base["interior_walls"] = [Rect2(360, 32, 32, 320), Rect2(360, 420, 32, 268), Rect2(800, 32, 32, 320), Rect2(800, 420, 32, 268)]
			base["plates"] = [
				{"id": "p_ha1", "pos": Vector2(200, 540), "target": "door_ha"},
				{"id": "p_ha2", "pos": Vector2(580, 180), "target": "door_ha"}
			]
			base["doors"] = [{"id": "door_ha", "pos": Vector2(800, 370), "rot": 1.5708, "logic": "AND", "req_count": 2}]
			base["drones"] = [
				{"pos": Vector2(460, 540), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(240, 0)]), "patrol_speed": 110.0},
				{"pos": Vector2(700, 200), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, 240)]), "patrol_speed": 110.0}
			]
		36:
			base["title"] = "CHAMBER 36: PHANTOM GRID"
			base["par_loops"] = 4
			base["interior_walls"] = [Rect2(420, 32, 32, 656), Rect2(780, 32, 32, 656)]
			base["timed_buttons"] = [
				{"id": "b_pg1", "pos": Vector2(220, 200), "duration": 5.0, "target": "las_pg1"},
				{"id": "b_pg2", "pos": Vector2(600, 520), "duration": 5.0, "target": "las_pg2"}
			]
			base["lasers"] = [
				{"id": "las_pg1", "pos": Vector2(420, 360), "length": 140.0, "orientation": "vertical", "target": "b_pg1"},
				{"id": "las_pg2", "pos": Vector2(780, 360), "length": 140.0, "orientation": "vertical", "target": "b_pg2"}
			]
			base["switches"] = [{"id": "sw_pg", "pos": Vector2(600, 200), "target": "door_pg"}]
			base["doors"] = [{"id": "door_pg", "pos": Vector2(1040, 360), "rot": 1.5708, "logic": "AND", "req_count": 1}]
		37:
			base["title"] = "CHAMBER 37: THE CATACOMB"
			base["par_loops"] = 4
			base["interior_walls"] = [
				Rect2(300, 160, 32, 400), Rect2(550, 32, 32, 400),
				Rect2(800, 280, 32, 408), Rect2(1000, 32, 32, 400)
			]
			base["plates"] = [
				{"id": "p_cat1", "pos": Vector2(160, 200), "target": "door_cat"},
				{"id": "p_cat2", "pos": Vector2(420, 540), "target": "door_cat"},
				{"id": "p_cat3", "pos": Vector2(680, 180), "target": "door_cat"}
			]
			base["doors"] = [{"id": "door_cat", "pos": Vector2(1000, 480), "rot": 1.5708, "logic": "AND", "req_count": 3}]
			base["drones"] = [
				{"pos": Vector2(420, 200), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, 200)]), "patrol_speed": 100.0},
				{"pos": Vector2(680, 450), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, -200)]), "patrol_speed": 100.0}
			]
		38:
			base["title"] = "CHAMBER 38: NEURAL FRACTURE"
			base["par_loops"] = 4
			base["interior_walls"] = [Rect2(440, 32, 32, 300), Rect2(440, 400, 32, 288), Rect2(840, 32, 32, 300), Rect2(840, 400, 32, 288)]
			base["switches"] = [
				{"id": "sw_nf1", "pos": Vector2(240, 200), "target": "door_nf1"},
				{"id": "sw_nf2", "pos": Vector2(640, 540), "target": "door_nf2"}
			]
			base["plates"] = [{"id": "p_nf3", "pos": Vector2(640, 200), "target": "door_nf2"}]
			base["doors"] = [
				{"id": "door_nf1", "pos": Vector2(440, 350), "rot": 1.5708, "logic": "AND", "req_count": 1},
				{"id": "door_nf2", "pos": Vector2(840, 350), "rot": 1.5708, "logic": "AND", "req_count": 2}
			]
			base["terminals"] = [{"pos": Vector2(240, 520), "log_id": "log_09"}]
			base["drones"] = [{"pos": Vector2(640, 360), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(140, 0)]), "patrol_speed": 115.0}]
		39:
			base["title"] = "CHAMBER 39: THE GAUNTLET OF DREAD"
			base["par_loops"] = 5
			base["interior_walls"] = [
				Rect2(360, 160, 560, 32), Rect2(360, 528, 560, 32)
			]
			base["timed_buttons"] = [
				{"id": "b_gd1", "pos": Vector2(200, 360), "duration": 6.0, "target": "las_gd1"}
			]
			base["plates"] = [
				{"id": "p_gd2", "pos": Vector2(640, 100), "target": "door_gd"},
				{"id": "p_gd3", "pos": Vector2(640, 620), "target": "door_gd"}
			]
			base["lasers"] = [{"id": "las_gd1", "pos": Vector2(920, 360), "length": 180.0, "orientation": "vertical", "target": "b_gd1"}]
			base["doors"] = [{"id": "door_gd", "pos": Vector2(1080, 360), "rot": 1.5708, "logic": "AND", "req_count": 2}]
			base["drones"] = [
				{"pos": Vector2(460, 360), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(360, 0)]), "patrol_speed": 130.0, "chase_speed": 175.0}
			]
		40:
			base["title"] = "CHAMBER 40: DELTA APEX: THE CONTAINMENT SEAL"
			base["par_loops"] = 5
			base["interior_walls"] = [
				Rect2(360, 32, 32, 656), Rect2(624, 32, 32, 656), Rect2(880, 32, 32, 656)
			]
			base["timed_buttons"] = [
				{"id": "b_cseal1", "pos": Vector2(200, 200), "duration": 5.0, "target": "las_cs1"},
				{"id": "b_cseal2", "pos": Vector2(490, 520), "duration": 5.0, "target": "las_cs2"}
			]
			base["plates"] = [{"id": "p_cseal3", "pos": Vector2(750, 200), "target": "door_cs"}]
			base["lasers"] = [
				{"id": "las_cs1", "pos": Vector2(360, 360), "length": 140.0, "orientation": "vertical", "target": "b_cseal1"},
				{"id": "las_cs2", "pos": Vector2(624, 360), "length": 140.0, "orientation": "vertical", "target": "b_cseal2"}
			]
			base["doors"] = [{"id": "door_cs", "pos": Vector2(880, 360), "rot": 1.5708, "logic": "AND", "req_count": 1}]
			base["drones"] = [
				{"pos": Vector2(490, 200), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, 200)]), "patrol_speed": 115.0},
				{"pos": Vector2(750, 480), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, -200)]), "patrol_speed": 115.0}
			]

		# =========================================================================
		# SECTOR 5: OMEGA WING (Chambers 41 - 50)
		# =========================================================================
		41:
			base["title"] = "CHAMBER 41: SINGULARITY THRESHOLD"
			base["par_loops"] = 4
			base["interior_walls"] = [Rect2(400, 32, 32, 280), Rect2(400, 400, 32, 288), Rect2(840, 32, 32, 280), Rect2(840, 400, 32, 288)]
			base["plates"] = [
				{"id": "p_st1", "pos": Vector2(200, 200), "target": "door_st"},
				{"id": "p_st2", "pos": Vector2(200, 520), "target": "door_st"},
				{"id": "p_st3", "pos": Vector2(620, 200), "target": "door_st"}
			]
			base["doors"] = [{"id": "door_st", "pos": Vector2(840, 360), "rot": 1.5708, "logic": "AND", "req_count": 3}]
			base["drones"] = [{"pos": Vector2(620, 450), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(160, 0)]), "patrol_speed": 110.0}]
		42:
			base["title"] = "CHAMBER 42: CHRONAL CASCADE"
			base["par_loops"] = 4
			base["interior_walls"] = [Rect2(340, 32, 32, 656), Rect2(680, 32, 32, 656), Rect2(980, 32, 32, 656)]
			base["timed_buttons"] = [
				{"id": "b_cc1", "pos": Vector2(180, 200), "duration": 5.0, "target": "las_cc1"},
				{"id": "b_cc2", "pos": Vector2(510, 520), "duration": 5.0, "target": "las_cc2"},
				{"id": "b_cc3", "pos": Vector2(830, 200), "duration": 5.0, "target": "las_cc3"}
			]
			base["lasers"] = [
				{"id": "las_cc1", "pos": Vector2(340, 360), "length": 140.0, "orientation": "vertical", "target": "b_cc1"},
				{"id": "las_cc2", "pos": Vector2(680, 360), "length": 140.0, "orientation": "vertical", "target": "b_cc2"},
				{"id": "las_cc3", "pos": Vector2(980, 360), "length": 140.0, "orientation": "vertical", "target": "b_cc3"}
			]
		43:
			base["title"] = "CHAMBER 43: PARADOX ENGINE"
			base["par_loops"] = 5
			base["interior_walls"] = [Rect2(360, 180, 560, 32), Rect2(360, 500, 560, 32)]
			base["plates"] = [
				{"id": "p_pe1", "pos": Vector2(200, 200), "target": "door_pe"},
				{"id": "p_pe2", "pos": Vector2(200, 520), "target": "door_pe"},
				{"id": "p_pe3", "pos": Vector2(640, 100), "target": "door_pe"},
				{"id": "p_pe4", "pos": Vector2(640, 620), "target": "door_pe"}
			]
			base["doors"] = [{"id": "door_pe", "pos": Vector2(1040, 360), "rot": 1.5708, "logic": "AND", "req_count": 4}]
			base["drones"] = [
				{"pos": Vector2(500, 360), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(280, 0)]), "patrol_speed": 135.0, "chase_speed": 180.0}
			]
		44:
			base["title"] = "CHAMBER 44: THE GRAND HARMONIZER"
			base["par_loops"] = 4
			base["interior_walls"] = [Rect2(624, 32, 32, 656), Rect2(32, 344, 1216, 32)]
			base["timed_buttons"] = [
				{"id": "b_gh1", "pos": Vector2(220, 180), "duration": 5.5, "target": "door_gh"},
				{"id": "b_gh2", "pos": Vector2(980, 180), "duration": 5.5, "target": "door_gh"},
				{"id": "b_gh3", "pos": Vector2(220, 540), "duration": 5.5, "target": "door_gh"}
			]
			base["doors"] = [{"id": "door_gh", "pos": Vector2(980, 540), "rot": 0.0, "logic": "AND", "req_count": 3}]
			base["drones"] = [
				{"pos": Vector2(400, 180), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, 120)]), "patrol_speed": 105.0},
				{"pos": Vector2(800, 540), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, -120)]), "patrol_speed": 105.0}
			]
		45:
			base["title"] = "CHAMBER 45: PROXY-ZERO SANCTUM"
			base["par_loops"] = 4
			base["interior_walls"] = [Rect2(420, 32, 32, 320), Rect2(420, 420, 32, 268), Rect2(820, 32, 32, 320), Rect2(820, 420, 32, 268)]
			base["plates"] = [
				{"id": "p_pz1", "pos": Vector2(240, 200), "target": "door_pz"},
				{"id": "p_pz2", "pos": Vector2(620, 540), "target": "door_pz"}
			]
			base["doors"] = [{"id": "door_pz", "pos": Vector2(820, 370), "rot": 1.5708, "logic": "AND", "req_count": 2}]
			base["terminals"] = [{"pos": Vector2(620, 200), "log_id": "log_09"}]
			base["drones"] = [{"pos": Vector2(620, 360), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(140, 0)]), "patrol_speed": 115.0}]
		46:
			base["title"] = "CHAMBER 46: THE CAUSAL VORTEX"
			base["par_loops"] = 5
			base["interior_walls"] = [Rect2(340, 32, 32, 656), Rect2(880, 32, 32, 656)]
			base["plates"] = [
				{"id": "p_vx1", "pos": Vector2(180, 200), "target": "las_vx1"},
				{"id": "p_vx2", "pos": Vector2(180, 520), "target": "las_vx2"}
			]
			base["switches"] = [{"id": "sw_vx3", "pos": Vector2(610, 360), "target": "door_vx"}]
			base["lasers"] = [
				{"id": "las_vx1", "pos": Vector2(340, 360), "length": 160.0, "orientation": "vertical", "target": "p_vx1"},
				{"id": "las_vx2", "pos": Vector2(880, 360), "length": 160.0, "orientation": "vertical", "target": "p_vx2"}
			]
			base["doors"] = [{"id": "door_vx", "pos": Vector2(1060, 360), "rot": 1.5708, "logic": "AND", "req_count": 1}]
			base["drones"] = [
				{"pos": Vector2(610, 180), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, 360)]), "patrol_speed": 120.0}
			]
		47:
			base["title"] = "CHAMBER 47: INFINITE HORIZON"
			base["par_loops"] = 5
			base["interior_walls"] = [Rect2(440, 160, 32, 400), Rect2(780, 160, 32, 400)]
			base["plates"] = [
				{"id": "p_ih1", "pos": Vector2(220, 360), "target": "door_ih"},
				{"id": "p_ih2", "pos": Vector2(610, 180), "target": "door_ih"},
				{"id": "p_ih3", "pos": Vector2(610, 540), "target": "door_ih"}
			]
			base["doors"] = [{"id": "door_ih", "pos": Vector2(1000, 360), "rot": 1.5708, "logic": "AND", "req_count": 3}]
			base["drones"] = [
				{"pos": Vector2(610, 360), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(120, 0)]), "patrol_speed": 125.0}
			]
		48:
			base["title"] = "CHAMBER 48: THE SINGULARITY CRUCIBLE"
			base["par_loops"] = 5
			base["interior_walls"] = [
				Rect2(340, 32, 32, 280), Rect2(340, 400, 32, 288),
				Rect2(680, 32, 32, 280), Rect2(680, 400, 32, 288),
				Rect2(960, 32, 32, 280), Rect2(960, 400, 32, 288)
			]
			base["timed_buttons"] = [
				{"id": "b_cr1", "pos": Vector2(180, 200), "duration": 5.0, "target": "las_cr1"},
				{"id": "b_cr2", "pos": Vector2(510, 520), "duration": 4.5, "target": "las_cr2"}
			]
			base["plates"] = [{"id": "p_cr3", "pos": Vector2(820, 200), "target": "door_cr"}]
			base["lasers"] = [
				{"id": "las_cr1", "pos": Vector2(340, 360), "length": 96.0, "orientation": "vertical", "target": "b_cr1"},
				{"id": "las_cr2", "pos": Vector2(680, 360), "length": 96.0, "orientation": "vertical", "target": "b_cr2"}
			]
			base["doors"] = [{"id": "door_cr", "pos": Vector2(960, 360), "rot": 1.5708, "logic": "AND", "req_count": 1}]
			base["drones"] = [
				{"pos": Vector2(510, 200), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, 220)]), "patrol_speed": 115.0},
				{"pos": Vector2(820, 480), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(0, -220)]), "patrol_speed": 115.0}
			]
		49:
			base["title"] = "CHAMBER 49: THORNE'S LAST STAND"
			base["par_loops"] = 5
			base["interior_walls"] = [
				Rect2(360, 180, 560, 32), Rect2(360, 500, 560, 32),
				Rect2(640, 212, 32, 288)
			]
			base["plates"] = [
				{"id": "p_tls1", "pos": Vector2(200, 200), "target": "door_tls"},
				{"id": "p_tls2", "pos": Vector2(200, 520), "target": "door_tls"},
				{"id": "p_tls3", "pos": Vector2(500, 360), "target": "door_tls"},
				{"id": "p_tls4", "pos": Vector2(780, 360), "target": "door_tls"}
			]
			base["doors"] = [{"id": "door_tls", "pos": Vector2(1040, 360), "rot": 1.5708, "logic": "AND", "req_count": 4}]
			base["drones"] = [
				{"pos": Vector2(500, 100), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(280, 0)]), "patrol_speed": 130.0},
				{"pos": Vector2(780, 620), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(-280, 0)]), "patrol_speed": 130.0}
			]
		50:
			base["title"] = "CHAMBER 50: THE SINGULARITY BREACH"
			base["par_loops"] = 5
			base["interior_walls"] = [
				Rect2(320, 32, 32, 240), Rect2(320, 448, 32, 240),
				Rect2(960, 32, 32, 240), Rect2(960, 448, 32, 240),
				Rect2(520, 240, 240, 32), Rect2(520, 448, 240, 32)
			]
			base["plates"] = [
				{"id": "fin_nw", "pos": Vector2(180, 180), "target": "core_singularity"},
				{"id": "fin_sw", "pos": Vector2(180, 540), "target": "core_singularity"},
				{"id": "fin_ne", "pos": Vector2(1080, 180), "target": "core_singularity"},
				{"id": "fin_se", "pos": Vector2(1080, 540), "target": "core_singularity"}
			]
			base["doors"] = [{"id": "core_singularity", "pos": Vector2(640, 360), "rot": 0.0, "logic": "AND", "req_count": 4}]
			base["drones"] = [
				{"pos": Vector2(400, 140), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(480, 0)]), "patrol_speed": 115.0},
				{"pos": Vector2(880, 580), "waypoints": PackedVector2Array([Vector2.ZERO, Vector2(-480, 0)]), "patrol_speed": 115.0}
			]
			base["terminals"] = [{"pos": Vector2(640, 200), "log_id": "log_10"}]
			base["exit_pos"] = Vector2(640, 360)
			
	return base
