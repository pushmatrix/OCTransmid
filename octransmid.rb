require 'OCTranspoScraper.rb'
require 'midilib/sequence'
require 'midilib/consts'
include MIDI

class OcTransmid
  
  @@note_length = 1
  @@base_note = 53
  
  def initialize
    @scraper = OCTranspoScraper.new
  end
  
  def convert( stopNumber )
    seq = Sequence.new()

    bus_arrivals = @scraper.getBusStopArrivals( stopNumber )
    bus_arrivals.each do |busNumber,arrivals|
      # Create a new MIDI track per bus route
      track = Track.new(seq)
      seq.tracks << track
      track.events << Controller.new(0, CC_VOLUME, 127)
      track.events << ProgramChange.new(0, 1, 0)

      0.upto(arrivals.size-2).each do |i|
        #time difference in seconds
        delta = arrivals[i+1] - arrivals[i]
        delta = delta.to_i
        if( delta < 0)
          delta *= -1
        end
        new_note_event( @@base_note, @@note_length, track,127, delta )
      end
    end

    # Export the file
    filename = "midiexports/stop" << stopNumber << ".mid"
    File.open(filename, 'wb') do | file |
   	  seq.write(file)
    end
  end
  
  private
  def new_note_event(note, note_length, track,velocity, delta)
    channel = 0
    track.events << NoteOnEvent.new(channel, note, velocity, delta)
    track.events << NoteOffEvent.new(channel, note, velocity, note_length)
  end
  
end

transmid = OcTransmid.new
if( ARGV.size > 0 )
  transmid.convert(ARGV[0])
end