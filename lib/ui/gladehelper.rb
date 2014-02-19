require 'pathname'

module Ig3tool

	class GladeHelper
		GLADE_DIR = Pathname.new(__FILE__).parent.parent + "glade"

		def initialize (gladefile, toplevel = "window")
			filename = GLADE_DIR + gladefile
			@glade = Gtk::Builder.new
                        @glade.add_from_file(filename.to_s)
                        @glade.connect_signals {|h| method(h) }
			@window = @glade.get_object(toplevel)
			@window.title += " - Ig3tool"
			@window.move(169,0) # Zet het naast het toolwindow
			@window.signal_connect("delete-event") do
				@window.hide
				true
			end
      

                        @sounds = Hash.new
#      load_sounds

		end

		def show
			@window.show
		end

#    def load_sounds
#      sounddir = File.join(GLADE_DIR, "sound", "*.wav")
#      Dir.glob(sounddir).each do |wavfile|
#        key = File.basename(wavfile, ".wav")
#        @sounds[key] = File.basename(wavfile)
#      end
#      @sounds["cash"] = "cash2.wav"
#      @sounds["tetten"] = "shaglic1.wav"
#      @sounds["wall-e"] = "walle01.wav"
#      @sounds["tea"] = "wohlen_sie.wav"
#      @sounds["burp"] = "burp.wav"
#      @sounds["cow"] = "cow.wav"
#      @sounds["jaaa"] = "jaaaaaa.wav"
#      @sounds["pika"] = "pikachu1.wav"
#      @sounds["canttouch"] = "cant_touch_this.wav"
#      @sounds["hammertime"] = "stop_hammertime.wav"
#      @sounds["gone1"] = "gonept1.mp3"
#      @sounds["gone2"] = "gonept2.mp3"
#    end

    def enumerateSounds(key)
        sounddir = File.join(GLADE_DIR, "sound")
        matches = File.join(sounddir, key)
        return Dir.glob(matches).map do |filepath|
            # make sure they are offset from GLADE_DIR/sound
            filepath[(sounddir.length + File::SEPARATOR.length)..(filepath.length)]
        end
    end

    def play(key)
			Thread.new do
				filename = File.join(GLADE_DIR, "sound", key) #@sounds[key]
                                puts filename
				unless filename.nil?
					begin
						`mplayer #{filename}`
					rescue Exception => e
						warn "sound error: #{e.message}"
					end
				end
			end
    end

		def speak(str)
			Thread.new do
				begin
					`echo \"#{str}\" | festival --tts`
				rescue
						warn "speech error: #{e.message}"
				end
			end
		end

		def present
			@window.present
		end

		def _get_widget(widget)
			@glade.get_object(widget)
		end

		# Debugger combobox invullen
		def make_debugger_combo (combo, window = nil)
			@@debuggers ||= $client.person_debuggers.sort {|a,b| a.username <=> b.username }

			debugger_model = Gtk::ListStore.new(Object, String)
			@@debuggers.each do |d|
				row    = debugger_model.append
				row[0] = d
				row[1] = d.username
			end

			combo.clear
			combo.model  = debugger_model
			renderer = Gtk::CellRendererText.new
			combo.pack_start(renderer, true)
			combo.add_attribute(renderer, :text, 1)

			# Indien het window gekleurd moet worden adhv zijn 'interne' status
			add_window_colorer(combo, window) if window

			username = $client.username
			debugger_model.each do |m, p, i|
				if i[1] == username
					combo.active_iter = i
					break
				end
			end
		end

		# Status combobox invullen
		def make_status_combo (combo,statussen = nil)
			begin
				statussen = $client.person_statussen unless statussen
				statussen_model = Gtk::ListStore.new(Object, String)
				statussen.each do |key, value|
					row		 = statussen_model.append
					row[0] = key
					row[1] = value
				end
				combo.model = statussen_model
				combo.active = 0
				combo.clear
				renderer = Gtk::CellRendererText.new
				combo.pack_start(renderer, true)
				combo.set_attributes(renderer, :text => 1)
			rescue Exception => e
				puts "Fout: Make_status_combo: #{$!}"
			end
		end

		def add_window_colorer(combo, window)
			combo.signal_connect("changed") do
				saldo = 0
				if combo.active_iter
					debugger = combo.active_iter[1]
          if debugger != "kas"
					begin
						saldo  = $client.interne(debugger).saldo.to_i
					rescue Exception => e
						# ignore
            puts e.to_s + " - " + e.message
					end
          end
				end

				if saldo < 0
					shade = [65535, 0, 0] 
					ratio = (saldo < -7500) ? 1 : Rational(saldo,(-75 * 100)) # In cent + Need rational!
				else
					shade = [0, 65535, 0]
					ratio = (saldo > 20000) ? 1 : Rational(saldo,(200 * 100))
				end
				ratio1 = 1 - ratio
				base = Gtk::Widget.default_style.bg(Gtk::STATE_NORMAL)
				window.modify_bg(Gtk::STATE_NORMAL,
												 Gdk::Color.new(
													 (base.red   * ratio1 + shade[0] * ratio).to_i,
													 (base.green * ratio1 + shade[1] * ratio).to_i,
													 (base.blue  * ratio1 + shade[2] * ratio).to_i))
			end
		end

		def make_eval_widget(widget, fallback="")
			%w(focus-out-event activate).each do |s|
				widget.signal_connect s do
					number_eval_widget widget, fallback
					false
				end
			end
		end

		def number_eval_widget(widget, fallback="")
			text = widget.text
			text.strip!
			text.gsub! /[^\d+\/*().-]/, ""
			text.gsub! /(\D|^)\./, '\1'+'0.' # Ruby laat geen ".2" toe
			if text =~ /[+\/*()-]/
				text = begin eval(text).to_s rescue fallback.to_s end
			else
				text = text.to_f.to_s
			end
			widget.text = text
		end

	end
end
