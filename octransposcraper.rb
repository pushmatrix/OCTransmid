require 'rubygems'
require 'nokogiri'
require 'open-uri'

class OCTranspoScraper
  @@base_url = "http://www.octranspo1.com/travelplanner/stop?"
  @@common_url_suffix = "&lang=en&day=20100408&rangeIndex=5&accessible=false&continue=Continue"
  @@result_limit_per_page = 5
  
  def getBusStopArrivals( stopNumber )
    bus_arrivals = {}
    url = @@base_url + "&stop=" + stopNumber + @@common_url_suffix

    group_index = 0
    done_scraping = false
    while !done_scraping
        # The OCTranspo site can only display 5 bus routes at a time per stop.
        # Therefore this gets grouping of 5 routes, and merges them together
        # until all routes for that stop have been collected.
        #
        # The group_index keeps track of which grouping of routes we
        # are currently on. 
        stop_times = getSubsetOfArrivals( stopNumber, group_index )
        bus_arrivals.merge!(stop_times)
        group_index += 1
        # If the number of results that was returned was less than the max
        # per page, that's a good indicator that we are done!
        if( stop_times.size < @@result_limit_per_page )
          done_scraping = true
        end
    end
    return bus_arrivals
  end
  
  private
  
  # OCTranspo has the times as a string under the form hh:mm(A|P)M -- ex: 12:01AM 
  # This converts it into military time, as well as stores it in a Time object.
  def formatTime( time )
     hours = 0
     minutes = 0
     time[/(\d+):(\d+)/]
     hours = $1.to_i
     minutes = $2.to_i
     if time.include? "PM"
        if( hours!=12 )
          hours += 12
        end 
     end 
     if time.include? "AM"
       if (hours == 12)
         hours = 0
       end
     end
     # The year, month and day are irrelevant. 
     return Time.local( 1, 1, 1, hours, minutes, 0)
  end

  def getSubsetOfArrivals(stopNumber, group_index)
     bus_arrivals = {}
     params = "stop=" << stopNumber
     
     # Generate the query params. 
     0.upto(@@result_limit_per_page-1).each do |i| 
       bus_index = i + group_index * @@result_limit_per_page
       params << "&check" << (bus_index).to_s << "=on"
     end
     
     url = @@base_url + params + @@common_url_suffix 
     doc = Nokogiri::HTML( open( url ) )

     0.upto(@@result_limit_per_page-1).each do |i|
       bus_index = i + group_index * @@result_limit_per_page
       list_of_times = []
       table = doc.css( "table#StopTimesTimesListTable" << i.to_s )
    	  table.css("td").each do |column|
    	    #Remove all spaces and [D]'s
    	    time = column.text.gsub(/\s|\[D\]/,"")
    	    list_of_times << formatTime( time )
  	    end
    	  if !list_of_times.empty?
    	    bus_arrivals[("bus" << bus_index.to_s).to_sym] = list_of_times
  	    end
     end
     return bus_arrivals
  end
end