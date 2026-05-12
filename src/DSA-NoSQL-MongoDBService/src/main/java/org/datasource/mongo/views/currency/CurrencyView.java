package org.datasource.mongo.views.currency;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data @AllArgsConstructor @NoArgsConstructor(force = true)
@JsonIgnoreProperties({"_id"})
public class CurrencyView {
	private String currencyCode;
	private String currencyName;
	private Double exchangeRate;
	private String region;
	private String symbol;
	private String baseCurrency;
	private String extractionDate;
}
