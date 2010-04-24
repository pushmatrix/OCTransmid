# Fun Fact: Find bus stop numbers here: http://www.octranspo1.com/maps

require 'octransposcraper'
require 'midilib/sequence'
require 'midilib/consts'
require 'optparse'
include MIDI



class OCTransmid
  
  @@midi_directory = "midiexports/"
  # Start the day at 6AM
  @@day_start_time = Time.local(1,1,1,6,0,0)
  # Pulses per quarter note. This needs to be at 500 so that
  # when you specify a 1 millisecond delay, it actually is 1 millisecond.
  @@ppqn = 500
  
  @@seconds_in_a_day = 60 * 60 * 24
  
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
      if(@seq.tracks.size > 1)
        filename << "multi"
      end
      File.open(@@midi_directory + filename +".mid", 'wb') do | file |
     	  @seq.write(file)
      end
    end
  end
  
  protected
  
  # TODO: Error Checking
  def getMultipleTrackMidiSequence
    bus_arrivals = @scraper.getBusStopArrivals( @stop_number )
    if bus_arrivals.empty?
      return 
    end
    
    @seq = Sequence.new()
    @seq.ppqn = @@ppqn
    bus_arrivals.each_with_index do |arrivals,index|
      bus_number = arrivals[0]
      arrival_times = arrivals[1]
      
      # Create a new MIDI track per bus route
      track = Track.new(@seq)
      @seq.tracks << track
      track.events << Controller.new(0, CC_VOLUME, 127)
      track.events << ProgramChange.new(0, 1, 0)

      delta = arrival_times[0] - @@day_start_time
      delta = delta.to_i
      new_note_event( @base_note , @note_length, track,127, delta )
      0.upto(arrival_times.size-2).each do |i|
        #time difference in seconds
        delta = arrival_times[i+1] - arrival_times[i]
        delta = delta.to_i
        if( delta < 0)
          delta *= -1
          delta = @@seconds_in_a_day - delta
        end
        new_note_event( @base_note + index, @note_length, track,127, delta - @note_length )
        end
    end
    return @seq
  end
  def getSingleTrackMidiSequence
    # Generate a multi track sequence
    multi_track_seq = getMultipleTrackMidiSequence
    if multi_track_seq.nil?
      return
    end
    # Take the multitrack sequence, and merge it down.
    single_track_seq = Sequence.new()
    single_track_seq.ppqn = @@ppqn
    track = Track.new( single_track_seq )
    
    multi_track_seq.tracks.each do |other_track|
     track.merge other_track.events
    end
    single_track_seq.tracks << track
    @seq = single_track_seq
    return @seq
  end
  
  
  def new_note_event(note, note_length, track,velocity, delta)
    channel = 0
    track.events << NoteOnEvent.new(channel, note, velocity, delta)
    track.events << NoteOffEvent.new(channel, note, velocity, @note_length)
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

