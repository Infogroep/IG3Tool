require 'gettext'
require 'facets'

module Ig3tool

  class PeopleWindow < GladeHelper
    include GetText

    MENU_PATH = ["Leden"]
    ICON = "members_xklein.png"
    FIELDS = %w(firstname lastname email username rolnummer phone mobile)
    ALLFIELDS = %w(firstname lastname email username rolnummer phone mobile address1 address2 barcode)


    attr :glade

    def initialize
      super("people.glade")

      @username = @glade.get_widget("username")
      @firstname = @glade.get_widget("firstname")
      @lastname = @glade.get_widget("lastname")
      @barcode = @glade.get_widget("barcode")
      @email = @glade.get_widget("email")
      @notification = @glade.get_widget("errorfield")
      @status = @glade.get_widget("status")
      @mobile = @glade.get_widget("mobile")
      @address1 = @glade.get_widget("address1")
      @address2 = @glade.get_widget("address2")
      @phone = @glade.get_widget("phone")
      @rolnummer = @glade.get_widget("rolnummer")

      @statussearch = @glade.get_widget("statussearch")

      @people_view = _@glade.get_widget("names")
      @people_view.model = @people_store = Gtk::ListStore.new(Object, String)
      r = Gtk::CellRendererText.new
      @people_view.insert_column(-1, "name", r, :text => 1)
      @people_view.enable_search = true


      @history    = @glade.get_widget("history")
      @history.model = @history_store = Gtk::ListStore.new(Object, String, String, String, String)
      ll = Gtk::CellRendererText.new
      @history.insert_column(-1, "year", ll) do |tvc, cell, m ,iter|
      cell.text = iter[0].year
      end
      @history.insert_column(-1, "username", ll) do |tvc, cell, m ,iter|
      cell.text = iter[0].username
      end
      @history.insert_column(-1, "status", ll) do |tvc, cell, m ,iter|
      cell.text = iter[0].status
      end
      @history.insert_column(-1, "barcode", ll) do |tvc, cell, m ,iter|
      cell.text = iter[0].barcode
      end



      @statussearch.active = 0

      @statushash = {"non-member" => 0,
    "member" => 1,
    "debugger" => 2,
    "honorary member" => 3,
      "ex-debugger" => 4}
      @statushashi = @statushash.invert

    end

    def delete(widget)
      username = @username.text.strip
			begin
				raise Needed, "please fill in a username..." if username.empty?
			$client.person_remove!("username" => username)
        @notification.text = "the imps killed username, they left no traces..."
			rescue Exception => e
        @notification.text = e.message
			end
    end
    def refreshhist(widget)
      puts "refreshhist() is not implemented yet."
    end
    def smart_search(widget)
      username = @username.text
      if username.strip.empty?
        @notification.text = "please fill in a username..."
      else

        p = $client.person_lookup("username", username)[0]
        if p.nil?
          @notification.text = "no user with username #{username} found..."
        else
          clear_all(nil)
          _show(p)
        end
      end
    end
    def find_by_barcode(widget)
      begin
        barc = @barcode.text
        p = $client.person_member(barc)
        clear_all(nil)
        _show(p)
      rescue Exception => e
        @notification.text = "no user with barcode #{barc} found..."
      end
    end
    def clear(widget)
      @statussearch.active = 0 if @statussearch.active == -1
      #@statussearch.active = 0
      # met of zonder if?
      clear_all(nil)
    end
    def refresh(widget)
      puts "refresh!"
      _update_names(nil) unless @statussearch.active == -1
    end
    def log_row_activated(widget, arg0, arg1)
      clear_most(nil)
    end
    def username_del(widget, arg0, arg1)
      clear_most(nil)
    end
    def tabfocus(widget, arg0, arg1)
      puts "tabfocus() is not implemented yet."
    end

    def save(widget)
      attrs = {}

      ALLFIELDS.each do |k|
        #v = _get_widget(k).text.strip
        v = @glade.get_widget(k).text.strip
        fld = fix(k)
        attrs[fld] = v unless v.nil? or v.empty?
      end
      if attrs["address1"] and attrs["address2"]
        attrs["address"] = attrs["address1"] + ", " + attrs["address2"]
      elsif attrs["address1"]
        attrs["address"] = attrs["address1"]
      elsif attrs["address2"]
        attrs["address"] = attrs["address2"]
      end
      attrs.delete "address1"
      attrs.delete "address2"

      attrs["status"] = @statushashi[@status.active]

      begin
        $client.person_save!(attrs)
        @notification.text =  "Person succesfully saved, clearing the form..."
        sleep 2
        clear_all(nil)
        _update_names
      rescue Exception => e
        @notification.text =  "Error: Save: #{e.message}"
      end
    end

    def fix(field)
      case field
      when "firstname"
      "first_name"
      when "lastname"
      "last_name"
      when "rolnummer"
      "rolnr"
      when "mobile"
      "gsm"
      else
        field
      end
    end

    def find(widget)
      attrs = {}

      FIELDS.each do |k|
        #v = _get_widget(k).text.strip
        v = @glade.get_widget(k).text.strip
        fld = fix(k)
        attrs[fld] = v unless v.nil? or v.empty?
      end

      begin
        people = $client.person_lookup(attrs)
        _show(people[0]) if people.size == 1
        _update_names(people)
      rescue Exception => e
        @notification.text =  "Error: Lookup: #{e.message}"
      end

    end


    def notification_focus_in_event_cb(widget, arg0)
      puts "notification_focus_in_event_cb() is not implemented yet."
    end
    def username_ins(widget, arg0, arg1, arg2)
      puts "username_ins() is not implemented yet."
    end
    def select (widget, path, column)
      iter = widget.model.get_iter(path)
      clear_all(nil)
      u = $client.person_lookup("username", iter[0].username.to_s)[0]
      _show(u)
    end

    def clear_all(widget, clearnotification=true)
      @username.text = ""
      clear_most(widget,clearnotification)
      @people_view.grab_focus
    end

    def clear_most(widget, clearnotification=true)
      @email.text = ""
      @firstname.text = ""
      @lastname.text = ""
      @barcode.text = ""
      @phone.text = ""
      @rolnummer.text = ""
      @mobile.text = ""
      @address1.text = ""
      @address2.text = ""
      @notification.text = "" if clearnotification
      #@statussearch.active = 0
      @status.active = -1
      @history_store.clear
    end


    private

    def _update_hist(username, clear=true)
      @history_store.clear if clear
      Thread.new do
        hist = $client.person_memberships(username)
        hist.each do |m|
          @history_store.append[0] = m
        end
      end
    end


    def _update_names(people=nil, clear=true)
      @notification.text = "loading people..."
      @people_store.clear if clear
      Thread.new do
        if people.nil?
          case @statussearch.active
          when -1
            people = $client.person_people
          when 0
            people = $client.person_people
          when 1
            people = $client.person_debuggers
          when 2
            people = $client.person_members
          when 3
            people = $client.person_nonmembers
          when 4
            people = $client.person_honorarymembers
          end
        else
          @statussearch.active = -1
        end

        people.sort! do |a,b|
          x = a.last_name.capitalize <=> b.last_name.capitalize
          x == 0 ? a.first_name <=> b.first_name : x
        end

        @people_view.model = nil
        @people_store.clear if clear

        people.each do |p|
          row = @people_store.append
          row[0] = p
          row[1] = (p.last_name.capitalize + " " + p.first_name.capitalize).smaller(20)
        end

        @people_view.model = @people_store
        @notification.text = ""
      end
    end


    def _show(person)
      #puts "DEBUG: #{person.inspect}"
      begin
        @username.text = person["username"]
        @email.text = person["email"]
        @firstname.text = person["first_name"]
        @lastname.text = person["last_name"]
        @phone.text = person["phone"]
        @rolnummer.text = person["rolnr"]
        @mobile.text = person["gsm"]
        addr = person["address"]
        unless addr.nil? or addr.strip.empty?
          addr.gsub!(/\n/, " , ")
          addrm = addr.match(/(((\w|\.|\-|\/|\(|\))+\s+)+\d+\w{0,1}(\s+\w\s+){0,1})((\s+|\s*\,\s*)\d*(\s+(\w|\.|\-|\/|\(|\))+)+)/)
          #if addrm.nil?
          #addrm = addr.match(/((\w|\.|-|\s)+\s*\d*\s*(\w|\.|-)*)(\s+|\s*\,\s*)*(\d*\s*(\w|\.|-|\s)+)/)
          #end
          if not addrm.nil? 
            @address1.text = addrm[1].strip unless addrm[1].nil?
            @address2.text = addrm[5].gsub(/\,/, "").strip unless addrm[5].nil?
          elsif ((not addr.nil?) and (not addr.strip.empty?))
            @address1.text = addr
          end
        end
        @mobile.text = person["gsm"]
        #@status.text = $client.person_status(username)
        membership = $client.person_membership(person["username"])
        @barcode.text = membership.barcode unless membership.nil? 
        status = $client.person_status(person["username"])
        @status.active = @statushash[status]
        _update_hist(person["username"])
        @notification.text = "the ig3tool imps found #{person["username"]}..."
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

  register_window(PeopleWindow)

end
