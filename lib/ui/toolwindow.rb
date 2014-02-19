module Ig3tool

	begin
		require 'pathname'
		require 'inline'
		class XScreenSaver
			class << self
				inline do |builder|
					builder.add_link_flags '-lXss'
					builder.include '<X11/extensions/scrnsaver.h>'
					builder.c %{
					double idle_time() {
						static Display *display;
						XScreenSaverInfo *info = XScreenSaverAllocInfo();
						if (!display)  display = XOpenDisplay(0);
							if (!display)  return -1;
								XScreenSaverQueryInfo(display, DefaultRootWindow(display), info);
								return info->idle / 1000;
					}
				}
				end
			end
		end
	rescue Exception => e
		class XScreenSaver
			def self.timeout
				0
			end
		end
		puts "XTimeout extension not enabled: #{e.message}"
	end

	# Hoofdmenu (altijd on top)
	# Zorgt voor dynamische uitbreidingsmogelijkheden van de ig3tool

	SALES_WINDOW_TIMEOUT = 60 # 1 Minuut

	class ToolWindow

		@@windows = {}

		ICON_BASEPATH = Pathname.new(__FILE__).parent.parent + "glade/icons"

		def initialize (klasses)
			window = Gtk::Window.new
			window.title = "Ig3tool"
			window.type_hint = Gdk::Window::TYPE_HINT_NORMAL
			#window.keep_above = true
			window.move(0,0)

			bigbox = Gtk::VBox.new(true)
			bigbox.border_width = 6
			bigbox.spacing = 12
			window.add(bigbox)


			klasses.each do |klass|
				name = klass::MENU_PATH.last
				icon = (klass::ICON || "no.xpm")
				button = create_button(name, icon.to_s)
				button.signal_connect("clicked") do
					Thread.new do
						@@windows[klass] ||= klass.new
						@@windows[klass].show
						@@windows[klass].present
					end
				end
				bigbox.add(button)
			end

			window.signal_connect("delete-event") do
				not ask_to_quit(window)
			end
			window.signal_connect("destroy") do
				Gtk::main_quit
			end

			GLib::Timeout.add_seconds(30) {
				begin
					if XScreenSaver.idle_time >= SALES_WINDOW_TIMEOUT
						klass = SalesWindow
						@@windows[klass] ||= klass.new
						@@windows[klass].show
						@@windows[klass].present
						@@windows[klass].focus_smartzap
					end
				rescue Exception => e
					puts "No XTimeout"
				end
				true
			}

			bigbox.show_all
			size = window.size_request
			size[0] += 24
			size[1] += klasses.length * 12
			window.set_default_size(*size)
			window.show_all
		end

		private

		def create_button (label, icon = nil)
			if not icon
				return Gtk::Button.new(label)
			end

			i = Gtk::Image.new((ICON_BASEPATH + icon).to_s)
			l = Gtk::Label.new(label)
			l.set_alignment(0, 0.5)

			h = Gtk::HBox.new(false, 6)
			h.pack_start(i, false, false)
			h.pack_start(l, false, false)

			a = Gtk::Alignment.new(0.5, 0.5, 0, 0)
			a.add(h)

			b = Gtk::Button.new
			b.add(a)
			return b
		end

		def ask_to_quit (window)
			dialog = Gtk::MessageDialog.new(window, 0,
			                                Gtk::MessageDialog::QUESTION,
			                                Gtk::MessageDialog::BUTTONS_NONE,
			              "De ig3tool (met alle venstertjes) afsluiten?")
			dialog.add_buttons(
			            [ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL ],
			            [ Gtk::Stock::QUIT,   Gtk::Dialog::RESPONSE_OK ])
      dialog.move(169,0)
			dialog.default_response = Gtk::Dialog::RESPONSE_OK
			quit = dialog.run == Gtk::Dialog::RESPONSE_OK
			dialog.destroy
			return quit
		end

			def self.remove_window (klass)
				@@windows.delete klass
			end
		end

	end
