/datum/round_event_control/electrical_storm
	name = "Electrical Storm"
	typepath = /datum/round_event/electrical_storm
	earliest_start = 20 MINUTES
	min_players = 25
	weight = 25
	max_occurrences = 2
	alert_observers = FALSE

/datum/round_event/electrical_storm
	var/lightsoutAmount	= 1
	var/lightsoutRange	= 25
	announceWhen	= 1

/datum/round_event/electrical_storm/announce(fake)
	if(prob(50))
		priority_announce("An electrical storm has been detected in your area, please repair potential electronic overloads.", "Electrical Storm Alert")
	else
		print_command_report("An electrical storm has been detected in your area, please repair potential electronic overloads.", "Electrical Storm")

/datum/round_event/electrical_storm/start()
	var/list/epicentreList = list()

	for(var/i=1, i <= lightsoutAmount, i++)
		var/turf/T = find_safe_turf()
		if(istype(T))
			epicentreList += T

	if(!epicentreList.len)
		return

	for(var/centre in epicentreList)
		for(var/a in GLOB.apcs_list)
			var/obj/machinery/power/apc/A = a
			if(get_dist(centre, A) <= lightsoutRange)
				A.overload_lighting()
