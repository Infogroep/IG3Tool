module Ig3tool

	class VendingMachineWindow < GladeHelper
		MENU_PATH = ["Automaat"]
		ICON = "cola_xsmall.png"

		LEFTCOL = [
			[ "Coca Cola",            "5449000000996" ],
			[ "Coca Cola Light",      "5449000050205" ],
			[ "Coca Cola Zero",       "5449000131805" ],
#			[ "Coca Light Lemon",     "5449000089229" ],
			[ "Fanta Orange",         "5449000011527" ],
			[ "Fanta Lemon",          "5449000006004" ],
			[ "Sprite",               "5449000014535" ],
			[ "Chaudfontaine plat",   "5449000111678" ]
		]

		RIGHTCOL = [
			[ "Minute Maid",          			"90494024"      ],
			[ "Minute Maid Multivitamine", 	"5449000100573" ],
#			[ "Minute Maid Appelsap", "90494031"      ],
			[ "Nestea",               			"5449000027382" ],
#			[ "Aquarius Orange",      "5449000033819" ],
			[ "Aquarius Lemon",       			"5449000058560" ],
			[ "Chaudfontaine bruis",  			"5449000111715" ],
			[ "Nalu",                 			"5449000067456" ]
		]

		def initialize
			super("vendingmachine.xml")

			@notification = @glade.get_object("notification")

			@entries = [ ]

			[[LEFTCOL,  @glade.get_object("blikjes_table")],
				[RIGHTCOL, @glade.get_object("flesjes_table")]].
				each do |list, table|
				table.resize(list.length, 2)
				list.each_with_index do |(name, barcode), i|
				label = Gtk::Label.new(name + ":")
				label.set_alignment(0, 0.5)
				table.attach(label, 0, 1, i, i + 1)
				entry = Gtk::Entry.new
				entry.name = barcode
				make_eval_widget entry
				table.attach(entry, 1, 2, i, i + 1)
				@entries <<= entry
				end
				end

			@debuggers = @glade.get_object("debuggers")
			make_debugger_combo(@debuggers)

			@window.show_all
		end

		def number_eval_widget(widget, fallback)
			# Controleer of het een nummer is
			super(widget, fallback)
			# Clear notification
			@notification.text = ""
		end

		def sell_clicked
			if @debuggers.active_iter.nil?
				_print_msg("Selecteer eerst uw naam uit de debugger-lijst!")
				return
			end

			debugger = @debuggers.active_iter[0]
			aantal = 0
			items  = {}

			filled_entries = @entries.select {|x| !x.text.nil? and x.text.to_i > 0}
			filled_entries.each do |entry|
				items[entry.name] = entry.text.to_i
				aantal += entry.text.to_i
			end

			if items.empty?
				_print_msg("Minstens een element nodig om te verkopen!")
				return
			end

			begin
				total = $client.product_restock!( :debugger => debugger.username,
																									 :items => items)
			rescue Exception => e
				_print_msg "Fout: Verkopen: #{$!}"
			else
				_print_msg "#{aantal} items verkocht, voor EUR #{total.from_c}!"
			end

			# Maak alle velden leeg
			@entries.each { |entry| entry.text = "" }
		end

		def _print_msg(msg)
			@notification.text = msg
			puts msg
		end

	end

	register_window(VendingMachineWindow)

end
