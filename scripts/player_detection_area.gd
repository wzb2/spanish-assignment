extends Area3D

class_name PlayerDetectionArea

func all_players_in_area() -> bool:
	for p: Player in MultiplayerManager.players.values():
		if not get_overlapping_bodies().has(p.root_bone):
			return false
	return true
