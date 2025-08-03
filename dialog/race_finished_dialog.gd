extends Control
class_name RaceFinishedDialog

signal nextRaceSignal

func _input(event: InputEvent) -> void:
	if visible == false:
		return
		
	if event.is_action_pressed("ui_accept"):
		nextRaceSignal.emit()
		
func updateLabels(totalTime:float, bestLap:int, bestTime:float, worstLap:int, worstTime:float):
	%TotalTimeLabel.text = "Total Time: " + str(totalTime) + " Sec"
	%BestLapLabel.text = "Best Lap: " + str(bestTime) + " Sec (Lap " + str(bestLap) + ")"
	%WorstLapLabel.text = "Worst Lap: " + str(worstTime) + " Sec (Lap " + str(worstLap) + ")"

func _on_next_race_button_pressed() -> void:
	nextRaceSignal.emit()
