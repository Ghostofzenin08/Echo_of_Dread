extends Node

# AdManager: Cross-platform monetization and advertisement controller for Echo of Dread.
# Supports:
# 1. Web Game Ad Networks (CrazyGames SDK, GameDistribution, Poki SDK, itch.io Web)
# 2. Rewarded Video Ads (Puzzle Hints, Loop Time Extenders, Chronal Cosmetics)
# 3. Paced Interstitial Ads (Between chambers, strict 180s cooldown)
# 4. In-Editor & Desktop safe simulation (prevents crashes, enables unit testing)

signal rewarded_completed(reward_type: String)
signal rewarded_failed(error_message: String)
signal interstitial_opened
signal interstitial_closed
signal ad_state_changed(is_ad_active: bool)

# Monetization Configuration
@export var is_ad_free: bool = false
@export var interstitial_cooldown: float = 180.0 # 3 minutes minimum between unprompted interstitials
@export var chambers_per_interstitial: int = 3   # Show only every 3 chambers completed

var last_interstitial_time: float = -999.0
var chambers_cleared_since_ad: int = 0
var is_ad_in_progress: bool = false

# Web bridge callback storage
var _js_rewarded_callback = null
var _js_interstitial_callback = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_web_bridge()

func _setup_web_bridge() -> void:
	if not OS.has_feature("web"):
		return
		
	if ClassDB.class_exists("JavaScriptBridge"):
		var js = ClassDB.instantiate("JavaScriptBridge")
		if js and js.has_method("create_callback"):
			_js_rewarded_callback = js.create_callback(_on_js_rewarded_result)
			_js_interstitial_callback = js.create_callback(_on_js_interstitial_result)
			
			# Expose Godot listeners to window object for web ad networks
			var init_script := """
			window.godotAdListeners = {
				onRewardedComplete: function(type) {
					if (window._godotRewardedCb) window._godotRewardedCb(type, true);
				},
				onRewardedFailed: function(reason) {
					if (window._godotRewardedCb) window._godotRewardedCb(reason, false);
				},
				onInterstitialClosed: function() {
					if (window._godotInterstitialCb) window._godotInterstitialCb();
				}
			};
			"""
			js.eval(init_script)

# ==============================================================================
# Rewarded Video Ads (Puzzle Hints, Chrono-Surge, Cosmetics)
# ==============================================================================

func is_rewarded_ready() -> bool:
	return not is_ad_in_progress

func show_rewarded(reward_type: String = "hint") -> void:
	if is_ad_in_progress:
		rewarded_failed.emit("Ad already in progress")
		return
		
	is_ad_in_progress = true
	ad_state_changed.emit(true)
	
	if OS.has_feature("web"):
		_request_web_rewarded(reward_type)
	else:
		_simulate_ad(reward_type, true)

func _request_web_rewarded(reward_type: String) -> void:
	if not ClassDB.class_exists("JavaScriptBridge"):
		_simulate_ad(reward_type, true)
		return
		
	var js = ClassDB.instantiate("JavaScriptBridge")
	if not js or not js.has_method("eval"):
		_simulate_ad(reward_type, true)
		return
		
	# Call universal Web Game Ad SDK wrapper
	# Handles CrazyGames, GameDistribution, Poki or test fallback
	var ad_req := """
	(function() {
		var rType = '%s';
		if (window.CrazyGames && window.CrazyGames.SDK && window.CrazyGames.SDK.ad) {
			window.CrazyGames.SDK.ad.requestAd('rewarded', {
				adFinished: function() { if (window.godotAdListeners) window.godotAdListeners.onRewardedComplete(rType); },
				adError: function(err) { if (window.godotAdListeners) window.godotAdListeners.onRewardedFailed(String(err)); }
			});
		} else if (window.gdsdk && typeof window.gdsdk.showAd === 'function') {
			window.gdsdk.showAd('rewarded')
				.then(function() { if (window.godotAdListeners) window.godotAdListeners.onRewardedComplete(rType); })
				.catch(function(err) { if (window.godotAdListeners) window.godotAdListeners.onRewardedFailed(String(err)); });
		} else if (window.PokiSDK) {
			window.PokiSDK.rewardedBreak().then(function(success) {
				if (success) { if (window.godotAdListeners) window.godotAdListeners.onRewardedComplete(rType); }
				else { if (window.godotAdListeners) window.godotAdListeners.onRewardedFailed('User skipped'); }
			});
		} else {
			// No external SDK present on web host (e.g. standalone itch.io embed) -> Safe 1.5s simulated view
			setTimeout(function() {
				if (window.godotAdListeners) window.godotAdListeners.onRewardedComplete(rType);
			}, 1500);
		}
	})();
	""" % [reward_type.replace("'", "")]
	
	js.eval(ad_req)

func _on_js_rewarded_result(args: Array) -> void:
	is_ad_in_progress = false
	ad_state_changed.emit(false)
	
	var r_type: String = str(args[0]) if args.size() > 0 else "hint"
	var success: bool = bool(args[1]) if args.size() > 1 else true
	
	if success:
		_grant_reward(r_type)
	else:
		rewarded_failed.emit(str(args[0]) if args.size() > 0 else "Ad dismissed")

# ==============================================================================
# Paced Interstitial Ads (Between Chambers Only)
# ==============================================================================

func on_chamber_cleared() -> void:
	chambers_cleared_since_ad += 1
	if chambers_cleared_since_ad >= chambers_per_interstitial:
		var current_time := Time.get_ticks_msec() / 1000.0
		if (current_time - last_interstitial_time) >= interstitial_cooldown:
			show_interstitial()

func show_interstitial() -> bool:
	if is_ad_free or is_ad_in_progress:
		return false
		
	var current_time := Time.get_ticks_msec() / 1000.0
	if (current_time - last_interstitial_time) < interstitial_cooldown and last_interstitial_time > 0:
		return false
		
	is_ad_in_progress = true
	last_interstitial_time = current_time
	chambers_cleared_since_ad = 0
	ad_state_changed.emit(true)
	interstitial_opened.emit()
	
	if OS.has_feature("web"):
		_request_web_interstitial()
	else:
		_simulate_ad("interstitial", false)
		
	return true

func _request_web_interstitial() -> void:
	if not ClassDB.class_exists("JavaScriptBridge"):
		_simulate_ad("interstitial", false)
		return
		
	var js = ClassDB.instantiate("JavaScriptBridge")
	if not js or not js.has_method("eval"):
		_simulate_ad("interstitial", false)
		return
		
	var ad_req := """
	(function() {
		if (window.CrazyGames && window.CrazyGames.SDK && window.CrazyGames.SDK.ad) {
			window.CrazyGames.SDK.ad.requestAd('midgame', {
				adFinished: function() { if (window.godotAdListeners) window.godotAdListeners.onInterstitialClosed(); },
				adError: function() { if (window.godotAdListeners) window.godotAdListeners.onInterstitialClosed(); }
			});
		} else if (window.gdsdk && typeof window.gdsdk.showAd === 'function') {
			window.gdsdk.showAd('interstitial')
				.finally(function() { if (window.godotAdListeners) window.godotAdListeners.onInterstitialClosed(); });
		} else if (window.PokiSDK) {
			window.PokiSDK.commercialBreak()
				.finally(function() { if (window.godotAdListeners) window.godotAdListeners.onInterstitialClosed(); });
		} else {
			setTimeout(function() {
				if (window.godotAdListeners) window.godotAdListeners.onInterstitialClosed();
			}, 1000);
		}
	})();
	"""
	js.eval(ad_req)

func _on_js_interstitial_result(_args: Array) -> void:
	is_ad_in_progress = false
	ad_state_changed.emit(false)
	interstitial_closed.emit()

# ==============================================================================
# Simulation & Rewards Engine (Editor / Desktop / Test Runner)
# ==============================================================================

func _simulate_ad(reward_type: String, is_rewarded: bool) -> void:
	# In headless tests, resolve immediately to not block assertions
	if DisplayServer.get_name() == "headless":
		is_ad_in_progress = false
		ad_state_changed.emit(false)
		if is_rewarded:
			_grant_reward(reward_type)
		else:
			interstitial_closed.emit()
		return
		
	# In desktop/editor interactive play, provide a sleek 1-second transmission delay
	var tree := get_tree()
	if tree:
		var timer := tree.create_timer(1.0, false)
		timer.timeout.connect(func():
			is_ad_in_progress = false
			ad_state_changed.emit(false)
			if is_rewarded:
				_grant_reward(reward_type)
			else:
				interstitial_closed.emit()
		)
	else:
		is_ad_in_progress = false
		ad_state_changed.emit(false)
		if is_rewarded:
			_grant_reward(reward_type)
		else:
			interstitial_closed.emit()

func _grant_reward(reward_type: String) -> void:
	if reward_type.begins_with("hint_"):
		var lvl_str := reward_type.trim_prefix("hint_")
		var chamber_id := int(lvl_str)
		if chamber_id > 0 and SaveManager:
			SaveManager.unlock_hint(chamber_id)
	elif reward_type == "hint":
		var cur_lvl := GameManager.current_level_index if GameManager else 1
		if SaveManager:
			SaveManager.unlock_hint(cur_lvl)
			
	rewarded_completed.emit(reward_type)

# ==============================================================================
# Chamber Hints Database
# ==============================================================================

const CHAMBER_HINTS: Dictionary = {
	1: "Use Echo 1 to press the pressure plate on the north corridor, holding the blast door open so you can reach the exit portal.",
	2: "Coordinate your loops: have Echo 1 toggle the primary terminal switch, then use Echo 2 to sprint through the timed security gate.",
	3: "Lure the security drone away with Echo 1's path, creating an open window for your real body to access the temporal core.",
	4: "Step on the synchronization pads simultaneously. Record Echo 1 on Pad A, Echo 2 on Pad B, and claim the Singularity Exit.",
	5: "Divide your actions: Echo 1 holds down the laser override lever while Echo 2 clears the barrier in the eastern chamber.",
	10: "Sector Alpha Finale: Loop 1 overrides the power distributor, Loop 2 discharges the plasma coil, and your final loop breaches the bulkhead.",
	20: "Sector Beta Apex: Synchronize 3 harmonic frequencies across all 3 timed buttons before the 15-second loop counter expires.",
	30: "Sector Gamma Core: Guide Echoes through the laser labyrinth without intersecting the patrol drone's detection radius.",
	40: "Delta Sector Mastery: Leverage simultaneous pressure plate weights with Echo 1 and Echo 2 to unlock the double-gated vault.",
	50: "Omega Singularity: All four temporal anchor plates must be occupied concurrently. Orchestrate 4 distinct echo loops to escape Chronos Facility."
}

func get_chamber_hint(chamber_id: int) -> String:
	if CHAMBER_HINTS.has(chamber_id):
		return CHAMBER_HINTS[chamber_id]
	return "Synchronize your echo recording loops: coordinate plate depression, timed buttons, and drone evasion to breach the chamber exit."
