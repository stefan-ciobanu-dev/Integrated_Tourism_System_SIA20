package org.datasource;

import org.datasource.csv.views.airline.AirlineView;
import org.datasource.csv.views.airline.AirlineViewBuilder;
import org.datasource.csv.views.flight.FlightView;
import org.datasource.csv.views.flight.FlightViewBuilder;
import org.datasource.csv.views.route.RouteView;
import org.datasource.csv.views.route.RouteViewBuilder;
import org.datasource.csv.views.hotelstars.HotelStarsView;
import org.datasource.csv.views.hotelstars.HotelStarsViewBuilder;
import org.datasource.csv.views.touristage.TouristAgeView;
import org.datasource.csv.views.touristage.TouristAgeViewBuilder;
import org.datasource.csv.views.period.PeriodView;
import org.datasource.csv.views.period.PeriodViewBuilder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.logging.Logger;

/*	REST Service URL
	http://localhost:8097/DSA-DOC-CSVService/rest/csv/AirlineView
	http://localhost:8097/DSA-DOC-CSVService/rest/csv/FlightView
	http://localhost:8097/DSA-DOC-CSVService/rest/csv/RouteView
	http://localhost:8097/DSA-DOC-CSVService/rest/csv/HotelStarsView
	http://localhost:8097/DSA-DOC-CSVService/rest/csv/TouristAgeView
	http://localhost:8097/DSA-DOC-CSVService/rest/csv/PeriodView
*/
@RestController
@RequestMapping("/csv")
public class RESTViewServiceCSV {
	private static Logger logger = Logger.getLogger(RESTViewServiceCSV.class.getName());

	@RequestMapping(value = "/ping", method = RequestMethod.GET,
			produces = {MediaType.TEXT_PLAIN_VALUE})
	@ResponseBody
	public String pingDataSource() {
		logger.info(">>>> DSA-DOC-CSVService:: RESTViewService is Up!");
		return "Ping response from DSA-DOC-CSVService!";
	}

	@RequestMapping(value = "/AirlineView", method = RequestMethod.GET,
			produces = {MediaType.APPLICATION_JSON_VALUE, MediaType.APPLICATION_XML_VALUE})
	@ResponseBody
	public List<AirlineView> get_AirlineView() {
		return this.airlineViewBuilder.build().getViewList();
	}

	@RequestMapping(value = "/FlightView", method = RequestMethod.GET,
			produces = {MediaType.APPLICATION_JSON_VALUE, MediaType.APPLICATION_XML_VALUE})
	@ResponseBody
	public List<FlightView> get_FlightView() {
		return this.flightViewBuilder.build().getViewList();
	}

	@RequestMapping(value = "/RouteView", method = RequestMethod.GET,
			produces = {MediaType.APPLICATION_JSON_VALUE, MediaType.APPLICATION_XML_VALUE})
	@ResponseBody
	public List<RouteView> get_RouteView() {
		return this.routeViewBuilder.build().getViewList();
	}

	@RequestMapping(value = "/HotelStarsView", method = RequestMethod.GET,
			produces = {MediaType.APPLICATION_JSON_VALUE, MediaType.APPLICATION_XML_VALUE})
	@ResponseBody
	public List<HotelStarsView> get_HotelStarsView() {
		return this.hotelStarsViewBuilder.build().getViewList();
	}

	@RequestMapping(value = "/TouristAgeView", method = RequestMethod.GET,
			produces = {MediaType.APPLICATION_JSON_VALUE, MediaType.APPLICATION_XML_VALUE})
	@ResponseBody
	public List<TouristAgeView> get_TouristAgeView() {
		return this.touristAgeViewBuilder.build().getViewList();
	}

	@RequestMapping(value = "/PeriodView", method = RequestMethod.GET,
			produces = {MediaType.APPLICATION_JSON_VALUE, MediaType.APPLICATION_XML_VALUE})
	@ResponseBody
	public List<PeriodView> get_PeriodView() {
		return this.periodViewBuilder.build().getViewList();
	}

	// Set-up
	@Autowired private AirlineViewBuilder airlineViewBuilder;
	@Autowired private FlightViewBuilder flightViewBuilder;
	@Autowired private RouteViewBuilder routeViewBuilder;
	@Autowired private HotelStarsViewBuilder hotelStarsViewBuilder;
	@Autowired private TouristAgeViewBuilder touristAgeViewBuilder;
	@Autowired private PeriodViewBuilder periodViewBuilder;
}
