package org.datasource;

import org.datasource.mongo.views.booking.MongoBookingView;
import org.datasource.mongo.views.booking.MongoBookingViewBuilder;
import org.datasource.mongo.views.currency.CurrencyView;
import org.datasource.mongo.views.currency.CurrencyViewBuilder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.logging.Logger;

/*	REST Service URL
	http://localhost:8093/DSA-NoSQL-MongoDBService/rest/mongodb/MongoBookingView
	http://localhost:8093/DSA-NoSQL-MongoDBService/rest/mongodb/CurrencyView
*/
@RestController
@RequestMapping("/mongodb")
public class RESTViewServiceMongoDB {
	private static Logger logger = Logger.getLogger(RESTViewServiceMongoDB.class.getName());

	@RequestMapping(value = "/ping", method = RequestMethod.GET,
			produces = {MediaType.TEXT_PLAIN_VALUE})
	@ResponseBody
	public String pingDataSource() {
		logger.info(">>>> DSA-NoSQL-MongoDBService:: RESTViewService is Up!");
		return "Ping response from DSA-NoSQL-MongoDBService!";
	}

	@RequestMapping(value = "/MongoBookingView", method = RequestMethod.GET,
			produces = {MediaType.APPLICATION_JSON_VALUE, MediaType.APPLICATION_XML_VALUE})
	@ResponseBody
	public List<MongoBookingView> get_MongoBookingView() {
		return this.mongoBookingViewBuilder.build().getViewList();
	}

	@RequestMapping(value = "/CurrencyView", method = RequestMethod.GET,
			produces = {MediaType.APPLICATION_JSON_VALUE, MediaType.APPLICATION_XML_VALUE})
	@ResponseBody
	public List<CurrencyView> get_CurrencyView() {
		return this.currencyViewBuilder.build().getViewList();
	}

	// Set-up
	@Autowired private MongoBookingViewBuilder mongoBookingViewBuilder;
	@Autowired private CurrencyViewBuilder currencyViewBuilder;
}
