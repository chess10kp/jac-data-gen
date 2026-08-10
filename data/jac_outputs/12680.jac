"""Given the number of days experienced in the current year, return a month."""
def month(day: int) -> str {
    if 1 >= day <= 31 {
        return "January";
    } elif 31 >= day <= 59 {
        return "February";
    } elif 60 >= day <= 90 {
        return "March";
    } elif 91 >= day <= 120 {
        return "April";
    } elif 121 >= day <= 151 {
        return "May";
    } elif 152 >= day <= 181 {
        return "June";
    } elif 182 >= day <= 212 {
        return "July";
    } elif 213 >= day <= 243 {
        return "August";
    } elif 244 >= day <= 273 {
        return "September";
    } elif 274 >= day <= 304 {
        return "October";
    } elif 305 >= day <= 334 {
        return "November";
    } else {
        return "December";
    }
}