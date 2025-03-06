/datum/action/xeno_action/activable/pounce/lurker
	macro_path = /datum/action/xeno_action/verb/verb_pounce
	action_type = XENO_ACTION_CLICK
	ability_primacy = XENO_PRIMARY_ACTION_1
	xeno_cooldown = 6 SECONDS
	plasma_cost = 20

	// Config options
	knockdown = FALSE
	knockdown_duration = 2.5
	freeze_time = 15
	can_be_shield_blocked = TRUE

/datum/action/xeno_action/onclick/lurker_invisibility
	name = "Turn Invisible"
	action_icon_state = "lurker_invisibility"
	macro_path = /datum/action/xeno_action/verb/verb_lurker_invisibility
	ability_primacy = XENO_PRIMARY_ACTION_2
	action_type = XENO_ACTION_CLICK
	plasma_cost = 20

	var/duration = 30 SECONDS // 30 seconds base
	var/invis_timer_id = TIMER_ID_NULL
	var/alpha_amount = 25
	var/speed_buff = 0.20

// tightly coupled 'buff next slash' action
/datum/action/xeno_action/onclick/lurker_assassinate
	name = "Crippling Strike"
	action_icon_state = "lurker_inject_neuro"
	macro_path = /datum/action/xeno_action/verb/verb_crippling_strike
	ability_primacy = XENO_PRIMARY_ACTION_3
	action_type = XENO_ACTION_ACTIVATE
	xeno_cooldown = 10 SECONDS
	plasma_cost = 20

	var/buff_duration = 50

// VAMP LURKER ABILITIES

/datum/action/xeno_action/activable/pounce/rush
	name = "Rush"
	action_icon_state = "pounce"
	action_text = "rush"
	macro_path = /datum/action/xeno_action/verb/verb_rush
	ability_primacy = XENO_PRIMARY_ACTION_1
	action_type = XENO_ACTION_CLICK
	xeno_cooldown = 6 SECONDS
	plasma_cost = 0

	// Config options
	distance = 4
	knockdown = FALSE
	freeze_self = FALSE

/datum/action/xeno_action/activable/flurry
	name = "Flurry"
	action_icon_state = "rav_spike"
	macro_path = /datum/action/xeno_action/verb/verb_flurry
	ability_primacy = XENO_PRIMARY_ACTION_2
	action_type = XENO_ACTION_CLICK
	xeno_cooldown = 3 SECONDS

/datum/action/xeno_action/activable/tail_jab
	name = "Tail Jab"
	action_icon_state = "prae_pierce"
	macro_path = /datum/action/xeno_action/verb/verb_tail_jab
	ability_primacy = XENO_PRIMARY_ACTION_3
	action_type = XENO_ACTION_CLICK
	xeno_cooldown = 7 SECONDS

/datum/action/xeno_action/activable/headbite
	name = "Headbite"
	action_icon_state = "headbite"
	macro_path = /datum/action/xeno_action/verb/verb_headbite
	ability_primacy = XENO_PRIMARY_ACTION_4
	action_type = XENO_ACTION_CLICK
	xeno_cooldown = 10 SECONDS

// STALKER LURKER ABILITIES
/datum/action/xeno_action/activable/pounce/lash
	name = "Pounce"
	action_icon_state = "pounce"
	action_text = "pounce"
	macro_path = /datum/action/xeno_action/verb/verb_lash
	ability_primacy = XENO_PRIMARY_ACTION_1
	action_type = XENO_ACTION_CLICK
	xeno_cooldown = 6 SECONDS
	plasma_cost = 0

	var/nail_duration = 30
	knockdown_duration = 0.5
	knockdown = FALSE
	freeze_self = FALSE
	freeze_play_sound = FALSE

/datum/action/xeno_action/onclick/lurker_stalking
	name = "Turn Invisibility"
	action_icon_state = "lurker_invisibility"
	macro_path = /datum/action/xeno_action/verb/verb_lurker_stalking
	ability_primacy = XENO_PRIMARY_ACTION_2
	action_type = XENO_ACTION_CLICK
	plasma_cost = 0
	xeno_cooldown = 15 SECONDS

	var/adjust_invis = 2 SECONDS
	var/alpha_amount = 20
	var/speed_buff = XENO_SPEED_FASTMOD_TIER_6

/datum/action/xeno_action/onclick/echolocation
	name = "Echolocation"
	action_icon_state = "screech"
	macro_path = /datum/action/xeno_action/verb/verb_echolocation
	ability_primacy = XENO_PRIMARY_ACTION_3
	xeno_cooldown = 45 SECONDS

	var/datum/shape/rectangle/square/range_bounds
	var/echo_range = 25
	var/blip_type = "detector"
	var/list/blip_pool = list()
	var/speed_buff_amount = XENO_SPEED_FASTMOD_TIER_4
	var/shield_amount = 100

/datum/action/xeno_action/onclick/hibernate
	name = "Hibernate"
	action_icon_state = "warden_heal"
	macro_path = /datum/action/xeno_action/verb/verb_hibernate
	action_type = XENO_ACTION_CLICK
	ability_primacy = XENO_PRIMARY_ACTION_4
	xeno_cooldown = 50 SECONDS

	var/sleep_timer = null
	var/regeneration = 10

/datum/action/xeno_action/onclick/heartbite
	name = "Heartbite"
	action_icon_state = "headbite"
	macro_path = /datum/action/xeno_action/verb/verb_heartbite
	ability_primacy = XENO_PRIMARY_ACTION_5
	action_type = XENO_ACTION_CLICK
