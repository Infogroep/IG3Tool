require 'gettext'
module Ig3tool

	class PrintingWindow < GladeHelper
		include GetText

		MENU_PATH = ["Printer", "Printing"]
		ICON = "stock_print.png"

		attr :glade

		def initialize
			super("printing.xml")


			@tabs = @glade.get_object("tabs")

			@firstname = @glade.get_object("firstname")
			@lastname = @glade.get_object("lastname")
			@username = @glade.get_object("username")
			@email = @glade.get_object("email")
			@saldo = @glade.get_object("saldo")
			@notification = @glade.get_object("errorfield")
			@log_notification = @glade.get_object("errorfield")
			@apply = @glade.get_object("apply")
			@clear = @glade.get_object("clear")
			@delta = @glade.get_object("delta")
			@statussearch = @glade.get_object("statussearch")
			@status = @glade.get_object("status")
			@usernames = @glade.get_object("usernames")
			@usernames.model = @usernames_store = Gtk::ListStore.new(Object, String)
			r = Gtk::CellRendererText.new
			@usernames.insert_column(-1, "username", r, :text => 1)
			@usernames.enable_search = true
			
			
			# ALIASES
			@alias_debugger = @glade.get_object("alias_debugger")
			@alias_notification = @glade.get_object("errorfield")
			@alias_username = @glade.get_object("alias_username")
			@alias_alias = @glade.get_object("alias_alias")
			@aliases = @glade.get_object("aliases")
			@aliases.model = @aliases_store = Gtk::ListStore.new(Object, String)
			ar = Gtk::CellRendererText.new
			@aliases.insert_column(-1, "alias", ar, :text => 1)
			@aliases.enable_search = true

			make_debugger_combo(@alias_debugger)

			# LOG

			@filteredlog = @glade.get_object("filteredlog")
			@filteredlog.model = @filteredlog_store = Gtk::ListStore.new(Object, String)
			@last_log_id = 0
			fl = Gtk::CellRendererText.new
			@filteredlog.insert_column(-1, "message", fl) do |tvc, cell, m ,iter|
			if iter[0].category == "print"
				message = "#{iter[0].username} printed #{iter[0].pages} pages for #{iter[0].amount} cents: #{iter[0].job}"
			else
				message = iter[0].message
			end
			cell.text = message
			cell.strikethrough = iter[0].refunded.to_i.to_b
			end


			@log = @glade.get_object("log")
			@log.model = @log_store = Gtk::ListStore.new(Object)
			@last_big_log_id = 0
			l = Gtk::CellRendererText.new
			@log.insert_column(-1, "time", l) do |tvc, cell, m, iter|
				cell.text = Time.parse(iter[0].time).strftime("%d/%m %H:%M")
			end
			@log.insert_column(-1, "type", l) do |tvc, cell, m, iter|
				cell.text = iter[0].category
				cell.strikethrough = iter[0].refunded.to_i.to_b
			end
			@log.insert_column(-1, "username", l) do |tvc, cell, m, iter|
				cell.text = iter[0].username
			end
			@log.insert_column(-1, "queue", l) do |tvc, cell, m, iter|
				cell.text = iter[0].queue
			end
			@log.insert_column(-1, "amount", l) do |tvc, cell, m, iter|
				cell.text = iter[0].amount.from_c.to_s
			end
			@log.insert_column(-1, "host", l) do |tvc, cell, m, iter|
				cell.text = iter[0].host
			end
			@log.insert_column(-1, "pages", l) do |tvc, cell, m, iter|
				cell.text = iter[0].pages
			end
			@log.insert_column(-1, "job", l) do |tvc, cell, m, iter|
				cell.text = iter[0].job
			end
			@log.insert_column(-1, "message", l) do |tvc, cell, m, iter|
				cell.text = iter[0].message
			end

      # externals
			@ext_debugger = @glade.get_object("ext_debugger")
			@ext_notification = @glade.get_object("errorfield")
			@ext_name = @glade.get_object("ext_name")
			@ext_contact = @glade.get_object("ext_contact")
			@ext_ip = @glade.get_object("ext_ip")
			@ext_debt = @glade.get_object("ext_debt")
			@ext_list = @glade.get_object("ext_list")
			@ext_list.model = @ext_list_store = Gtk::ListStore.new(Object, String)
			err = Gtk::CellRendererText.new
			@ext_list.insert_column(-1, "ext", err, :text => 1)
			@ext_list.enable_search = true

			make_debugger_combo(@ext_debugger)
			
			begin
        GLib::Timeout.add_seconds(30) {
          begin
            _update_log
            _update_biglog
          rescue Exception => e
          end
          true
        }
      rescue
        GLib::Timeout.add(30*1000) {
          begin
            _update_log
            _update_biglog
          rescue Exception => e
          end
          true
        }
      end

			refresh(nil)
      @statussearch.active = 0
			make_menu
			make_bigmenu
		end


		def log_click(w, event)
			if event.kind_of? Gdk::EventButton and event.button == 3
				@log_menu.popup(nil, nil, event.button, event.time)
			end
		end
		def biglog_click(w, event)
			if event.kind_of? Gdk::EventButton and event.button == 3
				@log_big_menu.popup(nil, nil, event.button, event.time)
			end
		end

		def make_menu
			@log_menu = Gtk::Menu.new
			log_menu_refund_item = Gtk::MenuItem.new("refund")
			log_menu_show_item = Gtk::MenuItem.new("show")
			log_menu_reprint_item = Gtk::MenuItem.new("reprint")
			# Treeview heeft default Mode Gtk::SELECTION_SINGLE
			log_menu_reprint_item.signal_connect("activate") {
				@filteredlog.selection.selected_each do |model, path, iter|
				logentry = iter[0]
				# do reprint stuff
				$client.print_reprint!({ "logid" => logentry["id"]})
				@notification.text  = "attempting reprint of job #{logentry["job"]} for #{logentry["username"]}"
				_update_log
				end
			}
			log_menu_show_item.signal_connect("activate") {
				@filteredlog.selection.selected_each do |model, path, iter|
				logentry = iter[0]
				_show(logentry.username)
				end
			}
			log_menu_refund_item.signal_connect("activate") {
				@filteredlog.selection.selected_each do |model, path, iter|
				logentry = iter[0]
				if logentry.refunded.to_i.to_b
					logentry["refunded"] = "0"
				else
					logentry["refunded"] = "1"
				end
				@filteredlog_store.insert_before(iter)[0] = logentry
				@filteredlog_store.remove(iter)

				begin
					raise IG3Error, "the imps can only refund printjobs" if logentry.category != "print"
					$client.print_refund!({"logid" => logentry["id"]})
					@notification.text  = "refunded print of #{logentry["amount"]} credits to #{logentry["username"]}"
					_update_log
				rescue Exception => e
					#puts "ERR: " + e.message.to_s
					@notification.text = (e.class.to_s + " - " + e.message).smaller
				end
			end
			#_delete(iter[0],false)
			#model.remove(iter) # Verwijder uit de lijst
			}

			@log_menu.append(log_menu_show_item)
			@log_menu.append(log_menu_refund_item)
			@log_menu.append(log_menu_reprint_item)
			@log_menu.show_all

		end
		
		def make_bigmenu
			@log_big_menu = Gtk::Menu.new
			log_menu_refund_item = Gtk::MenuItem.new("refund")
			log_menu_show_item = Gtk::MenuItem.new("show")
			log_menu_reprint_item = Gtk::MenuItem.new("reprint")
			# Treeview heeft default Mode Gtk::SELECTION_SINGLE
			log_menu_reprint_item.signal_connect("activate") {
				@filteredlog.selection.selected_each do |model, path, iter|
				logentry = iter[0]
				# do reprint stuff
				$client.print_reprint!({ "logid" => logentry["id"]})
				@notification.text  = "attempting reprint of job #{logentry["job"]} for #{logentry["username"]}"
				_update_log
				end
			}
			log_menu_show_item.signal_connect("activate") {
				@log.selection.selected_each do |model, path, iter|
				logentry = iter[0]
				_show(logentry.username)
				@tabs.page = 0
				end
			}
			log_menu_refund_item.signal_connect("activate") {
				@log.selection.selected_each do |model, path, iter|
				logentry = iter[0]
				if logentry.refunded.to_i.to_b
					logentry["refunded"] = "0"
				else
					logentry["refunded"] = "1"
				end
				@log_store.insert_before(iter)[0] = logentry
				@log_store.remove(iter)
				begin
					raise IG3Error, "only printjobs can be refunded" if logentry.category != "print"
					$client.print_refund!({"logid" => logentry["id"]})
					@log_notification.text  = "refunded print of #{logentry["amount"]} credits to #{logentry["username"]}"
					_update_log
				rescue Exception => e
					Ig3tool.show_login_window if e.class == Ig3tool::Token || e.class == Token
					#puts "ERR: " + e.message.to_s
					@log_notification.text = (e.class.to_s + " - " + e.message).smaller
				end
				end
			#_delete(iter[0],false)
			#model.remove(iter) # Verwijder uit de lijst
			}

			@log_big_menu.append(log_menu_show_item)
			@log_big_menu.append(log_menu_refund_item)  
			@log_big_menu.append(log_menu_reprint_item)  
			@log_big_menu.show_all

		end


    # funtions for extern tab
    
    def ext_apply(w)
      begin
      $client.print_update_external!("name" => @ext_name.text.strip, "contact" => @ext_contact.text.strip, "ip" => @ext_ip.text.strip)
        _ext_clear
        _update_ext_list
        @ext_notification.text = "the imps applied your changes!" 
      rescue Exception => e
        @ext_notification.text = e.class.to_s + " " + e.message.to_s 
      end
    end

    def ext_cancel(w)
      _ext_clear
      _update_ext_list
    end

    def ext_delete(w)
      begin
      $client.print_remove_external!("name" => @ext_name.text.strip)
        _update_ext_list
        _ext_clear
        @ext_notification.text = "the imps removed this external!" 
      rescue Exception => e
        @ext_notification.text = e.class.to_s + " " + e.message.to_s 
      end
    end

    def get_debugger(widget)
      widget.active_iter[0]
    end 


    def ext_reset(w)
      begin
        if @ext_debugger.active == -1
          @ext_notification.text = "Please select a debugger!"
        else
          $client.print_reset_external!("external" => @ext_name.text.strip, "debugger" => get_debugger(@ext_debugger).username)
          _ext_clear
          @ext_notification.text = "the imps resetted the debt of this external!"
        end
      rescue Exception => e
        @ext_notification.text = e.class.to_s + " " + e.message.to_s 
      end
    end

    def ext_smart_update(w)
      name = @ext_name.text.strip
      _ext_show(name)
    end

    def ext_seleted(w, path, col)
			name = w.model.get_iter(path)[1]
      _ext_show(name)
    end



    # end of extern



		def alias_apply(w)
			begin
			username = @alias_debugger.active_iter[0]
			a = @alias_alias.text.strip
			$client.print_addalias!("username" => username.username, "alias" => a)
				@alias_notification.text = "alias #{a} for #{username.username} added!"
			@alias_alias.text = ""
			_update_aliases(username.username)
			rescue Exception => e
				@alias_notification.text = e.message
			end

		end

		def select_alias(widget, path, col)
			a = widget.model.get_iter(path)[0]
			@alias_alias.text = a.alias
			@alias_username.text = a.username
		end

		def alias_cancel(w)
			@alias_username.text = ""
			@alias_alias.text = ""
			@alias_notification.text = ""
		end

		def alias_delete(w)
			begin
			username = @alias_debugger.active_iter[0]
			a = @alias_alias.text.strip
			$client.print_removealias!("username" => username.username, "alias" => a)
				@alias_notification.text = "alias #{a} for #{username.username} removed!"
			@alias_alias.text = ""
			_update_aliases(username.username)
			rescue Exception => e
				@alias_notification.text = e.message
			end
		end

		def alias_delete_all(w)
			begin
			username = @alias_debugger.active_iter[0]
			$client.print_removealiases!("username" => username.username)
				@alias_notification.text = "all aliases for #{username.username} removed!"
			@alias_alias.text = ""
			_update_aliases(username.username)
			rescue Exception => e
				@alias_notification.text = e.message
			end
		end

		def alias_changed(widget)
			alias_cancel(nil)
			username = @alias_debugger.active_iter[0].username
			puts username
			@alias_username.text = username
			_update_aliases(username)
		end

		def fl_row_activated(view, path, col)
			logentry = @filteredlog.model.get_iter(path)[0]
			#if logentry.category != "print"
				_show(logentry.username)
			#else
			#	begin
			#		$client.print_refund!({"logid" => logentry["id"]})
			#		@notification.text  = "refunded print of #{logentry["amount"]} to #{logentry["username"]}"
			#		_update_log
			#	rescue Exception => e
			#		#puts "ERR: " + e.message.to_s
       #   @notification.text = (e.class.to_s + " - " + e.message).smaller
			#	end
			#end
		end

		def log_row_activated(view, path, col)
			logentry = @log.model.get_iter(path)[0]
			#if logentry.category != "print"
				_show(logentry.username)
			#else
			#	begin
			#		$client.print_refund!({"logid" => logentry["id"]})
			#		@notification.text  = "refunded print of #{logentry["amount"]} to #{logentry["username"]}"
			#	rescue Exception => e
			#		#puts "ERR: " + e.message.to_s
       #   @notification.text = (e.class.to_s + " - " + e.message).smaller
			#	end
			#end
			@tabs.page = 0
		end

		def changed(widget) # triggers when fields change
			#puts "changed " + widget.text
			@apply.image = Gtk::Image.new(Gtk::Stock::APPLY, Gtk::IconSize::BUTTON)
			@apply.label = Gtk::Stock::APPLY
		end

		def refresh(widget) # refreshes the usernames list and the small log
			if !@refreshing
				@refreshing = true
				_update_usernames
				_update_log
				@refreshing = false
			end
		end


		def refreshlog(widget) #refreshes the big log on page 2
			_update_biglog
			@log_notification.text = ""
		end

		def to_apply(widget)
			if(@username.text.strip != "")
				@apply.grab_focus
				@notification.text = "Save changes?"
			else
				@username.grab_focus
			end
		end

		def to_add(widget)
			if(@username.text.strip != "")
				if(@delta.text.strip != "")
					@apply.grab_focus
					@notification.text = "Add credits?"
				else
					@delta.grab_focus
				end
			else
				@username.grab_focus
			end

		end

		def tabfocus(a,b,c)
			case c
			when 1
				_update_biglog
			when 0
				refresh(nil)
			when 2
				_update_aliases(nil)
			when 3
				_update_ext_list
			end
		end


		def smart_search(widget)
			if @username.text.strip == ""
				@notification.text = "the imps want you to look up a user first..."
				clear_all(nil, false)
			else
				begin
					user = $client.print_user(@username.text)
          _ext_clear
          @ext_contact.text = user.username
					person = $client.person_lookup({"username" => @username.text})
          raise NotFound, "the ig3tool imps found no such user..." if person.nil?
					person = person[0]
					@email.text = person["email"]
					@saldo.text = user["saldo"].from_c.to_s
					@firstname.text = person["first_name"]
					@lastname.text = person["last_name"]
					@status.text = $client.person_status(person["username"])
					@notification.text = "the ig3tool imps found #{user["username"]}..."
					@apply.image = Gtk::Image.new(Gtk::Stock::ADD, Gtk::IconSize::BUTTON)
					@apply.label = Gtk::Stock::ADD
					@delta.grab_focus
				rescue Exception => e
					begin
						person = $client.person_lookup({"username" => @username.text})
            raise NotFound, "the ig3tool imps found no such user..." if person.nil? or person.empty?
						person = person[0]
						@email.text = person["email"]
            _ext_clear
            @ext_contact.text = user.username
						@saldo.text = "0.0"
						@firstname.text = person["first_name"]
						@lastname.text = person["last_name"]
						@status.text = $client.person_status(person["username"])
						@notification.text = "the ig3tool imps found #{person["username"]}..."
						@apply.image = Gtk::Image.new(Gtk::Stock::ADD, Gtk::IconSize::BUTTON)
						@apply.label = Gtk::Stock::ADD
						@delta.grab_focus
					rescue Exception => e
						#puts "user not found"
					  @notification.text = (e.class.to_s + " - " + e.message).smaller
            puts e.inspect
            @notification.text += "\n fill in the blanks to create a new user"
            @email.text = @username.text.strip + "@vub.ac.be" 
            @firstname.grab_focus
					end
				end
			end
		end

		def clear_all(widget, clearnotification=true)
			@username.text = ""
			@email.text = ""
			@saldo.text = "0.0"
			@firstname.text = ""
			@lastname.text = ""
			@notification.text = "" if clearnotification
			@delta.text = "0.0"
			@apply.image = Gtk::Image.new(Gtk::Stock::APPLY, Gtk::IconSize::BUTTON)
			@apply.label = Gtk::Stock::APPLY
			@usernames.grab_focus
			@statussearch.active = -1
		end

		def clear_most(widget)
			@email.text = ""
			@saldo.text = "0.0"
			@firstname.text = ""
			@lastname.text = ""
			@notification.text = ""
			@delta.text = "0.0"
			@apply.image = Gtk::Image.new(Gtk::Stock::APPLY, Gtk::IconSize::BUTTON)
			@apply.label = Gtk::Stock::APPLY
			#@statussearch.active = -1
		end

		def username_del(a,b,c)
			clear_most(nil)
		end
		def username_ins(a,b,c,d)
			clear_most(nil)
		end

		def smart_add(widget)
			begin
				$client.print_addcredit!({:username => @username.text, :amount => @delta.text})
				@notification.text = "the imps added #{@delta.text} euro's to #{@username.text}'s account..."
			rescue Exception => e
          @notification.text = (e.class.to_s + " - " + e.message).smaller
			end
		end

		def notification_focus_in_event_cb(widget, arg0)
			puts "notification_focus_in_event_cb() is not implemented yet."
		end

		def smart_update(widget)
			if @username.text.strip == ""
				quick_message("\n    you can't do that with no username looked up...    \n")
				clear_all(nil)
			else
				begin
					#amount = @delta.text.strip.gsub(/,/, ".")
					amount = @delta.text.strip
					#if amount.to_f < 0
					#	quick_message("\n    the ig3tool imps do not accept negative values...    \n")
					#else
						$client.print_update!({:username => @username.text, 
														 :first_name => @firstname.text,
														 :last_name => @lastname.text,
														 :email => @email.text,
														 :amount => amount.to_c })
						clear_all(nil)
						@notification.text = "smart update done!"
						Thread.new do
							refresh(true)
						end
					#end
				rescue Exception => e
          @notification.text = (e.class.to_s + " - " + e.message).smaller
				end
			end
		end

		def select (widget, path, column)
			iter = widget.model.get_iter(path)
			_show iter[1]
		end

		private

		def _show(username)
			#puts "show: #{username}"
			begin
				user = $client.print_user(username)
				person = $client.person_lookup(["username", username])[0]
				@username.text = username
        _ext_clear
        @ext_contact.text = username
				@email.text = person["email"]
				@saldo.text = user["saldo"].from_c.to_s
				@firstname.text = person["first_name"]
				@lastname.text = person["last_name"]
				@status.text = $client.person_status(username)
				@notification.text = "the ig3tool imps found #{username}..."
				@apply.image = Gtk::Image.new(Gtk::Stock::ADD, Gtk::IconSize::BUTTON)
				@apply.label = Gtk::Stock::ADD
				@delta.grab_focus
			rescue Exception => e
				#puts "EXC: " + e.message
				begin
          person = $client.person_lookup(["username", @username.text])
          raise NotFound, "the ig3tool imps found no such user..." if person.nil? or person.empty?
          person = person[0]
					@username.text = username
          _ext_clear
          @ext_contact.text = username
					@email.text = person["email"]
					@saldo.text = "0"
					@firstname.text = person["first_name"]
					@lastname.text = person["last_name"]
					@status.text = $client.person_status(username)
					@notification.text = "the ig3tool imps found #{username}..."
					@apply.image = Gtk::Image.new(Gtk::Stock::ADD, Gtk::IconSize::BUTTON)
					@apply.label = Gtk::Stock::ADD
					@delta.grab_focus
				rescue Exception => e
					#puts "user not found"
          @notification.text = (e.class.to_s + " - " + e.message).smaller
          puts e.inspect
					@notification.text += "\n fill in the blanks to create a new user"
					@email.text = @username.text.strip + "@vub.ac.be" 
					@firstname.grab_focus
				end
			end
		end

    def _ext_show(name)
      begin
        e = $client.print_external(name)
        @ext_name.text = e.name
        @ext_contact.text = e.contact
        @ext_ip.text = e.ip
        @ext_debt.text = e.debt.from_c.to_s
      rescue Exception => e
          @notification.text = (e.class.to_s + " - " + e.message)
      end
    end

		def _update_usernames(clear=true)
			@usernames.model = nil
			@usernames_store.clear if clear
			Thread.new do 
				if @statussearch.active > 0
					users = $client.person_everybody.sort{|x,y| x["username"] <=> y["username"]}
				else
					users = $client.print_users
				end
				users.each do |user|
					row = @usernames_store.append
					row[1] = user["username"]
				end
				@usernames.model = @usernames_store
			end
		end
		
		def _update_aliases(username)
			@aliases.model = nil
			@aliases_store.clear
			Thread.new do 
					users = $client.print_aliases
					users.delete_if{|u| u.username != username} unless username.nil?
				users.each do |user|
					row = @aliases_store.append
					row[1] = user.alias
					row[0] = user
				end
				@aliases.model = @aliases_store
			end
		end
		
    def _update_ext_list
			@ext_list.model = nil
			@ext_list_store.clear
			Thread.new do 
				exts = $client.print_externals
				exts.each do |e|
					row = @ext_list_store.append
					row[1] = e.name
					row[0] = e
				end
				@ext_list.model = @ext_list_store
			end
		end


    def _update_log
			_update_log_bypassed
			@filteredlog.scroll_to_point(0,0)
			begin
			  GLib::Timeout.add_seconds(1) {
				  @filteredlog.scroll_to_point(0,0)
				  false
			  }
		  rescue
		    GLib::Timeout.add(1*1000) {
				  @filteredlog.scroll_to_point(0,0)
				  false
			  }
	    end
		end

		def _update_log_bypassed
				begin
					loglines = $client.print_logs(200, @last_log_id)
					loglines.reverse.each do |ll|
						@filteredlog_store.prepend[0] = ll
					end
					@last_log_id = loglines.first["id"] # this makes loglines be nil, waaaai?
					#@last_log_id = 0 # fix, but always gets the entire log again, - o, well -
				rescue Exception => e
					warn "error updating log: " + e.message
					warn e.backtrace
				end
		end
		
		def _update_biglog
			_update_biglog_bypassed
			@log.scroll_to_point(0,0)
      begin
        GLib::Timeout.add_seconds(1) {
          @log.scroll_to_point(0,0)
          false
        }
      rescue
        GLib::Timeout.add(1*1000) {
          @log.scroll_to_point(0,0)
          false
        }
      end
		end

		def _update_biglog_bypassed
			if !@updating_biglog # sommige kindjes vinden het leuk om op refresh te klikken
				@updating_biglog = true
					begin
						loglines = $client.print_logs(200, @last_big_log_id)
						loglines.reverse.each do |ll|
							@log_store.prepend[0] = ll
						end
						@last_big_log_id = loglines.first["id"]
						@updating_biglog = false
					rescue Exception => e
					  Ig3tool.show_login_window if e.class == Ig3tool::Token || e.class == Token
						warn "error updating biglog: " + e.message
						@updating_biglog = false
					end
			end
		end

    def _ext_clear
      @ext_name.text = ""
      @ext_contact.text = ""
      @ext_ip.text = ""
      @ext_debt.text = ""
      @ext_notification.text = ""
      @ext_debugger.active  = -1
    end

		def quick_message(message, title="ig3tool message")
			# Create the dialog
			dialog = Gtk::Dialog.new(title,
															 $main_application_window,
															 Gtk::Dialog::DESTROY_WITH_PARENT,
															 [ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_NONE ])

			# Ensure that the dialog box is destroyed when the user responds.
			dialog.signal_connect('response') { dialog.destroy }

			# Add the message in a label, and show everything we've added to the dialog.
			dialog.vbox.add(Gtk::Label.new(message))
			dialog.show_all
		end

	end

	register_window(PrintingWindow)

end

