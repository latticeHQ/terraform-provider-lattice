package helpers

import (
	"strconv"
	"strings"

	"golang.org/x/xerrors"
)

// ValidateSchedules checks that no two schedules in the slice overlap.
func ValidateSchedules(schedules []string) error {
	for i := 0; i < len(schedules); i++ {
		for j := i + 1; j < len(schedules); j++ {
			overlap, err := SchedulesOverlap(schedules[i], schedules[j])
			if err != nil {
				return xerrors.Errorf("invalid schedule: %w", err)
			}
			if overlap {
				return xerrors.Errorf("schedules overlap: %s and %s",
					schedules[i], schedules[j])
			}
		}
	}
	return nil
}

// SchedulesOverlap reports whether two 5-field cron expressions can fire at
// the same time.
func SchedulesOverlap(schedule1, schedule2 string) (bool, error) {
	fields1 := strings.Fields(schedule1)
	fields2 := strings.Fields(schedule2)

	if len(fields1) != 5 {
		return false, xerrors.Errorf("schedule %q has %d fields, expected 5 (minute hour dom month dow)", schedule1, len(fields1))
	}
	if len(fields2) != 5 {
		return false, xerrors.Errorf("schedule %q has %d fields, expected 5 (minute hour dom month dow)", schedule2, len(fields2))
	}

	monthsOverlap, err := MonthsOverlap(fields1[3], fields2[3])
	if err != nil {
		return false, xerrors.Errorf("invalid month range: %w", err)
	}
	if !monthsOverlap {
		return false, nil
	}

	daysOverlap, err := DaysOverlap(fields1[2], fields1[4], fields2[2], fields2[4])
	if err != nil {
		return false, xerrors.Errorf("invalid day range: %w", err)
	}
	if !daysOverlap {
		return false, nil
	}

	hoursOverlap, err := HoursOverlap(fields1[1], fields2[1])
	if err != nil {
		return false, xerrors.Errorf("invalid hour range: %w", err)
	}
	return hoursOverlap, nil
}

// MonthsOverlap reports whether two month cron fields overlap.
func MonthsOverlap(months1, months2 string) (bool, error) {
	return CheckOverlap(months1, months2, 12)
}

// HoursOverlap reports whether two hour cron fields overlap.
func HoursOverlap(hours1, hours2 string) (bool, error) {
	return CheckOverlap(hours1, hours2, 23)
}

// DomOverlap reports whether two day-of-month cron fields overlap.
func DomOverlap(dom1, dom2 string) (bool, error) {
	return CheckOverlap(dom1, dom2, 31)
}

// DowOverlap reports whether two day-of-week cron fields overlap.
func DowOverlap(dow1, dow2 string) (bool, error) {
	return CheckOverlap(dow1, dow2, 6)
}

// DaysOverlap reports whether the combined DOM+DOW fields of two schedules
// overlap. When either DOM is "*" only DOW is checked, and vice versa.
func DaysOverlap(dom1, dow1, dom2, dow2 string) (bool, error) {
	if dom1 == "*" || dom2 == "*" {
		return DowOverlap(dow1, dow2)
	}
	if dow1 == "*" || dow2 == "*" {
		return DomOverlap(dom1, dom2)
	}

	domOverlap, err := DomOverlap(dom1, dom2)
	if err != nil {
		return false, err
	}
	dowOverlap, err := DowOverlap(dow1, dow2)
	if err != nil {
		return false, err
	}
	return domOverlap || dowOverlap, nil
}

// CheckOverlap reports whether two cron range expressions share any value in
// [0, maxValue].
func CheckOverlap(range1, range2 string, maxValue int) (bool, error) {
	set1, err := ParseRange(range1, maxValue)
	if err != nil {
		return false, err
	}
	set2, err := ParseRange(range2, maxValue)
	if err != nil {
		return false, err
	}
	for value := range set1 {
		if set2[value] {
			return true, nil
		}
	}
	return false, nil
}

// ParseRange converts a cron range expression (e.g. "1-3,5,7-9" or "*") into
// a set of integers. maxValue is the inclusive upper bound.
func ParseRange(input string, maxValue int) (map[int]bool, error) {
	result := make(map[int]bool)

	if input == "*" {
		for i := 0; i <= maxValue; i++ {
			result[i] = true
		}
		return result, nil
	}

	for _, part := range strings.Split(input, ",") {
		if strings.Contains(part, "-") {
			rangeParts := strings.Split(part, "-")
			start, err := strconv.Atoi(rangeParts[0])
			if err != nil {
				return nil, xerrors.Errorf("invalid start value in range: %w", err)
			}
			end, err := strconv.Atoi(rangeParts[1])
			if err != nil {
				return nil, xerrors.Errorf("invalid end value in range: %w", err)
			}
			if start < 0 || end > maxValue || start > end {
				return nil, xerrors.Errorf("invalid range %d-%d: values must be between 0 and %d", start, end, maxValue)
			}
			for i := start; i <= end; i++ {
				result[i] = true
			}
		} else {
			value, err := strconv.Atoi(part)
			if err != nil {
				return nil, xerrors.Errorf("invalid value: %w", err)
			}
			if value < 0 || value > maxValue {
				return nil, xerrors.Errorf("invalid value %d: must be between 0 and %d", value, maxValue)
			}
			result[value] = true
		}
	}
	return result, nil
}
