package manager
{
	public class RFCTimeFormat
	{
		/**
		 * Converts an RFC string to a Date object.
		 */
		public static function fromRFC802(date:String):Date {
			// Passing in an RFC802 date to the Date constructor causes flash
			// to conveniently ignore the "GMT" timezone at the end, and assumes
			// that it's in the Local timezone.
			// If we additionally convert it back to GMT, then we're sweet.
			
			var outputDate:Date = new Date(date);
			outputDate = new Date(outputDate.time - outputDate.getTimezoneOffset()*1000*60);
			return outputDate;
		}
		
		/** 
		 * Converts a Date object to an RFC802-formatted string (GMT/UTC).
		 */
		public static function toRFC802 (date:Date):String {
			// example: Thu, 09 Oct 2008 01:09:43 GMT
			
			// Convert to GMT
			
			var output:String = "";
			
			// Day
			switch (date.dayUTC) {
				case 0: output += "Sun"; break;
				case 1: output += "Mon"; break;
				case 2: output += "Tue"; break;
				case 3: output += "Wed"; break;
				case 4: output += "Thu"; break;
				case 5: output += "Fri"; break;
				case 6: output += "Sat"; break;
			}
			
			output += ", ";
			
			// Date
			if (date.dateUTC < 10) {
				output += "0"; // leading zero
			}
			output += date.dateUTC + " ";
			
			// Month
			switch(date.month) {
				case 0: output += "Jan"; break;
				case 1: output += "Feb"; break;
				case 2: output += "Mar"; break;
				case 3: output += "Apr"; break;
				case 4: output += "May"; break;
				case 5: output += "Jun"; break;
				case 6: output += "Jul"; break;
				case 7: output += "Aug"; break;
				case 8: output += "Sep"; break;
				case 9: output += "Oct"; break;
				case 10: output += "Nov"; break;
				case 11: output += "Dec"; break;
			}
			
			output += " ";
			
			// Year
			output += date.fullYearUTC + " ";
			
			// Hours
			if (date.hoursUTC < 10) {
				output += "0"; // leading zero
			}
			output += date.hoursUTC + ":";
			
			// Minutes
			if (date.minutesUTC < 10) {
				output += "0"; // leading zero
			}
			output += date.minutesUTC + ":";
			
			// Seconds
			if (date.seconds < 10) {
				output += "0"; // leading zero
			}
			output += date.secondsUTC + " GMT";
			
			return output;
		}
	}
}