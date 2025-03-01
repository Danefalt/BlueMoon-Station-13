#define ABDUCTOR_MAX_TEAMS 4

/datum/antagonist/abductor
	name = "Abductor"
	roundend_category = "abductors"
	antagpanel_category = "Abductor"
	job_rank = ROLE_ABDUCTOR
	show_in_antagpanel = FALSE //should only show subtypes
	threat = 5
	show_to_ghosts = TRUE
	var/datum/team/abductor_team/team
	var/sub_role
	var/outfit
	var/landmark_type
	var/greet_text


/datum/antagonist/abductor/agent
	name = "Abductor Agent"
	sub_role = "Agent"
	outfit = /datum/outfit/abductor/agent
	landmark_type = /obj/effect/landmark/abductor/agent
	greet_text = "Use your stealth technology and equipment to incapacitate humans for your scientist to retrieve."
	show_in_antagpanel = TRUE
	skill_modifiers = list(/datum/skill_modifier/job/level/wiring)

/datum/antagonist/abductor/scientist
	name = "Abductor Scientist"
	sub_role = "Scientist"
	outfit = /datum/outfit/abductor/scientist
	landmark_type = /obj/effect/landmark/abductor/scientist
	greet_text = "Use your experimental console and surgical equipment to monitor your agent and experiment upon abducted humans."
	show_in_antagpanel = TRUE
	skill_modifiers = list(/datum/skill_modifier/job/affinity/surgery)

/datum/antagonist/abductor/create_team(datum/team/abductor_team/new_team)
	if(!new_team)
		return
	if(!istype(new_team))
		stack_trace("Wrong team type passed to [type] initialization.")
	team = new_team

/datum/antagonist/abductor/get_team()
	return team

/datum/antagonist/abductor/on_gain()
	owner.special_role = "[name]"
	owner.assigned_role = "[name]"
	objectives += team.objectives
	finalize_abductor()
	ADD_TRAIT(owner, TRAIT_ABDUCTOR_TRAINING, ABDUCTOR_ANTAGONIST)
	return ..()

/datum/antagonist/abductor/on_removal()
	if(owner.current)
		to_chat(owner.current,"<span class='userdanger'>You are no longer the [owner.special_role]!</span>")
	owner.special_role = null
	REMOVE_TRAIT(owner, TRAIT_ABDUCTOR_TRAINING, ABDUCTOR_ANTAGONIST)
	return ..()

/datum/antagonist/abductor/greet()
	to_chat(owner.current, "<span class='notice'>You are the [owner.special_role]!</span>")
	to_chat(owner.current, "<span class='notice'>You are an operative for your home planet's government. Your mission is to detain, experiment, and observe.</span>")
	to_chat(owner.current, "<span class='notice'>Work together with your teammate to bring live subjects from the space station nearby onto your ship for experimentation.</span>")
	to_chat(owner.current, "<span class='notice'>For the sake of the mission, do not damage the integrity of the station, do not kill anyone unless in self defense, always capture specimens first if you can, and do not steal equipment or belongings from abducted specimens.</span>")
	to_chat(owner.current, "<span class='notice'>Your task is to observe and take notes of the effects of your experiments.</span>")
	to_chat(owner.current, "<span class='notice'>[greet_text]</span>")
	owner.announce_objectives()

/datum/antagonist/abductor/proc/finalize_abductor()
	//Equip
	var/mob/living/carbon/human/H = owner.current
	H.set_species(/datum/species/abductor)
	var/obj/item/organ/tongue/abductor/T = H.getorganslot(ORGAN_SLOT_TONGUE)
	T.mothership = "[team.name]"

	H.real_name = "[team.name] [sub_role]"
	H.equipOutfit(outfit)

	//Teleport to ship
	for(var/obj/effect/landmark/abductor/LM in GLOB.landmarks_list)
		if(istype(LM, landmark_type) && LM.team_number == team.team_number)
			H.forceMove(LM.loc)
			break

	update_abductor_icons_added(owner,"abductor")

/datum/antagonist/abductor/scientist/on_gain()
	ADD_TRAIT(owner, TRAIT_ABDUCTOR_SCIENTIST_TRAINING, ABDUCTOR_ANTAGONIST)
	ADD_TRAIT(owner, TRAIT_SURGEON, ABDUCTOR_ANTAGONIST)
	. = ..()

/datum/antagonist/abductor/scientist/on_removal()
	REMOVE_TRAIT(owner, TRAIT_ABDUCTOR_SCIENTIST_TRAINING, ABDUCTOR_ANTAGONIST)
	REMOVE_TRAIT(owner, TRAIT_SURGEON, ABDUCTOR_ANTAGONIST)
	. = ..()

/datum/antagonist/abductor/admin_add(datum/mind/new_owner,mob/admin)
	var/list/current_teams = list()
	for(var/datum/team/abductor_team/T in GLOB.antagonist_teams)
		current_teams[T.name] = T
	var/choice = input(admin,"Add to which team ?") as null|anything in (current_teams + "new team")
	if (choice == "new team")
		team = new
	else if(choice in current_teams)
		team = current_teams[choice]
	else
		return
	new_owner.add_antag_datum(src)
	log_admin("[key_name(usr)] made [key_name(new_owner)] [name] on [choice]!")
	message_admins("[key_name_admin(usr)] made [key_name_admin(new_owner)] [name] on [choice] !")

/datum/antagonist/abductor/get_admin_commands()
	. = ..()
	.["Equip"] = CALLBACK(src,.proc/admin_equip)

/datum/antagonist/abductor/proc/admin_equip(mob/admin)
	if(!ishuman(owner.current))
		to_chat(admin, "<span class='warning'>This only works on humans!</span>")
		return
	var/mob/living/carbon/human/H = owner.current
	var/gear = alert(admin,"Agent or Scientist Gear","Gear","Agent","Scientist")
	if(gear)
		if(gear=="Agent")
			H.equipOutfit(/datum/outfit/abductor/agent)
		else
			H.equipOutfit(/datum/outfit/abductor/scientist)

/datum/team/abductor_team
	member_name = "abductor"
	var/team_number
	var/list/datum/mind/abductees = list()
	var/static/team_count = 1

/datum/team/abductor_team/New()
	..()
	team_number = team_count++
	name = "Mothership [pick(GLOB.possible_changeling_IDs)]" //TODO Ensure unique and actual alieny names
	add_objective(new/datum/objective/experiment)

/datum/team/abductor_team/is_solo()
	return FALSE

/datum/team/abductor_team/proc/add_objective(datum/objective/O)
	O.team = src
	O.update_explanation_text()
	objectives += O

/datum/team/abductor_team/roundend_report()
	var/list/result = list()

	var/won = TRUE
	for(var/datum/objective/O in objectives)
		if(!O.check_completion())
			won = FALSE
	if(won)
		result += "<span class='greentext big'>[name] team fulfilled its mission!</span>"
	else
		result += "<span class='redtext big'>[name] team failed its mission.</span>"

	result += "<span class='header'>The abductors of [name] were:</span>"
	for(var/datum/mind/abductor_mind in members)
		result += printplayer(abductor_mind)
	result += printobjectives(objectives)

	return "<div class='panel redborder'>[result.Join("<br>")]</div>"

// LANDMARKS
/obj/effect/landmark/abductor
	var/team_number = 1

/obj/effect/landmark/abductor/agent
	icon_state = "abductor_agent"
/obj/effect/landmark/abductor/scientist
	icon_state = "abductor"

// OBJECTIVES
/datum/objective/experiment
	target_amount = 6

/datum/objective/experiment/New()
	explanation_text = "Проведите эксперименты над репродуктивной системой [target_amount] сотрудников Космической Станции. Быть может, нас заинтересуют и иные органы! Отталкиваемся от ситуации."

/datum/objective/experiment/check_completion()
	for(var/obj/machinery/abductor/experiment/E in GLOB.machines)
		if(!istype(team, /datum/team/abductor_team))
			return FALSE
		var/datum/team/abductor_team/T = team
		if(E.team_number == T.team_number)
			return E.points >= target_amount
	return FALSE

/datum/antagonist/proc/update_abductor_icons_added(datum/mind/alien_mind,hud_type)
	var/datum/atom_hud/antag/hud = GLOB.huds[ANTAG_HUD_ABDUCTOR]
	hud.join_hud(alien_mind.current)
	set_antag_hud(alien_mind.current, hud_type)

/datum/antagonist/proc/update_abductor_icons_removed(datum/mind/alien_mind)
	var/datum/atom_hud/antag/hud = GLOB.huds[ANTAG_HUD_ABDUCTOR]
	hud.leave_hud(alien_mind.current)
	set_antag_hud(alien_mind.current, null)
