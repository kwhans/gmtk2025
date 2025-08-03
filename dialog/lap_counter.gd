extends MarginContainer
class_name LapCounter

func updateLabel(lapsComplete:int, totalLaps:int):
	$LapCountLabel.text = "Laps Completed: " + str(lapsComplete) + " / " + str(totalLaps)
	
