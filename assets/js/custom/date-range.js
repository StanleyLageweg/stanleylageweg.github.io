jQuery(function() {

function updateDateRangeDurations() {
	const nodes = document.querySelectorAll(".date-range-duration");

	for (const node of nodes) {
		const fromString = node.getAttribute("date-range-from");
		const toString = node.getAttribute("date-range-to");

		const fromDate = new Date(fromString);
		const toDate = (() => {
			if (toString === "Present") {
				return new Date();
			}

			// Use the first day of the next month, as we assume that the duration will have lasted the full month
			const date = new Date(toString);
				return new Date(date.getFullYear(), date.getMonth() + 1, 1);
		})();

		if (isNaN(fromDate)) {
			console.error("date-range.js: invalid from date:", fromString);
			continue;
		}
		if (isNaN(toDate)) {
			console.error("date-range.js: invalid to date:", toString);
			continue;
		}

		if (fromDate > toDate) {
			console.error("date-range.js: from date is after to date:", fromString, toString);
			continue;
		}

		const fromMonths = fromDate.getFullYear() * 12 + fromDate.getMonth();
		const toMonths = toDate.getFullYear() * 12 + toDate.getMonth();
		const totalMonths = toMonths - fromMonths;
		const years = Math.floor(totalMonths / 12);
		const months = totalMonths % 12;

		if (years < 0 && months < 0) {
			continue;
		}

		let text = "";
		if (years > 0) {
			text += years + " year" + (years !== 1 ? "s" : "");
		}
		if (months > 0) {
			if (text.length > 0) {
				text += " ";
			}
			text += months + " month" + (months !== 1 ? "s" : "");
		}
		node.textContent = "· " + text;
	}
}
updateDateRangeDurations();
});
