require 'gettext'
require 'time'

module Ig3tool

  class InterneWindow < GladeHelper
    include GetText

    MENU_PATH = ["Interne", "Interne"]
    ICON = "piggy_xsmall.png"



    def initialize
      super("newinterne.glade")


      @action = @glade.get_widget("action")
      @notification = @glade.get_widget("notification")
      @message = @glade.get_widget("message")
      @amount = @glade.get_widget("amount")
      @saldo = @glade.get_widget("saldo")
      @from = @glade.get_widget("fromcombo")
      @to = @glade.get_widget("tocombo")

      @transactions = @glade.get_widget("transactions")
      @transactions.model = @transactions_store = Gtk::ListStore.new(Object, String, String, String, String, String)
      l = Gtk::CellRendererText.new
      @transactions.insert_column(-1, "time", l) do |tvc, cell, m, iter|
				cell.text = Time.parse(iter[0].time).strftime("%d/%m/%y")
      end
      @transactions.insert_column(-1, "amount", l) do |tvc, cell, m, iter|
						cell.text = iter[0].amount.from_c.to_s
      end
      @transactions.insert_column(-1, "from", l) do |tvc, cell, m, iter|
						cell.text = iter[0].donor
      end
      @transactions.insert_column(-1, "to", l) do |tvc, cell, m, iter|
	        	cell.text = iter[0].recipient
      end
      @transactions.insert_column(-1, "message", l) do |tvc, cell, m, iter|
        		cell.text = iter[0].message
      end

      add_window_colorer(@from, @window)

      @amount.text = "0.0"
      #@window.signal_connect("activate-focus") do
      #  @notification.text = "refreshing..."
      #  _update_debuggers
      #  @notification.text = "refresh done"
      #end

      _update_debuggers
      _update_transactions

    end

    def refresh(widget)
      from = @from.active
      fromusername = @internes[from-1].username
      setaction(from, @to.active)
      _update_debuggers_nothread
      @from.active = from
      puts "DEBUG: #{fromusername}"
      interne = $client.interne(fromusername)
      @saldo.text = interne.saldo.from_c.to_s unless from == 0
      @saldo.text = "unlimited moneyz" if from == 0
      if from == 0
        _update_transactions
      else
        _update_transactions(fromusername)
      end
    end

    def tochange(widget)
      setaction(@from.active, @to.active)
    end
    def fromchange(widget)
      setaction(@from.active, @to.active)
      fromusername = @internes[@from.active-1].username
      if @from.active != 0
        interne = $client.interne(fromusername)
        @saldo.text = interne.saldo.from_c.to_s
      end
      @saldo.text = "unlimited moneyz" if @from.active == 0
      if @from.active == 0
        _update_transactions
      else
        fromusername = @internes[@from.active - 1].username 
        _update_transactions(fromusername)
      end
    end
    def tossmoney(widget)
      if @from.active == 0
        fromusername = "kas"
      else
        fromusername = @internes[@from.active-1].username 
      end
      if @to.active == 0
        tousername = "kas"
      else
        tousername = @internes[@to.active-1].username
      end
      begin
        amount = @amount.text
        raise Ig3tool::IG3Error, "uncorrect format for amount" unless amount =~ /\d+(\.\d{1,2}){0,1}/
        message = @message.text.strip
        message = "No message" if message.nil? or message.empty?
        $client.interne_transfer!("from" => fromusername, "to" => tousername, "amount" => @amount.text.strip.to_c, "message" => message) 
        _clear
        _update_transactions(fromusername)
        @notification.text = "transferred #{amount} EUR from #{fromusername} to #{tousername}"
      rescue Exception => e
        @notification.text = e.message
      end
    end
    def setaction(from, to)
      if from == 0
        fromusername = "kas"
      else
        fromusername = @internes[from-1].username 
      end
      if to == 0
        tousername = "kas"
      else
        tousername = @internes[to-1].username
      end
      @action.set_markup("toss money from <b>#{fromusername}</b> to <b>#{tousername}</b>")
      @action.set_markup("retract money from kas") if fromusername == "kas"
      @action.set_markup("deposit money to your interne") if tousername == "kas"
      @action.set_markup("money masturbation detected!") if from == to
    end


    private


    def _clear
      @amount.text = "0.0"
      @message.text = ""
      @saldo.text = ""
      from = @from.active
      to = @to.active
      _update_debuggers
      @from.active = from
      @to.active = to
    end
    
    def _update_debuggers_nothread
        begin
          @internes = $client.internes
          from_model = Gtk::ListStore.new(Object, String)
          to_model = Gtk::ListStore.new(Object, String)

          empty = from_model.append
          empty[0] = nil
          empty[1] = "kas"
          empty2 = to_model.append
          empty2[0] = nil
          empty2[1] = "kas"

          @internes.each do |s|
            row    = from_model.append
            row[0] = s
            row[1] = s.username
            row2    = to_model.append
            row2[0] = s
            row2[1] = s.username
          end

          @from.model = from_model
          @from.active = 0
          @from.clear
          renderer = Gtk::CellRendererText.new
          @from.pack_start(renderer, true)
          @from.set_attributes(renderer, :text => 1)
          @to.model = to_model
          @to.active = 0
          @to.clear
          renderer = Gtk::CellRendererText.new
          @to.pack_start(renderer, true)
          @to.set_attributes(renderer, :text => 1)
        rescue Exception => e
          @notification.text = e.to_s + e.message
        end
    end


    def _update_debuggers
      Thread.new do
        begin
          @internes = $client.internes
          from_model = Gtk::ListStore.new(Object, String)
          to_model = Gtk::ListStore.new(Object, String)

          empty = from_model.append
          empty[0] = nil
          empty[1] = "kas"
          empty2 = to_model.append
          empty2[0] = nil
          empty2[1] = "kas"

          @internes.each do |s|
            row    = from_model.append
            row[0] = s
            row[1] = s.username
            row2    = to_model.append
            row2[0] = s
            row2[1] = s.username
          end

          @from.model = from_model
          @from.active = 0
          @from.clear
          renderer = Gtk::CellRendererText.new
          @from.pack_start(renderer, true)
          @from.set_attributes(renderer, :text => 1)
          @to.model = to_model
          @to.active = 0
          @to.clear
          renderer = Gtk::CellRendererText.new
          @to.pack_start(renderer, true)
          @to.set_attributes(renderer, :text => 1)
        rescue Exception => e
          @notification.text = e.to_s + e.message
        end
      end
    end

    def _update_transactions(name=nil)
      @notification.text = "loading log..."
      @transactions_store.clear
#			tmp_store = Gtk::ListStore.new(Object,String,String,String,String,String)
      Thread.new do 
        begin
          if name.nil?
            transactionslines = $client.interne_log("foo") # DEBUG: remove foo
						# this causes the ui to be broken, possibly too many inserts
						# => fix by limiting # elements in log
          else
            transactionslines = $client.interne_log(name, 200)
          end
          transactionslines.each do |ll|
						if ll != nil then
#							tmp_store.append[0] = ll
							@transactions_store.append[0] = ll
						end
          end
        rescue Exception => e
          @notification.text = e.message
        end
      end
#			@transactions_store = tmp_store
#			#@transactions.model = @transactions_store
      @notification.text = ""
    end



  end

  register_window(InterneWindow)

end



