package org.datasource;

import org.datasource.jpa.JPADataSourceConnector;
import org.datasource.jpa.views.tourist.TouristView;
import org.datasource.jpa.views.tourist.TouristViewBuilder;
import org.datasource.jpa.views.hotel.HotelView;
import org.datasource.jpa.views.hotel.HotelViewBuilder;
import org.datasource.jpa.views.booking.BookingView;
import org.datasource.jpa.views.booking.BookingViewBuilder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.logging.Logger;

/*	REST Service URL
	http://localhost:8090/DSA-SQL-JPAService/rest/tourism/TouristView
	http://localhost:8090/DSA-SQL-JPAService/rest/tourism/HotelView
	http://localhost:8090/DSA-SQL-JPAService/rest/tourism/BookingView
*/
@RestController
@RequestMapping("/tourism")
public class RESTViewServiceJPA {
	private static Logger logger = Logger.getLogger(RESTViewServiceJPA.class.getName());

	@RequestMapping(value = "/ping", method = RequestMethod.GET,
			produces = {MediaType.TEXT_PLAIN_VALUE})
	@ResponseBody
	public String pingDataSource() {
		logger.info(">>>> DSA-SQL-JPAService:: RESTViewService is Up!");
		return "Ping response from DSA-SQL-JPAService!";
	}

	@RequestMapping(value = "/TouristView", method = RequestMethod.GET,
			produces = {MediaType.APPLICATION_JSON_VALUE, MediaType.APPLICATION_XML_VALUE})
	@ResponseBody
	public List<TouristView> get_TouristView() {
		List<TouristView> viewList = this.touristViewBuilder.build().getViewList();
		return viewList;
	}

	@RequestMapping(value = "/HotelView", method = RequestMethod.GET,
			produces = {MediaType.APPLICATION_JSON_VALUE, MediaType.APPLICATION_XML_VALUE})
	@ResponseBody
	public List<HotelView> get_HotelView() {
		List<HotelView> viewList = this.hotelViewBuilder.build().getViewList();
		return viewList;
	}

	@RequestMapping(value = "/BookingView", method = RequestMethod.GET,
			produces = {MediaType.APPLICATION_JSON_VALUE, MediaType.APPLICATION_XML_VALUE})
	@ResponseBody
	public List<BookingView> get_BookingView() {
		List<BookingView> viewList = this.bookingViewBuilder.build().getViewList();
		return viewList;
	}

	// Set-up
	@Autowired private JPADataSourceConnector dataSourceConnector;
	@Autowired private TouristViewBuilder touristViewBuilder;
	@Autowired private HotelViewBuilder hotelViewBuilder;
	@Autowired private BookingViewBuilder bookingViewBuilder;
}
