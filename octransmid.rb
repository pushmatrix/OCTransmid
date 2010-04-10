require 'octransposcraper'
require 'midilib/sequence'
require 'midilib/consts'
require 'optparse'
include MIDI

class OCTransmid
  
  @@midi_directory = "midiexports/"
  
  def initialize ( stop_number,options )
    @scraper = OCTranspoScraper.new
    @base_note = 50
    @note_length = 1
    @stop_number = stop_number
    @seq = nil
    
    if options[:multitrack] 
      return getMultipleTrackMidiSequence
    else
      return getSingleTrackMidiSequence
    end
  end
  
  def exportToMidi
    filename = "stop" << @stop_number
    unless @seq.nil?
      File.open(@@midi_directory + filename +".mid", 'wb') do | file |
     	  @seq.write(file)
      end
    end
  end
  
  protected
  def getMultipleTrackMidiSequence
    bus_arrivals = @scraper.getBusStopArrivals( @stop_number )
    if bus_arrivals.empty?
      return 
    end
    
    @seq = Sequence.new()
    bus_arrivals.each_with_index do |arrivals,index| 
      bus_number = arrivals[0]
      arrival_times = arrivals[1]
      
      # Create a new MIDI track per bus route
      track = Track.new(@seq)
      @seq.tracks << track
      track.events << Controller.new(0, CC_VOLUME, 127)
      track.events << ProgramChange.new(0, 1, 0)

      0.upto(arrival_times.size-2).each do |i|
        #time difference in seconds
        delta = arrival_times[i+1] - arrival_times[i]
        delta = delta.to_i
        if( delta < 0)
          delta *= -1
        end
        new_note_event( @base_note + index, @note_length, track,127, delta )
        end
    end
    return @seq
  end
  
  def getSingleTrackMidiSequence
    single_track_seq = Sequence.new()
    multi_track_seq = getMultipleTrackMidiSequence
    if multi_track_seq.nil?
      return
    end
    
    track = Track.new(single_track_seq)
    
    multi_track_seq.tracks.each do |t|
     track.merge t.events
    end
    single_track_seq.tracks << track
    @seq = single_track_seq
    return @seq
  end
  
  
  def new_note_event(note, note_length, track,velocity, delta)
    channel = 0
    track.events << NoteOnEvent.new(channel, note, velocity, delta)
    track.events << NoteOffEvent.new(channel, note, velocity, note_length)
  end
  
end




# command line options
options = {}

optparse = OptionParser.new do|opts|

  # Set a banner, displayed at the top
  # of the help screen.
  opts.banner = "Usage: octransmid.rb [options] stopNumber1 stopNumber2 ..."

  # Define the options, and what they do
  options[:multitrack] = false
  opts.on( '-mt', 'Outputs as multitrack' ) do
    options[:multitrack] = true
  end
end

# parse the options out.
optparse.parse!

# generate a midi file for each stop specified
ARGV.each do|stop_num|
  puts "Generating midi file for stop #" << stop_num
  transmid = OCTransmid.new( stop_num, options)
  transmid.exportToMidi
end

