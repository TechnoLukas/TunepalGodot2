"""
Midi Player Demo
See comments bellow in _process, when to start/stop a note
@author BrainFooLong
@url https://github.com/brainfoolong/gdscript-midi-parser
""" 

class_name MidiFilePlayerExample extends Node

signal event (eventData, trackData)
signal finished

@onready var MidiPlayer_bus_index = AudioServer.get_bus_index("MidiPlayer")

var parser : MidiFileParser
var ms_per_tick = 60000 / (120 * 480)
var lastEventTime = 0
var currentEventIndex = 0
var playing = false
var audio_streams = {}

var sample_hz = 22050.0 # Keep the number of samples to mix low, GDScript is not super fast.
var pulse_hz = 220.0
var phase = 0.0

var midi_finished = false

var restart = false

func play():
	lastEventTime = -1
	playing = true
	AudioServer.set_bus_mute(MidiPlayer_bus_index, false)

func pause():
	playing = false

func stop():
	playing = false
	AudioServer.set_bus_mute(MidiPlayer_bus_index, true)

func play_sound(note_name, hz = 0, volume = 0):		
	if note_name in audio_streams:
		audio_streams[note_name].stop()
		audio_streams[note_name].queue_free()
		audio_streams.erase(note_name)
	if volume > 0:
		var audio_stream = AudioStreamPlayer.new()
		audio_stream.stream = AudioStreamGenerator.new()
		audio_stream.volume_db = -((1 - volume) * 20)
		audio_stream.stream.mix_rate = 3675 # using low sample rate for performance, best is 44100
		audio_stream.bus = "MidiPlayer"
		audio_streams[note_name] = audio_stream
		add_child(audio_stream)
		audio_stream.play()
		var playback = audio_stream.get_stream_playback()
		var increment = hz / audio_stream.stream.mix_rate
		var to_fill = playback.get_frames_available()
		while to_fill > 0:
			playback.push_frame(Vector2.ONE * sin(phase * TAU)) # Audio frames are stereo.
			phase = fmod(phase + increment, 1.0)
			to_fill -= 1	
				

func _ready():
	pass
	# loading Beethoven - Fur Elise
	#parser = MidiFileParser.load_file("res://assets/Roscommon.mid")
	# use MidiFileParser.load_file() when you have a file on disk
	#play()

func loadmidi(path):
	parser = MidiFileParser.load_file(path)
	
func playing_the_midi():
	for track in parser.tracks:
		var delta_ms = 0
		var player_process
		# storing internal player process in track data
		if "player_process" not in track.additional_data:
			track.additional_data.player_process = {"time" : Time.get_ticks_msec(), "event_index" : 0}
			player_process = track.additional_data.player_process
		else:
			player_process = track.additional_data.player_process
			delta_ms = Time.get_ticks_msec() - player_process.time		
			
		var delta_ticks = delta_ms / ms_per_tick
		while player_process.event_index < track.events.size():
			var event = track.events[player_process.event_index]
			if event.delta_ticks > delta_ticks:
				break
			player_process.event_index += 1
			player_process.time = Time.get_ticks_msec()
			delta_ms = 0
			delta_ticks = 0
			self.emit_signal("event", event, track)
			if event.event_type == MidiFileParser.Event.EventType.META && event.type == MidiFileParser.Meta.Type.SET_TEMPO:
				# tempo update
				ms_per_tick = event.ms_per_tick
				#print("tempo now " +str(event.bpm)+ " bpm")
			if event.event_type == event.EventType.MIDI && event.note_name != '':
				var offset = event.param1 - 69
				if event.velocity > 0:
					play_sound(event.note_name, event.frequency, event.velocity)
					#print("Play "+event.note_name+" with velocity "+str(event.velocity)+" freq "+str(event.frequency))
				else:
					play_sound(event.note_name)
					#print("Stop "+event.note_name)
				
				# event.velocity <= 0 = note off
				# event.velocity > 0 = note on
				# see MidiFileParser.Midi for more information about the midi data
	
		if player_process.event_index == track.events.size():
			midi_finished=true
			stop()
			player_process.event_index = 0
			emit_signal("finished")
			
		print(player_process.event_index," / ",track.events.size())

func _process(delta):
	if playing:
		playing_the_midi()
