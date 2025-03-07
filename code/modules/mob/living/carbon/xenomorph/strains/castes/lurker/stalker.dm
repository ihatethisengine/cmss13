/datum/xeno_strain/stalker
	name = LURKER_STALKER
	description = "You lose all of your abilities and you forefeit a chunk of your health and damage in exchange for a large amount of armor, a little bit of movement speed, increased attack speed, and brand new abilities that make you an assassin. Rush on your opponent to disorient them and Flurry to unleash a forward cleave that can hit and slow three talls and heal you for every tall you hit. Use your special AoE Tail Jab to knock talls away, doing more damage with direct hits and even more damage and a stun if they smack into walls. Finally, execute unconscious talls with a headbite to heal your wounds."
	flavor_description = "Show no mercy! Slaughter them all!"
	icon_state_prefix = "Vampire"

	actions_to_remove = list(
		/datum/action/xeno_action/onclick/lurker_invisibility,
		/datum/action/xeno_action/onclick/lurker_assassinate,
		/datum/action/xeno_action/activable/pounce/lurker,
		/datum/action/xeno_action/activable/tail_stab,
	)
	actions_to_add = list(
		/datum/action/xeno_action/activable/pounce/lash,
		/datum/action/xeno_action/onclick/lurker_stalking,
		/datum/action/xeno_action/onclick/echolocation,
		/datum/action/xeno_action/onclick/hibernate,
		/datum/action/xeno_action/onclick/heartbite,
	)
	behavior_delegate_type = /datum/behavior_delegate/lurker_stalker

/datum/xeno_strain/stalker/apply_strain(mob/living/carbon/xenomorph/lurker/lurker)
	lurker.plasmapool_modifier = 0
	lurker.health_modifier -= XENO_HEALTH_MOD_SMALL
	lurker.speed_modifier += XENO_SPEED_FASTMOD_TIER_1

	var/datum/mob_hud/execute_hud = GLOB.huds[MOB_HUD_EXECUTE]
	execute_hud.add_hud_to(lurker, lurker)
	lurker.execute_hud = TRUE

	lurker.recalculate_everything()

/datum/action/xeno_action/activable/pounce/lash/use_ability(atom/target)
	var/mob/living/carbon/xenomorph/xeno = owner
	to_chat(world, "test1")
	if(!action_cooldown_check())
		return

	if(target == xeno)
		return

	if(!isturf(xeno.loc))
		to_chat(xeno, SPAN_XENOWARNING("We can't [action_text] from here!"))
		return

	if(!xeno.check_state())
		return

	var/datum/behavior_delegate/lurker_stalker/stalk = xeno.behavior_delegate
	var/pounce_turfs = (knockdown || stalk.nail_target_ref != null) //if invis is off and we are not on top of an enemy, we can only lash at hostiles
	to_chat(world, "test2")
	if(stalk.nail_target_ref && target == stalk.nail_target_ref.resolve())
		to_chat(xeno, SPAN_XENOWARNING("We cannot pounce onto someone we are currently nailing to the ground."))
		return
	var/mob/living/carbon/carbon_target = target
	if(!iscarbon(target) || carbon_target.stat == DEAD)
		for(var/mob/living/carbon/carbon in get_turf(target))
			carbon_target = carbon
			if(carbon_target.stat != DEAD)
				break
	if(!pounce_turfs && (!iscarbon(carbon_target) || carbon_target.stat == DEAD || xeno.can_not_harm(carbon_target)))
		to_chat(xeno, SPAN_XENOWARNING("We need a hostile target to lash at."))
		return
	to_chat(world, "test2.5")
	to_chat(world, "test2.6")
	if(istype(carbon_target))
		to_chat(world, "test2.7")
		stalk.lash_target_ref = WEAKREF(carbon_target)
		stalk.lash_initial_turf = get_turf(xeno)
		to_chat(world, "test2.8")
		RegisterSignal(owner, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(lashing_turf))
	to_chat(world, "test3")
	. = ..(carbon_target)
	to_chat(world, "test4")
	if(!.)
		stalk.lash_target_ref = null
		stalk.lash_initial_turf = null
		if(istype(carbon_target))
			UnregisterSignal(owner, COMSIG_MOVABLE_PRE_MOVE)
		return

/datum/action/xeno_action/activable/pounce/lash/proc/lashing_turf(mob/movable_mob, turf/new_loc)
	SIGNAL_HANDLER
	var/mob/living/carbon/xenomorph/xeno = owner
	var/datum/behavior_delegate/lurker_stalker/stalk = xeno.behavior_delegate
	if(!stalk.lash_target_ref)
		return

	var/mob/living/target = stalk.lash_target_ref.resolve()
	if(!target)
		return

	if(!knockdown && target.Adjacent(xeno))
		return COMPONENT_CANCEL_MOVE

/datum/action/xeno_action/activable/pounce/lash/on_end_pounce()
	var/mob/living/carbon/xenomorph/xeno = owner
	var/datum/behavior_delegate/lurker_stalker/stalk = xeno.behavior_delegate
	UnregisterSignal(owner, COMSIG_MOVABLE_PRE_MOVE)
	if(!stalk.lash_target_ref)
		return

	var/mob/living/target = stalk.lash_target_ref.resolve()
	stalk.lash_target_ref = null
	if(!target)
		return
	if(!xeno.check_state())
		return
	if(target.stat == DEAD || xeno.can_not_harm(target) || !xeno.Adjacent(target))
		return
	if(knockdown && stalk.lash_initial_turf)
		var/dir1 = get_dir(stalk.lash_initial_turf, xeno)
		var/dir2 = get_dir(xeno, target)
		if(!((dir1 & dir2) || (dir2 & dir1))) //still pounce them if they in a relative same direction as the direction of the pounce
			return
		target.KnockDown(knockdown_duration)
	additional_effects(target)

/datum/action/xeno_action/activable/pounce/lash/additional_effects(mob/living/living_target) //pounce effects
	var/mob/living/carbon/xenomorph/xeno = owner
	if(!istype(xeno))
		return
	var/datum/behavior_delegate/lurker_stalker/stalk = xeno.behavior_delegate
	stalk.lash_target_ref = null
	if(knockdown)
		var/mob/living/carbon/target = living_target
		RegisterSignal(xeno, COMSIG_XENO_SLASH_ADDITIONAL_EFFECTS_SELF, PROC_REF(remove_freeze), TRUE) // Suppresses runtime ever we pounce again before slashing
		step_to(xeno, target)
		if(target.stat == DEAD)
			return
		var/datum/action/xeno_action/onclick/lurker_stalking/lurker_invis = get_action(xeno, /datum/action/xeno_action/onclick/lurker_stalking)
		if(lurker_invis)
			lurker_invis.invisibility_off()
		var/finish_him = target.stat == UNCONSCIOUS
		xeno.flick_attack_overlay(target, "tail")
		target.last_damage_data = create_cause_data(xeno.caste_type, xeno)
		target.apply_armoured_damage(get_xeno_damage_slash(target, xeno.caste.melee_damage_upper), ARMOR_MELEE, BRUTE, "chest")

		to_chat(world, "test [target.has_status_effect(/datum/status_effect/incapacitating/nailed)]")
		playsound(target, 'sound/weapons/alien_tail_attack.ogg', 30, TRUE)
		shake_camera(target, 2, 1)
		apply_cooldown_override(2 SECONDS)
		// if(xeno.loc != target.loc)
		// 	return
		stalk.add_nailed(target, nail_duration)
		if(finish_him)
			target.death(create_cause_data("nailing to the ground", xeno), FALSE)
		return
	var/mob/living/carbon/target = living_target
	target.sway_jitter(times = 2)
	xeno.animation_attack_on(target)
	xeno.flick_attack_overlay(target, "slash")   //fake slash to prevent disarm abuse
	target.last_damage_data = create_cause_data(xeno.caste_type, xeno)
	target.apply_armoured_damage(get_xeno_damage_slash(target, xeno.caste.melee_damage_upper), ARMOR_MELEE, BRUTE, "chest")
	target.Slow(0.5)
	playsound(get_turf(target), 'sound/weapons/alien_claw_flesh3.ogg', 30, TRUE)
	shake_camera(target, 2, 1)

/datum/action/xeno_action/activable/pounce/lash/proc/remove_freeze(mob/living/carbon/xenomorph/xeno)
	SIGNAL_HANDLER

	var/datum/behavior_delegate/lurker_stalker/behaviour_del = xeno.behavior_delegate
	if(istype(behaviour_del))
		UnregisterSignal(xeno, COMSIG_XENO_SLASH_ADDITIONAL_EFFECTS_SELF)
		end_pounce_freeze()

/datum/action/xeno_action/onclick/lurker_stalking/use_ability(atom/targeted_atom)
	var/mob/living/carbon/xenomorph/xeno = owner

	if(!istype(xeno))
		return
	if(!action_cooldown_check())
		return
	if(!check_and_use_plasma_owner())
		return

	if(xeno.stealth)
		invisibility_off()
		return ..()

	if(xeno.action_busy)
		return

	xeno.visible_message(SPAN_XENONOTICE("[xeno] starts adjusting its camouflage to the surroundings."),
		SPAN_XENONOTICE("We start adjusting our camouflage to the surroundings."))
	if(!do_after(xeno, adjust_invis, INTERRUPT_ALL, BUSY_ICON_GENERIC))
		to_chat(xeno, SPAN_WARNING("We were interrupted."))
		return

	button.icon_state = "template_active"
	xeno.update_icons() // callback to make the icon_state indicate invisibility is in lurker/update_icon

	animate(xeno, alpha = alpha_amount, time = 0.1 SECONDS, easing = QUAD_EASING)

	xeno.speed_modifier -= speed_buff
	xeno.recalculate_speed()

	var/datum/behavior_delegate/lurker_stalker/behavior = xeno.behavior_delegate
	behavior.on_invisibility()

	return ..()

/datum/action/xeno_action/onclick/lurker_stalking/proc/invisibility_off()
	var/mob/living/carbon/xenomorph/xeno = owner

	if(!istype(xeno))
		return
	if(owner.alpha == initial(owner.alpha) && !xeno.stealth)
		return

	animate(xeno, alpha = initial(xeno.alpha), time = 0.1 SECONDS, easing = QUAD_EASING)
	to_chat(xeno, SPAN_XENOHIGHDANGER("We feel our invisibility end!"))

	button.icon_state = "template"
	xeno.update_icons()

	xeno.speed_modifier += speed_buff
	xeno.recalculate_speed()

	var/datum/behavior_delegate/lurker_stalker/behavior = xeno.behavior_delegate
	if(!istype(behavior))
		CRASH("lurker_base behavior_delegate missing/invalid for [xeno]!")
	apply_cooldown_override(xeno_cooldown)
	behavior.on_invisibility_off()

/datum/action/xeno_action/onclick/echolocation/use_ability(atom/targeted_atom)
	var/mob/living/carbon/xenomorph/xeno = owner

	if (!xeno.check_state())
		return

	if (!action_cooldown_check())
		return

	apply_cooldown()
	if(xeno.stealth)
		var/datum/action/xeno_action/onclick/lurker_stalking/lurker_invis_action = get_action(xeno, /datum/action/xeno_action/onclick/lurker_stalking)
		if(lurker_invis_action)
			lurker_invis_action.invisibility_off()
	playsound(xeno, 'sound/voice/xenos_roaring.ogg', 60, sound_range = echo_range)
	xeno.create_shriekwave(1)
	to_chat(xeno, SPAN_XENOHIGHDANGER("We feel ourselves frenzied as we send sound waves!"))
	xeno.add_xeno_shield(shield_amount, XENO_SHIELD_SOURCE_STALKER, /datum/xeno_shield/crusher)
	xeno.speed_modifier += speed_buff_amount
	xeno.recalculate_speed()

	addtimer(CALLBACK(src, PROC_REF(remove_buffs)), 1.5 SECONDS)
	var/turf/cur_turf = get_turf(xeno)
	if(!istype(cur_turf))
		return

	var/list/ping_candidates = get_mobs_in_z_level_range(cur_turf, echo_range)

	for(var/atom in ping_candidates)
		to_chat(world, "test [atom]")
		var/mob/living/mob = atom //do this to skip the unnecessary istype() check; everything in ping_candidate is a mob already
		if(mob == xeno)
			continue
		if(xeno.can_not_harm(mob))
			to_chat(world, "test3")
			continue
		if(mob.stat == DEAD)
			continue
		if(HAS_TRAIT(mob, TRAIT_CLOAKED))
			continue
		if(HAS_TRAIT(mob, TRAIT_NESTED))
			continue
		show_blip(xeno, mob)
	return ..()

/datum/action/xeno_action/onclick/echolocation/proc/show_blip(mob/user, atom/target, blip_icon)
	set waitfor = 0
	if(user && user.client)

		blip_icon = blip_icon ? blip_icon : blip_type

		if(!blip_pool[target])
			blip_pool[target] = new /obj/effect/detector_blip

		var/obj/effect/detector_blip/DB = blip_pool[target]
		var/c_view = user.client.view
		var/view_x_offset = 0
		var/view_y_offset = 0
		if(c_view > 7)
			if(user.client.pixel_x >= 0)
				view_x_offset = floor(user.client.pixel_x/32)
			else
				view_x_offset = ceil(user.client.pixel_x/32)
			if(user.client.pixel_y >= 0)
				view_y_offset = floor(user.client.pixel_y/32)
			else
				view_y_offset = ceil(user.client.pixel_y/32)

		var/diff_dir_x = 0
		var/diff_dir_y = 0
		if(target.x - user.x > c_view + view_x_offset)
			diff_dir_x = 4
		else if(target.x - user.x < -c_view + view_x_offset) diff_dir_x = 8
		if(target.y - user.y > c_view + view_y_offset)
			diff_dir_y = 1
		else if(target.y - user.y < -c_view + view_y_offset) diff_dir_y = 2
		if(diff_dir_x || diff_dir_y)
			DB.icon_state = "[blip_icon]_blip_dir"
			DB.setDir(diff_dir_x + diff_dir_y)
		else
			DB.icon_state = "[blip_icon]_blip"
			DB.setDir(initial(DB.dir))

		DB.screen_loc = "[clamp(c_view + 1 - view_x_offset + (target.x - user.x), 1, 2*c_view+1)],[clamp(c_view + 1 - view_y_offset + (target.y - user.y), 1, 2*c_view+1)]"
		user.client.add_to_screen(DB)
		addtimer(CALLBACK(src, PROC_REF(clear_pings), user, DB), 1 SECONDS)

/datum/action/xeno_action/onclick/echolocation/proc/clear_pings(mob/user, obj/effect/detector_blip/DB)
	if(user.client)
		user.client.remove_from_screen(DB)

/datum/action/xeno_action/onclick/echolocation/proc/remove_buffs()
	var/mob/living/carbon/xenomorph/xeno = owner
	xeno.speed_modifier -= speed_buff_amount
	var/datum/xeno_shield/found
	for (var/datum/xeno_shield/shield in xeno.xeno_shields)
		if (shield.shield_source == XENO_SHIELD_SOURCE_STALKER)
			found = shield
			break

	if (istype(found))
		found.on_removal()
		qdel(found)

/datum/action/xeno_action/onclick/hibernate/use_ability(atom/target)
	var/mob/living/carbon/xenomorph/xeno = owner
	if (!xeno.check_state() || xeno.action_busy)
		return

	var/turf/current_turf = get_turf(xeno)
	if(!current_turf || !istype(current_turf))
		return

	if (!action_cooldown_check())
		return

	if(xeno.stealth)
		to_chat(xeno, SPAN_XENOWARNING("We cannot enter hibernation while stalking."))
		return

	if(xeno.health >= xeno.maxHealth)
		to_chat(xeno, SPAN_XENOWARNING("We don't require hibernation."))
		return

	var/obj/effect/alien/weeds/alien_weeds = locate() in current_turf

	if(!alien_weeds)
		to_chat(xeno, SPAN_XENOWARNING("You need to be on weeds in order to hibernate."))
		return

	if(alien_weeds.linked_hive.hivenumber != xeno.hivenumber)
		to_chat(xeno, SPAN_XENOWARNING("These weeds don't belong to your hive! You can't hibernate here."))
		return

	to_chat(xeno, SPAN_XENONOTICE("We start preparing ourselves for hibernation."))
	if(!do_after(xeno, 2.5 SECONDS, INTERRUPT_ALL, BUSY_ICON_FRIENDLY))
		to_chat(xeno, SPAN_WARNING("We were interrupted."))
		return

	var/datum/behavior_delegate/lurker_stalker/lurker_stalker = xeno.behavior_delegate
	var/bonus_heal = min(lurker_stalker.heartbites, lurker_stalker.max_heartbite_bonus)
	new /datum/effects/heal_over_time(xeno, regeneration + bonus_heal, 2)
	var/overlay_size = 1
	if(bonus_heal == lurker_stalker.max_heartbite_bonus)
		overlay_size = 3
	else if(bonus_heal >= (lurker_stalker.max_heartbite_bonus / 2))
		overlay_size = 2

	xeno.KnockDown(3)
	xeno.SetSleeping(3)
	sleep_timer = addtimer(CALLBACK(src, PROC_REF(sleep_check)), 2 SECONDS, TIMER_STOPPABLE|TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_NO_HASH_WAIT)
	xeno.add_filter("sleep_on", 1, list("type" = "outline", "color" = "#17991b80", "size" = overlay_size))
	RegisterSignal(xeno, COMSIG_XENO_TAKE_DAMAGE, PROC_REF(bad_wake_up))
	button.icon_state = "template_active"
	xeno.update_icons()
	xeno.visible_message(SPAN_XENONOTICE("[xeno] falls into a deep sleep, quickly healing its wounds."),
		SPAN_XENONOTICE("We fall into a deep sleep, quickly healing our wounds."))
	return ..()

/datum/action/xeno_action/onclick/hibernate/proc/sleep_check()
	var/mob/living/carbon/xenomorph/xeno = owner
	if (!xeno.stat == DEAD)
		xeno.remove_filter("sleep_on")
		return

	var/turf/current_turf = get_turf(xeno)
	if(!current_turf || !istype(current_turf)) //something went wrong
		xeno.remove_filter("sleep_on")
		return

	if(xeno.health >= xeno.maxHealth)
		xeno.SetSleeping(0.5)
		to_chat(xeno, SPAN_XENONOTICE("Our rest is over now."))
		xeno.remove_filter("sleep_on")
		UnregisterSignal(xeno, COMSIG_XENO_TAKE_DAMAGE)
		apply_cooldown()
		button.icon_state = "template"
		xeno.update_icons()
		if(sleep_timer)
			deltimer(sleep_timer)
			sleep_timer = null
		return

	var/obj/effect/alien/weeds/alien_weeds = locate() in current_turf

	if(!alien_weeds)
		to_chat(world, "test1")
		bad_wake_up()
		return

	if(alien_weeds.linked_hive.hivenumber != xeno.hivenumber)
		to_chat(world, "test2")
		bad_wake_up()
		return

	var/datum/behavior_delegate/lurker_stalker/lurker_stalker = xeno.behavior_delegate
	var/bonus_heal = min(lurker_stalker.heartbites, lurker_stalker.max_heartbite_bonus)
	new /datum/effects/heal_over_time(xeno, regeneration + bonus_heal, 2)
	xeno.SetSleeping(3)
	sleep_timer = addtimer(CALLBACK(src, PROC_REF(sleep_check)), 2 SECONDS, TIMER_STOPPABLE|TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_NO_HASH_WAIT)

/datum/action/xeno_action/onclick/hibernate/proc/bad_wake_up(user, damage_data = null)
	SIGNAL_HANDLER

	if(damage_data && damage_data["damage"] < 0) //ignore "negative" dmg
		return

	var/mob/living/carbon/xenomorph/xeno = owner
	xeno.visible_message(SPAN_XENONOTICE("[xeno]'s hibernation was interrupted, it looks distressed."),
		SPAN_WARNING("Our hibernation was interrupted!"))
	xeno.remove_filter("sleep_on")
	xeno.SetSleeping(0)
	xeno.KnockDown(0.5)
	xeno.Superslow(1.5)
	xeno.Slow(3.5)
	UnregisterSignal(xeno, COMSIG_XENO_TAKE_DAMAGE)
	if(sleep_timer)
		deltimer(sleep_timer)
		sleep_timer = null
	apply_cooldown()
	button.icon_state = "template"
	xeno.update_icons()

/datum/action/xeno_action/onclick/heartbite/use_ability()
	var/mob/living/carbon/xenomorph/xeno = owner

	var/datum/behavior_delegate/lurker_stalker/stalk = xeno.behavior_delegate
	if(!stalk.nail_target_ref)
		to_chat(xeno, SPAN_XENOWARNING("We can only heartbite someone we nailed to the ground."))
		return

	var/mob/living/target = stalk.nail_target_ref.resolve()

	var/mob/living/carbon/target_carbon = target

	if(xeno.can_not_harm(target_carbon))
		return

	if(!(HAS_TRAIT(target_carbon, TRAIT_KNOCKEDOUT) || target_carbon.stat == UNCONSCIOUS)) //called knocked out because for some reason .stat seems to have a delay .
		to_chat(xeno, SPAN_XENOHIGHDANGER("We can only heartbite an unconscious target!"))
		return

	if(xeno.loc != target_carbon.loc)
		return

	if(xeno.stat == UNCONSCIOUS)
		return

	if(xeno.stat == DEAD)
		return

	if(xeno.action_busy)
		return

	if(target_carbon.status_flags & XENO_HOST)
		for(var/obj/item/alien_embryo/embryo in target_carbon)
			if(HIVE_ALLIED_TO_HIVE(xeno.hivenumber, embryo.hivenumber))
				to_chat(xeno, SPAN_WARNING("We should not harm this host! It has a sister inside."))
				return

	xeno.visible_message(SPAN_DANGER("[xeno] grabs [target_carbon]’s aggressively."),
		SPAN_XENOWARNING("We grab [target_carbon]’s aggressively."))
	target_carbon.apply_status_effect(/datum/status_effect/incapacitating/nailed, 2 SECONDS) //make sure they won't get up, would be awkward
	xeno.emote("growl")
	if(!do_after(xeno, 1.5 SECONDS, INTERRUPT_NO_NEEDHAND, BUSY_ICON_HOSTILE, numticks = 2))
		return

	// To make sure that the headbite does nothing if the target is moved away.
	if(xeno.loc != target_carbon.loc)
		to_chat(xeno, SPAN_XENOHIGHDANGER("We missed! Our target was moved away before we could finish heartbiting them!"))
		return

	if(target_carbon.stat == DEAD)
		to_chat(xeno, SPAN_XENODANGER("They died before we could finish heartbiting them!"))
		return

	playsound(target_carbon,'sound/weapons/alien_bite2.ogg', 50, TRUE)
	xeno.visible_message(SPAN_DANGER("[xeno] pierces [target_carbon]’s chest with its inner jaw!"),
		SPAN_XENOHIGHDANGER("We pierce [target_carbon]’s chest with our inner jaw!"))
	xeno.flick_attack_overlay(target_carbon, "headbite")
	xeno.animation_attack_on(target_carbon, pixel_offset = 16)
	target_carbon.apply_armoured_damage(60, ARMOR_MELEE, BRUTE, "chest", 5) //DIE
	target_carbon.death(create_cause_data("heartbite execution", xeno), FALSE)
	if(ishuman(target_carbon))
		var/mob/living/carbon/human/target_human = target_carbon
		target_human.revive_grace_period -= 2 MINUTES
	log_attack("[key_name(xeno)] was executed by [key_name(target_carbon)] with a heartbite!")
	reward()
	return ..()

/datum/action/xeno_action/onclick/heartbite/proc/reward()
	var/mob/living/carbon/xenomorph/xeno = owner
	var/datum/action/xeno_action/onclick/lurker_stalking/lurker_invis = get_action(xeno, /datum/action/xeno_action/onclick/lurker_stalking)
	if(lurker_invis)
		lurker_invis.apply_cooldown_override(0)
	var/datum/action/xeno_action/onclick/echolocation/echolocation = get_action(xeno, /datum/action/xeno_action/onclick/echolocation)
	if(echolocation)
		echolocation.apply_cooldown_override(0)
	var/datum/action/xeno_action/onclick/hibernate/hibernate = get_action(xeno, /datum/action/xeno_action/onclick/hibernate)
	if(hibernate)
		hibernate.apply_cooldown_override(0)
	var/datum/behavior_delegate/lurker_stalker/lurker_stalker = xeno.behavior_delegate
	lurker_stalker.heartbites++

/mob/living/carbon/human/proc/temp_set_grace_period(grace_period)
	revive_grace_period = grace_period
	RegisterSignal(src, COMSIG_HUMAN_REVIVED, PROC_REF(reset_grace_period))

/mob/living/carbon/human/proc/reset_grace_period()
	SIGNAL_HANDLER
	UnregisterSignal(src, COMSIG_HUMAN_REVIVED)
	revive_grace_period = initial(revive_grace_period)

/datum/behavior_delegate/lurker_stalker
	name = "Lurker Stalker Behavior Delegate"

	var/datum/weakref/lash_target_ref = null //who are we targeting with the lash ability, used to strike them even if we didn't land exactly on top of them
	var/datum/weakref/nail_target_ref = null
	var/turf/lash_initial_turf = null

	var/invis_start_time = -1 // Special value for when we're not invisible
	var/heartbites = 0
	var/max_heartbite_bonus = 10

/datum/behavior_delegate/lurker_stalker/append_to_stat()
	. = list()
	. += "Hearts bitten: [heartbites]/[max_heartbite_bonus]"

/datum/behavior_delegate/lurker_stalker/melee_attack_additional_effects_self()
	..()

	var/datum/action/xeno_action/onclick/lurker_stalking/lurker_invis_action = get_action(bound_xeno, /datum/action/xeno_action/onclick/lurker_stalking)
	if (lurker_invis_action)
		lurker_invis_action.invisibility_off()

/datum/behavior_delegate/lurker_stalker/proc/decloak_handler(mob/source)
	SIGNAL_HANDLER
	var/datum/action/xeno_action/onclick/lurker_stalking/lurker_invis_action = get_action(bound_xeno, /datum/action/xeno_action/onclick/lurker_stalking)
	if(istype(lurker_invis_action))
		lurker_invis_action.invisibility_off() // Partial refund of remaining time

/// Implementation for enabling invisibility.
/datum/behavior_delegate/lurker_stalker/proc/on_invisibility()
	var/datum/action/xeno_action/activable/pounce/lash/lurker_pounce_action = get_action(bound_xeno, /datum/action/xeno_action/activable/pounce/lash)
	if(lurker_pounce_action)
		lurker_pounce_action.knockdown = TRUE // pounce knocks down
		lurker_pounce_action.freeze_self = TRUE
	ADD_TRAIT(bound_xeno, TRAIT_CLOAKED, TRAIT_SOURCE_ABILITY("cloak"))
	RegisterSignal(bound_xeno, COMSIG_MOB_EFFECT_CLOAK_CANCEL, PROC_REF(decloak_handler))
	bound_xeno.stealth = TRUE

/// Implementation for disabling invisibility.
/datum/behavior_delegate/lurker_stalker/proc/on_invisibility_off()
	var/datum/action/xeno_action/activable/pounce/lash/lurker_pounce_action = get_action(bound_xeno, /datum/action/xeno_action/activable/pounce/lash)
	if(lurker_pounce_action)
		lurker_pounce_action.knockdown = FALSE // pounce no longer knocks down
		lurker_pounce_action.freeze_self = FALSE
	bound_xeno.stealth = FALSE
	REMOVE_TRAIT(bound_xeno, TRAIT_CLOAKED, TRAIT_SOURCE_ABILITY("cloak"))
	UnregisterSignal(bound_xeno, COMSIG_MOB_EFFECT_CLOAK_CANCEL)

/datum/behavior_delegate/lurker_stalker/proc/add_nailed(mob/living/carbon/target, duration)
	nail_target_ref = WEAKREF(target)
	RegisterSignal(target, COMSIG_MOVABLE_MOVED, PROC_REF(remove_nailed))
	RegisterSignal(target, COMSIG_LIVING_SET_BODY_POSITION, PROC_REF(remove_nailed))
	RegisterSignal(bound_xeno, COMSIG_MOVABLE_MOVED, PROC_REF(remove_nailed))
	RegisterSignal(bound_xeno, COMSIG_PARENT_QDELETING, PROC_REF(remove_nailed))
	ADD_TRAIT(target, TRAIT_NAILED, TRAIT_SOURCE_ABILITY("Pounce"))
	target.apply_status_effect(/datum/status_effect/incapacitating/nailed, duration)
	if(ishuman(target))
		var/mob/living/carbon/human/human_target = target
		human_target.update_xeno_hostile_hud()

/datum/behavior_delegate/lurker_stalker/proc/remove_nailed()
	SIGNAL_HANDLER

	to_chat(world, "test9999")
	UnregisterSignal(bound_xeno, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
	if(!nail_target_ref)
		return
	var/mob/living/target = nail_target_ref.resolve()
	nail_target_ref = null
	if(!target)
		return
	UnregisterSignal(target, list(COMSIG_MOVABLE_MOVED, COMSIG_LIVING_SET_BODY_POSITION))
	REMOVE_TRAIT(target, TRAIT_NAILED, TRAIT_SOURCE_ABILITY("Pounce"))
	to_chat(world, "test1234")
	var/datum/status_effect/incapacitating/nailed/nailed = target.has_status_effect(/datum/status_effect/incapacitating/nailed)
	var/mob/living/carbon/human/human_target = target
	if(!nailed)
		if(istype(human_target))
			to_chat(world, "test12345 [HAS_TRAIT(target, TRAIT_NAILED)] [GET_TRAIT_SOURCES(target, TRAIT_NAILED)]")
			human_target.update_xeno_hostile_hud()
		return
	to_chat(world, "1test9999 [timeleft(nailed.timerid) / 10]")
	var/stunleft = 0.5
	if(nailed.timerid) //timer might be not even initialized if we move away to fast
		stunleft = timeleft(nailed.timerid) / 10
	target.KnockDown(min(stunleft, 0.5))
	target.remove_status_effect(/datum/status_effect/incapacitating/nailed)
	if(istype(human_target))
		human_target.update_xeno_hostile_hud()
