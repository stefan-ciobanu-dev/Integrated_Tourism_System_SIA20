package org.datasource.csv.views.touristage;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data @AllArgsConstructor @NoArgsConstructor(force = true)
public class TouristAgeView {
	private Integer ageGroupId;
	private String ageRange;
	private String label;
}
