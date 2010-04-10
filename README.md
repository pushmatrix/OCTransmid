
#OCTransmid


##Description:


For a given OCTranspo bus stop, there are normally several buses that go through it during the day. What if every time a bus arrived at that stop, it played a sound? As more and more buses would pass by the stop, more and more different sounds would be played, essentially creating a pattern. This pattern can then be transformed into MIDI. Currently, OCTransmid can output a .mid file as either singletrack or multitrack. 

##Multitrack:

Each bus route going through the specified stop is given its own track. That is, you can assign a unique instrument or sound to specifically that track. 

##Singletrack:

Each bus route going through the specified stop is merged into a single track. However, each route has a different "chord" that it plays. This way, you can assign an instrument to the track, and the arrivals will trigger different notes for that instrument.

#How to run:

Simply run:
		ruby octransmid.rb [options] stopnumber
(ex: ruby octransmid.rb 7676)
(ex: ruby octransmid.rb -mt 7676 2343 3000)

The current list of options are:
+ mt *export the midi with under multitrack mode*

#TODO:

A better description!