package org.datasource.csv.views.period;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data @AllArgsConstructor @NoArgsConstructor(force = true)
public class PeriodView {
	private String periodDate;
	private Integer year;
	private Integer month;
	private Integer day;
	private Integer quarter;
	private String season;
	private String isHighSeason;
}
