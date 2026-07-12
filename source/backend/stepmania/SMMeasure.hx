package backend.stepmania;

class SMMeasure {
	public var noteRows:Array<String> = [];
	
	public function new(rows:Array<String>) {
		for (row in rows) {
			var trimmed = row.trim();
			if (trimmed.length > 0 && !trimmed.startsWith('//')) {
				noteRows.push(trimmed);
			}
		}
	}
	
	public function getSubdivisions():Int {
		return noteRows.length;
	}
	
	public function hasNotes():Bool {
		for (row in noteRows) {
			for (i in 0...row.length) {
				var char = row.charAt(i);
				if (char != '0' && char != 'M') {
					return true;
				}
			}
		}
		return false;
	}
}
