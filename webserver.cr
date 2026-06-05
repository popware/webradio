require "http/server"

HOST = "192.168.4.140" # local webserver
PORT = 8080
FILESTATIONS = "stations.txt"
FILESTYLES = "styles.css"
FILELASTSTATION = "laststation.txt"
FILELIKES = "likes.txt"
DEBUG = 1

# Struct to hold station information with likes count
class CStation
  property name : String
  property likes : Int32 = 0
 
  def initialize(@name : String)
  end

  def inc_likes
    @likes += 1
    puts "Likes inc to #{@likes}" if DEBUG > 2
    return @likes
  end

  def dec_likes
    @likes -= 1 if @likes > 0
    puts "Likes dec to #{@likes}" if DEBUG > 2
    return @likes
  end

  def get_likes
    puts "Likes got #{@likes} for #{@name}" if DEBUG > 2
    return @likes
  end

  def set_likes(lik : Int32)
    @likes = lik
    puts "Likes set to #{@likes}" if DEBUG > 2
    get_likes
    return @likes
  end

  def get_name
    return @name
  end
end

class CAllStations
  @@allstations = [] of CStation

  def number_of_stations
    return @@allstations.size
  end

  def get_station(index : Int32)
    if index > (number_of_stations - 1)
      return @@allstations[-1]
    else
      return @@allstations[index]
    end
  end

  # Load station data from stations.txt and likes.txt
  def load_stations
    index = 0
    #load data from stations.txt
    File.each_line(FILESTATIONS) do |line|
      station_name = line.strip
      # Pass the station name to the initializer
      station = CStation.new(station_name)
      puts "load_stations: INX=#{index} STN=#{station}" if DEBUG > 2
      @@allstations << station
      index += 1
    end
    p @@allstations if DEBUG > 2
    load_likes
  end

  # Show like data from stations
  def show_stations
    number_of_stations.times do |index|
      sel = index + 1
      station = get_station(index)
      puts "show_stations: SEL=#{sel} LIK=#{station.get_likes}" if DEBUG > 2
    end
  end

  # Load like data from likes.txt
  def load_likes
    if File.exists?(FILELIKES)
      File.each_line(FILELIKES) do |line|
        parts = line.strip.split(":")
        if parts.size == 2
          sel = parts[0].to_i
          lik = parts[1].to_i
          puts "load_likes: SEL=#{sel} LIK=#{lik}" if DEBUG > 2
          if (sel > 0) && (sel <= number_of_stations)
              index = sel - 1
              @@allstations[index].set_likes(lik)
              p @@allstations[index] if DEBUG > 2
          end
        end
      end
    end
    # show loaded
    p @@allstations if DEBUG > 2
  end

  # Save like data to likes.txt
  def save_likes
    begin
      File.open(FILELIKES, "w") do |file|
        number_of_stations.times do |index|
          sel = index + 1
          station = get_station(index)
          file.puts "#{sel}:#{station.get_likes}"
          puts "save_likes: SEL=#{sel} LIK=#{station.get_likes}" if DEBUG > 2
        end
      end
    rescue
      puts "Error saving likes data"
    end
  end

end

def load_last_station : Int32
  last_station = 0 # default if not found
  if File.exists?(FILELASTSTATION)
    last_station_str = File.read(FILELASTSTATION).strip
    last_station = last_station_str.to_i
  end
  return last_station
end

def playselected(sel : Int32, last : Int32, stations : CAllStations) : Int32
  sel = last if sel < 1
  sel = 1 if sel > last
  index = sel - 1
  station = stations.get_station(index)
  system "/usr/local/bin/radioplay.sh #{station.get_name}"
  puts "Play[#{sel}] #{station.get_name}" if DEBUG > 0
  File.write(FILELASTSTATION, sel.to_s) # save selected station
  return sel
end

def buttons(context : HTTP::Server::Context)
  context.response.print "<div class=\"button-group\">"
  context.response.print "<button onclick=\"document.location='stop'\">Stop</button>"
  context.response.print "<button onclick=\"document.location='soft'\">Soft</button>"
  context.response.print "<button onclick=\"document.location='normal'\">Normal</button>"
  context.response.print "<button onclick=\"document.location='loud'\">Loud</button>"
  context.response.print "<button onclick=\"document.location='prev'\">&lt;</button>" #[<]
  context.response.print "<button onclick=\"document.location='next'\">&gt;</button>" #[>]
  context.response.print "<button onclick=\"document.location='like'\">Like</button>"
  context.response.print "<button onclick=\"document.location='unlike'\">Unlike</button>"
  context.response.print "</div>"
end

def likes_to_stars(likes : Int32) : String
  "* " * likes
end

def homepage(context : HTTP::Server::Context, selected_index : Int32, stations : CAllStations, auto_refresh : Bool = false)
  puts "HOME[" if DEBUG > 1
  stations.show_stations
  context.response.content_type = "text/html"
  context.response.print "<html><head><style>"
  File.each_line(FILESTYLES) do |line|
    context.response.print line
  end
  # Add meta refresh tag if auto_refresh is true
  if auto_refresh
      context.response.print "<meta http-equiv=\"refresh\" content=\"1\">"
  end
  context.response.print "</style></head><body>"
  buttons(context)
  context.response.print "<table border='1'><tr><th style='width:30px'>Select</th><th style='width:60px; text-align:center'>Likes</th><th>Station</th></tr>"
  stations.number_of_stations.times do |index|
    sel = index + 1
    station = stations.get_station(index)
    marker1 = (sel == selected_index ? "[ " : "")
    marker2 = (sel == selected_index ? " ]" : "")
    # Optional: add class for the selected row
    row_class = (sel == selected_index) ? " class='selected'" : ""
    context.response.print "<tr#{row_class}>"
    context.response.print "<td style='width:30px; text-align:center'>#{marker1}#{sel}#{marker2}</td>"
    context.response.print "<td style='width:60px; text-align:center'> #{likes_to_stars(station.get_likes)}</td>"
    context.response.print "<td><a href='/play#{sel}'>#{station.get_name}</a></td>"
    context.response.print "</tr>"
  end
  context.response.print "</table>"
  buttons(context)
  context.response.print "<br><a href='/'>Back to Home</a></body>"
  context.response.print "</html>"
  puts "HOME]" if DEBUG > 1
end

def main
  puts "MAIN[" if DEBUG > 1
  myStations = CAllStations.new
  selected = 0 # default if no station selected

  # Load the stations array before loading the last station
  myStations.load_stations
  laststation = myStations.number_of_stations
  selected = load_last_station
  selected = 1 if  (selected < 1) || (selected > laststation) # select 1st if invalid
  myStations.show_stations

  puts "SERVER[" if DEBUG > 1
  server = HTTP::Server.new do |context|
    command = context.request.resource
    puts command
    case command
      when "/"       
        playselected(selected, laststation, myStations)
        homepage(context, selected, myStations)
        next
     when "/stop"
        system "/usr/local/bin/vstop.sh"
        homepage(context, selected, myStations)
        next
      when "/soft"
        system "/usr/local/bin/vsoft.sh"
        homepage(context, selected, myStations)
        next
      when "/normal"
        system "/usr/local/bin/vnormal.sh"
        homepage(context, selected, myStations)
        next
      when "/loud"
        system "/usr/local/bin/vloud.sh"
        homepage(context, selected, myStations)
        next
      when "/prev"
        selected -= 1
        selected = playselected(selected, laststation, myStations)
        puts "[<] #{selected} #{laststation}" if DEBUG > 0
        homepage(context, selected, myStations)
        next
      when "/next"
        selected += 1
        selected = playselected(selected, laststation, myStations)
        puts "[>] #{selected} #{laststation}" if DEBUG > 0
        homepage(context, selected, myStations)
        next
      when "/play1".."/play99"
        selected = command.gsub("/play", "").to_i
        selected = playselected(selected, laststation, myStations)
        puts "[P] #{selected} #{laststation}" if DEBUG > 0
        homepage(context, selected, myStations)
        next
      when "/like"
        if (selected > 0) && (selected <= laststation) # valid selection
          index = selected - 1
          station = myStations.get_station(index)
          station.inc_likes
          puts "LIKE: SEL=#{selected} STN=#{station.get_name} LIK=#{station.get_likes}" if DEBUG > 0
          myStations.save_likes
        end
        homepage(context, selected, myStations, true)
        next
      when "/unlike"
        if (selected > 0) && (selected <= laststation) # valid selection
          index = selected - 1
          station = myStations.get_station(index)
          station.dec_likes
          puts "UNLIKE: SEL=#{selected} STN=#{station.get_name} LIK=#{station.get_likes}" if DEBUG > 0
          myStations.save_likes
        end
        homepage(context, selected, myStations, true)
        next
      when "/time"
        context.response.content_type = "text/plain"
        context.response.print "The time is #{Time.local}"
      when "/favicon.ico"
        # do nothing here
        homepage(context, selected, myStations)
        next
      else
        context.response.content_type = "text/plain"
        context.response.print "Invalid URL: #{command}"
        puts "[?] #{command}" if DEBUG > 0
    end
  end
  puts "SERVER]" if DEBUG > 1
  address = server.bind_tcp(HOST, PORT)
  puts "Listening on http://#{address}"
  server.listen
  puts "MAIN]" if DEBUG > 1
end

main
