require 'time'

class String

	def to_boolean
		return true if (self == "t" or self.to_i != 0)
		return false
	end

end

module Ig3tool

class ProtjesGlade < GladeHelper

	MENU_PATH = ["Producten", "Producten"]
	ICON = "doos_xsmall.png"

  attr :glade
  
def initialize
	super("protjes.xml")
		@tabs = @glade.get_object("tabs")

		# MANAGE TAB
		@manage_debuggers = @glade.get_object("add_debuggers")
		@manage_plebs = @glade.get_object("add_plebs")
		@manage_members = @glade.get_object("add_members")
		@manage_edit = @glade.get_object("add_edit")
		@add_notification = @glade.get_object("add_notification")
		@add_barcode = @glade.get_object("add_barcode")
		@add_name = @glade.get_object("add_name")
		@add_stock = @glade.get_object("add_stock")
		@add_prodcat = @glade.get_object("add_prodcat")
		@add_categories = @glade.get_object("add_categories")
		@continuous_stock = @glade.get_object("continuous_stock_check")

		@categories = $client.product_categories.collect {|x| x.name}.sort


		@add_products = @glade.get_object("add_products")
		@add_products.model = @add_products_store = Gtk::ListStore.new(Object, String)
		l = Gtk::CellRendererText.new
		@add_products.insert_column(-1, "product", l, :text => 1)
		@add_products.enable_search = true

		

		# PURCHASE TAB
		@purchase_debuggers_orig = @glade.get_object("purchase_debuggers_orig")
		@purchase_plebs_orig = @glade.get_object("purchase_plebs_orig")
		@purchase_members_orig = @glade.get_object("purchase_members_orig")
		@purchase_last = @glade.get_object("purchase_last")
		@purchase_debugger = @glade.get_object("purchase_debugger")
		@purchase_debuggers = @glade.get_object("purchase_debuggers")
		@purchase_plebs = @glade.get_object("purchase_plebs")
		@purchase_members = @glade.get_object("purchase_members")
		@purchase_barcode = @glade.get_object("purchase_barcode")
		@purchase_name = @glade.get_object("purchase_name")
		@purchase_stock = @glade.get_object("purchase_stock")
		@purchase_category = @glade.get_object("purchase_category")
		@purchase_categories = @glade.get_object("purchase_categories")
		@purchase_notification = @glade.get_object("purchase_notification")
		@purchase_amount = @glade.get_object("purchase_amount")
		@purchase_price = @glade.get_object("purchase_price")
		@purchase_date = @glade.get_object("purchase_date")
		@purchase_accept = @glade.get_object("purchase_accept")
    
		@purchase_products = @glade.get_object("purchase_products")
		@purchase_products.model = @purchase_products_store = Gtk::ListStore.new(Object, String)
		l = Gtk::CellRendererText.new
		@purchase_products.insert_column(-1, "product", l, :text => 1)
		@purchase_products.enable_search = true

		# STOCK TAB
		@stock_notification = @glade.get_object("stock_notification")
		@stock_categories = @glade.get_object("stock_categories")
		@stock_barcode = @glade.get_object("stock_barcode")
		@stock_stock = @glade.get_object("stock_stock")
		@stock_category = @glade.get_object("stock_category")
		@stock_name = @glade.get_object("stock_name")
		@stock_debugger = @glade.get_object("stock_debugger")
		@stock_stock_new = @glade.get_object("stock_stock_new")
		@stock_apply = @glade.get_object("stock_apply")
		
		@stock_products = @glade.get_object("stock_products")
		@stock_products.model = @stock_products_store = Gtk::ListStore.new(Object, String)
		l = Gtk::CellRendererText.new
		@stock_products.insert_column(-1, "product", l, :text => 1)
		@stock_products.enable_search = true

		# LOG TAB
		@log_notification = @glade.get_object("log_notification")
		@log_categories = @glade.get_object("log_categories")
		@log_barcode = @glade.get_object("log_barcode")
		@log_name = @glade.get_object("log_name")
		@log_products = @glade.get_object("log_products")
		@log_products.model = @log_products_store = Gtk::ListStore.new(Object, String)
		l = Gtk::CellRendererText.new
		@log_products.insert_column(-1, "product", l, :text => 1)
		@log_products.enable_search = true


		@purchase_log = @glade.get_object("purchase_log")
		@purchase_log.model = @purchase_log_store = Gtk::ListStore.new(Object, String, String, String, String, String)
		l = Gtk::CellRendererText.new
		@purchase_log.insert_column(-1, "time", l) do |tvc, cell, m, iter|
			cell.text = Time.parse(iter[0].time).strftime("%d/%m/%y")
		end
		@purchase_log.insert_column(-1, "barcode", l) do |tvc, cell, m, iter|
			cell.text = iter[0].product
		end
		@purchase_log.insert_column(-1, "debugger", l) do |tvc, cell, m, iter|
			cell.text = iter[0].debugger
		end
		@purchase_log.insert_column(-1, "amount", l) do |tvc, cell, m, iter|
			cell.text = iter[0].count
		end
		@purchase_log.insert_column(-1, "price", l) do |tvc, cell, m, iter|
			cell.text = iter[0].cost
		end

		# sales LOG TAB
		@slog_notification = @glade.get_object("slog_notification")
		@slog_categories = @glade.get_object("slog_categories")
		@slog_barcode = @glade.get_object("slog_barcode")
		@slog_name = @glade.get_object("slog_name")
		@slog_products = @glade.get_object("slog_products")
		@slog_products.model = @slog_products_store = Gtk::ListStore.new(Object, String)
		l = Gtk::CellRendererText.new
		@slog_products.insert_column(-1, "product", l, :text => 1)
		@slog_products.enable_search = true


		@spurchase_log = @glade.get_object("spurchase_log")
		@spurchase_log.model = @spurchase_log_store = Gtk::ListStore.new(Object, String, String, String, String, String, String)
		l = Gtk::CellRendererText.new
		@spurchase_log.insert_column(-1, "time", l) do |tvc, cell, m, iter|
			cell.text = Time.parse(iter[0].time).strftime("%d/%m/%y")
		end
		@spurchase_log.insert_column(-1, "barcode", l) do |tvc, cell, m, iter|
			cell.text = iter[0].product
		end
		@spurchase_log.insert_column(-1, "debugger", l) do |tvc, cell, m, iter|
			cell.text = iter[0].debugger
		end
		@spurchase_log.insert_column(-1, "status", l) do |tvc, cell, m, iter|
			cell.text = iter[0].status
		end
		@spurchase_log.insert_column(-1, "amount", l) do |tvc, cell, m, iter|
			cell.text = iter[0].count
		end
		@spurchase_log.insert_column(-1, "price", l) do |tvc, cell, m, iter|
			cell.text = iter[0].price
		end




		
		# ALL 
		
		cat_model = Gtk::ListStore.new(String)
		cat2_model = Gtk::ListStore.new(String)
		cat3_model = Gtk::ListStore.new(String)
		cat4_model = Gtk::ListStore.new(String)
		cat5_model = Gtk::ListStore.new(String)
		cat6_model = Gtk::ListStore.new(String)
		cat_model.prepend[0] = "all products"
		cat3_model.prepend[0] = "all products"
		cat4_model.prepend[0] = "all products"
		cat5_model.prepend[0] = "all products"
		cat6_model.prepend[0] = "all products"
		@categories.each do |cat|
			r    = cat_model.append
			r[0] = cat
			r2    = cat2_model.append
			r2[0] = cat
			r3    = cat3_model.append
			r3[0] = cat
			r4    = cat4_model.append
			r4[0] = cat
			r5    = cat5_model.append
			r5[0] = cat
			r6    = cat6_model.append
			r6[0] = cat
		end
		@add_categories.model  = cat_model
		@add_categories.active = 0
		@add_prodcat.model  = cat2_model
		@add_prodcat.active = -1
		@purchase_categories.model  = cat3_model
		@purchase_categories.active = 0
		@stock_categories.model  = cat4_model
		@stock_categories.active = 0
		@log_categories.model  = cat5_model
		@log_categories.active = 0
		@slog_categories.model  = cat6_model
		@slog_categories.active = 0

		@continuous_stock.active = false

		toggle_purchase_fields(false)
  	_add_clear
  	_purchase_clear
		
		#signal handlers
		@handler1 = @add_barcode.signal_connect("changed"){ barcode_changed }
		@handler2 = @purchase_barcode.signal_connect("changed"){ barcode_changed }
		@handler3 = @stock_barcode.signal_connect("changed"){ barcode_changed }
		@handler6 = @log_barcode.signal_connect("changed"){ barcode_changed }
		@handler7 = @log_barcode.signal_connect("activate"){ _log_show(@log_barcode.text.strip) ; _update_log(@log_barcode.text.strip) }

		@handler4 = @purchase_price.signal_connect("changed"){ price_amount_changed }
		@handler5 = @purchase_amount.signal_connect("changed"){ price_amount_changed }

		%w(focus-out-event activate).each do |s|
			@purchase_amount.signal_connect s do
				number_eval_widget(@purchase_amount, "0.0")
				if @purchase_price.text.strip.to_c == 0
					@purchase_price.text = (@purchase_amount.text.strip.to_i * @purchase_debuggers_orig.text.to_f).to_s
				end
				false
			end
		end
		#@handler8 = @add_categories.signal_connect("changed"){ refresh }
		@handler9 = @purchase_categories.signal_connect("changed"){ refresh }
		@handler10 = @stock_categories.signal_connect("changed"){ refresh }
		@handler11 = @log_categories.signal_connect("changed"){ refresh }
		@handler12 = @slog_categories.signal_connect("changed"){ refresh }
		
		@handler15 = @slog_barcode.signal_connect("changed"){ barcode_changed }
		@handler16 = @slog_barcode.signal_connect("activate"){ _slog_show(@log_barcode.text.strip) ; _update_slog(@log_barcode.text.strip) }

		make_debugger_combo(@purchase_debugger)
		make_debugger_combo(@stock_debugger)

		[@purchase_amount, @purchase_price, @purchase_plebs, @purchase_debuggers,
		 @purchase_members, @manage_debuggers, @manage_plebs, @manage_members,
		 @stock_stock_new].each do |w|
			make_eval_widget w
		end
		
    @handler69 = @purchase_debugger.signal_connect("changed"){ purchase_debugger_changed }
    @debugger_stamp = nil

  end

def purchase_debugger_changed
  puts "debugger changed"
  @debugger_stamp = Time.now
end

  def check_purchase_debugger_reset
    if @debugger_stamp.nil? or ((Time.now - @debugger_stamp).to_i > 300) 
      @purchase_debugger.active = -1
    end
  end

def get_debugger(widget)
	widget.active_iter[0]
end

	def price_amount_changed
		amount = @purchase_amount.text.strip.to_i
		price = @purchase_price.text.strip.to_c
		amount = @purchase_amount.text.strip.to_i
		@purchase_notification.text = "please enter a valid amount" if amount == 0
		@purchase_notification.text = "please enter a valid price (in euro's)" if price == 0
		if amount != 0  and price != 0
			begin
				@purchase_notification.text = "" 
				old = @purchase_debuggers_orig.text
				oldm = @purchase_members_orig.text
				oldp = @purchase_plebs_orig.text
				new = price.to_f / amount.to_f
				memb_ratio = (oldm.to_f / old.to_f)
				plebs_ratio = (oldp.to_f / old.to_f)
				newp = (new.to_f * plebs_ratio).to_i
				newm = (new.to_f * memb_ratio).to_i
				@purchase_debuggers.text = new.to_i.from_c.to_s
				@purchase_members.text = afronden(newm).from_c.to_s
				@purchase_plebs.text = afronden(newp).from_c.to_s
				#@purchase_accept.active = true
			rescue Exception => e
				@purchase_debuggers.text = new.to_i.from_c.to_s
				@purchase_members.text = afronden(new.to_i).from_c.to_s
				@purchase_plebs.text = afronden(new.to_i).from_c.to_s
				@purchase_notification.text = "no (smart) price suggestions could be made"
			end
		end
	end

	def afronden(i)
		m = i % 5
		case m
		when 0
			i
		when 1
			i - 1
		when 2
			i - 2
		when 3
			i + 2
		when 4
			i + 1
		end
	end



	def purchase
		begin
			if @purchase_accept.active?
				barcode = @purchase_barcode.text.strip
				$client.product_save!("barcode" => barcode, "dprice" => @purchase_debuggers.text.strip.to_c, "mprice" => @purchase_members.text.strip.to_c, "nmprice" => @purchase_plebs.text.strip.to_c)
			end

			raise "Refusing to update stock: price == 0 !" if @purchase_price.text.strip.to_c == 0
			$client.product_purchase!("debugger" => get_debugger(@purchase_debugger).username, "date" => @purchase_date.text.strip, "barcode" => @purchase_barcode.text.strip, "amount" => @purchase_amount.text.strip.to_i,  "price" => @purchase_price.text.strip.to_c)
			_purchase_clear
			@purchase_notification.text = "the imps noted this purchase..."	
		rescue Exception => e
			@purchase_notification.text = e.message
		end
	end
  
  def members_act(widget)
	end

	def barcode_ins(widget, arg0, arg1, arg2)
	end

	def barcode_del(widget, arg0, arg1)
	end

	def barcode_changed()
		case @tabs.page
		when 0
			_purchase_clear(false)
			toggle_purchase_fields(false)
		when 1
			_purchase_clear(false)
			toggle_purchase_fields(false)
		when 2
			_stock_clear(false)
			toggle_stock_field(false)
		when 3
			_log_clear(false)
		when 4
			_slog_clear(false)
		end
	end

	def toggle_price_fields(from_save, bool=nil)
    # if from_save  = true the saving of prices gets skipped
		bool = (not @manage_debuggers.sensitive?) if bool.nil?
		@manage_debuggers.sensitive = bool
		@manage_debuggers.editable = bool
		@manage_plebs.sensitive = bool
		@manage_plebs.editable = bool
		@manage_members.sensitive = bool
		@manage_members.editable = bool
		if bool
			@manage_edit.image = Gtk::Image.new(Gtk::Stock::SAVE, Gtk::IconSize::BUTTON)
			@manage_edit.label = Gtk::Stock::SAVE
		else
			unless from_save
				begin
					barcode = @add_barcode.text.strip
					$client.product_save!("barcode" => barcode, "dprice" => @manage_debuggers.text.strip.to_c, "mprice" => @manage_members.text.strip.to_c, "nmprice" => @manage_plebs.text.strip.to_c)

					@add_notification.text = "prices saved!"
					_add_show(barcode)
				rescue Exception => e
					puts e.backtrace
					@add_notification.text = e.message
				end
			end
			@manage_edit.image = Gtk::Image.new(Gtk::Stock::EDIT, Gtk::IconSize::BUTTON)
			@manage_edit.label = Gtk::Stock::EDIT
		end
	end

	def toggle_purchase_fields(bool)
		@purchase_debuggers.sensitive = bool
		@purchase_debuggers.editable = bool
		@purchase_plebs.sensitive = bool
		@purchase_plebs.editable = bool
		@purchase_members.sensitive = bool
		@purchase_members.editable = bool
		#@purchase_date.sensitive = bool
		#@purchase_date.editable = bool
		@purchase_amount.sensitive = bool
		@purchase_amount.editable = bool
		@purchase_price.sensitive = bool
		@purchase_price.editable = bool
	end

	def toggle_stock_field(bool)
		@stock_stock_new.sensitive = bool
		@stock_stock_new.editable = bool
	end

  def add_edit(widget)
		toggle_price_fields(false)
  end

  def smart_search(widget)
		case @tabs.page
		when 0
			barcode = @add_barcode.text.strip
			_add_show(barcode)
			_purchase_show(barcode)
		when 1
			barcode = @purchase_barcode.text.strip
			_add_show(barcode)
			_purchase_show(barcode)
		when 2
			barcode = @stock_barcode.text.strip
			_stock_show(barcode)
		when 3
			barcode = @stock_barcode.text.strip
			_log_show(barcode)
		when 4
			barcode = @stock_barcode.text.strip
			_slog_show(barcode)
		end
  end

  def plebs_act(widget)
  end

  def add_cancel(widget)
		toggle_price_fields(true, false)
		_add_clear
  end
	def log_cancel(w)
		_log_clear
    _update_log
	end
	def slog_cancel(w)
		_slog_clear
    _update_slog
	end
	def to_purchase(w)
		@tabs.page = 1
	end
	def refreshlog(w)
		barcode = @log_barcode.text.strip
		begin
			p = $client.product_lookup(barcode)
			_update_log(barcode)
		rescue Needed => e
			_update_log
		end
	end
	def refresh_slog(w)
		barcode = @slog_barcode.text.strip
		begin
			p = $client.product_lookup(barcode)
			_update_slog(barcode)
		rescue Needed => e
			_update_slog
		end
	end

  def changed(widget)
    #puts "changed() is not implemented yet."
  end

  def stock_cancel(widget)
		_stock_clear
  end

  def price_del(widget, arg0, arg1)
  end

  def stock_apply(widget)
		begin
			raise IG3Error, "select a debugger please!" if @stock_debugger.active == -1
			bar = @stock_barcode.text.strip
		$client.product_adjust_stock!("barcode" => bar, "stock" => @stock_stock_new.text.strip.to_i, "debugger" => get_debugger(@stock_debugger).username)
		_stock_clear
		@stock_notification.text = "stock update saved!"
		_stock_show(bar)
		rescue Exception => e
		@stock_notification.text = e.message
		end
  end

	def add_delete(w)
		begin
		barcode = @add_barcode.text.strip
		$client.product_remove!("barcode" => barcode)
		_add_clear
	  _update_add_products(false)
		rescue Exception => e
			@add_notification.text = e.message
		end
	end

  def refresh(widget=nil)
		case @tabs.page
		when 0
		_update_add_products(false)
		when 1
		_update_purchase_products(false)
		when 2
		_update_stock_products(false)
		when 3
		_update_log_products(false)
		when 4
		_update_slog_products(false)
		end
  end

  def debuggers_act(widget)
  end

  def accept_toogled(widget)
  end

  def purchase_cancel(widget)
		_purchase_clear
    check_purchase_debugger_reset
  end

  def price_ins(widget, arg0, arg1, arg2)
  end

  def tabfocus(widget, a, b)
		case b
		when 0
			_update_add_products
		when 1
			_update_purchase_products
      check_purchase_debugger_reset
		when 2
			_update_stock_products
		when 3
			_update_log_products
			_update_log
		when 4
			_update_slog_products
			_update_slog
		end
  end

  def notification_focus_in_event_cb(widget, arg0)
  end

  def stock_to_apply(widget)
		@stock_apply.grab_focus
  end

	def add_apply(widget)
		begin
			@add_notification.text = "saving product..."
			toggle_price_fields(true, false)
      barcode = @add_barcode.text.strip
			raise Needed, "please scan a barcode" if @add_barcode.text.strip.empty?
			raise Needed, "please enter a descriptive name" if @add_name.text.strip.empty?
			raise Needed, "please select a category" if @add_prodcat.active == -1
			if @continuous_stock.active?
				cs = 1
			else
				cs = 0
			end
			$client.product_save!("barcode" => @add_barcode.text.strip, "name" => @add_name.text.strip, "continuous_stock" => cs, "dprice" => @manage_debuggers.text.strip.to_c, "mprice" => @manage_members.text.strip.to_c, "nmprice" => @manage_plebs.text.strip.to_c, "category" => @categories[@add_prodcat.active])
			_update_add_products(false)
			@add_notification.text = "the imps saved the product!"
			_add_clear(false)
      _add_show(barcode)
      _purchase_show(barcode)
		rescue Exception => e
			@add_notification.text = e.message
		end
	end

  def select(widget, path, column)
		prodentry = widget.model.get_iter(path)
		_add_show(prodentry[0].barcode)
		_purchase_show(prodentry[0].barcode)
  end
  def purchase_select(widget, path, column)
		prodentry = widget.model.get_iter(path)
		_add_show(prodentry[0].barcode)
		_purchase_show(prodentry[0].barcode)
  end
  def stock_select(widget, path, column)
		prodentry = widget.model.get_iter(path)
		_stock_show(prodentry[0].barcode)
  end
  def log_select(widget, path, column)
		prodentry = widget.model.get_iter(path)
		barcode = prodentry[0].barcode
		_log_show(barcode)
		_update_log(barcode)
  end
  def select_from_log(widget, path, column)
		prodentry = widget.model.get_iter(path)
		barcode = prodentry[0].product
		_log_show(barcode)
		_update_log(barcode)
  end
  def slog_select(widget, path, column)
		prodentry = widget.model.get_iter(path)
		barcode = prodentry[0].barcode
		_slog_show(barcode)
		_update_slog(barcode)
  end
  def select_from_slog(widget, path, column)
		prodentry = widget.model.get_iter(path)
		barcode = prodentry[0].product
		_slog_show(barcode)
		_update_slog(barcode)
  end




	private

	def _add_show(barcode)
		begin
			@add_barcode.signal_handler_block(@handler1)
			prod = $client.product_lookup(barcode)
			@manage_members.text = prod.mprice.from_c.to_s
			@manage_debuggers.text = prod.dprice.from_c.to_s
			@manage_plebs.text = prod.nmprice.from_c.to_s
			@add_barcode.text = prod.barcode
			@add_stock.text = prod.stock
			@add_name.text = prod.name
			puts prod.continuous_stock.class
			puts prod.continuous_stock
			@continuous_stock.active = prod.continuous_stock.to_boolean
			@add_prodcat.active = @categories.index(prod.category)
		rescue Exception => e
			@add_notification.text = e.message
		ensure
			@add_barcode.signal_handler_unblock(@handler1)
		end
	end
	
	def _purchase_show(barcode)
		begin
			@purchase_barcode.signal_handler_block(@handler2)
			prod = $client.product_lookup(barcode)
			@purchase_members_orig.text = prod.mprice.from_c.to_s
			@purchase_debuggers_orig.text = prod.dprice.from_c.to_s
			@purchase_plebs_orig.text = prod.nmprice.from_c.to_s
			@purchase_barcode.text = prod.barcode
			@purchase_stock.text = prod.stock
			@purchase_name.text = prod.name
			@purchase_category.text = prod.category
			price_amount_changed
			if prod.continuous_stock.to_boolean
				toggle_purchase_fields(false)
				@purchase_notification.text = "this product has a continuous stock"
			else
				toggle_purchase_fields(true)
			end
      Thread.new do
        ps = $client.product_purchases(barcode)
        last_purchase = ps.first
			  date = Time.parse(last_purchase.time).strftime("%d/%m/%y")
        @purchase_last.text = date
      end
		rescue Exception => e
			@purchase_notification.text = e.message
		ensure
			@purchase_barcode.signal_handler_unblock(@handler2)
		end
	end
	def _stock_show(barcode)
		begin
			@stock_barcode.signal_handler_block(@handler3)
			prod = $client.product_lookup(barcode)
			@stock_barcode.text = prod.barcode
			@stock_stock.text = prod.stock
			@stock_name.text = prod.name
			@stock_category.text = prod.category
			toggle_stock_field(true)
		rescue Exception => e
			@stock_notification.text = e.message
		ensure
			@stock_barcode.signal_handler_unblock(@handler3)
		end
	end
	def _log_show(barcode)
		begin
			@log_barcode.signal_handler_block(@handler6)
			prod = $client.product_lookup(barcode)
			@log_barcode.text = prod.barcode
			@log_name.text = prod.name
		rescue Exception => e
			@log_notification.text = e.message
		ensure
			@log_barcode.signal_handler_unblock(@handler6)
		end
	end
	def _slog_show(barcode)
		begin
			@slog_barcode.signal_handler_block(@handler15)
			prod = $client.product_lookup(barcode)
			@slog_barcode.text = prod.barcode
			@slog_name.text = prod.name
		rescue Exception => e
			@slog_notification.text = e.message
		ensure
			@slog_barcode.signal_handler_unblock(@handler15)
		end
	end
	
	def _update_add_products(verbose=true)
		Thread.new do
			begin
				category = @add_categories.active_iter[0]
				@add_notification.text = "loading products..." if verbose
				@add_products.model = nil
				@add_products_store.clear
				prods = $client.product_all.sort{|x,y| x.name.downcase <=> y.name.downcase}
				prods.delete_if{|p| p.category != category} unless category == "all products"
				prods.each do |p|
					row = @add_products_store.append
					row[1] = p.name
					row[0] = p
				end
				@add_products.model = @add_products_store
				#@add_notification.text = "products loaded..." if verbose
				@add_notification.text = "" 
			rescue Exception => e
				@add_notification.text = e.message
			end
		end
	end
	
	def _update_purchase_products(verbose=true)
		Thread.new do
			begin
				category = @purchase_categories.active_iter[0]
				@purchase_notification.text = "loading products..." if verbose
				@purchase_products.model = nil
				@purchase_products_store.clear
				prods = $client.product_all.sort{|x,y| x.name.downcase <=> y.name.downcase}
				prods.delete_if{|p| p.category != category} unless category == "all products"
				prods.each do |p|
					row = @purchase_products_store.append
					row[1] = p.name
					row[0] = p
				end
				@purchase_products.model = @purchase_products_store
				#@purchase_notification.text = "products loaded..." if verbose
				@purchase_notification.text = "" if verbose
			rescue Exception => e
				@purchase_notification.text = e.message
			end
		end
	end
	
	def _update_stock_products(verbose=true)
		Thread.new do
			begin
				category = @stock_categories.active_iter[0]
				@stock_notification.text = "loading products..." if verbose
				@stock_products.model = nil
				@stock_products_store.clear
				prods = $client.product_all.sort{|x,y| x.name.downcase <=> y.name.downcase}
				prods.delete_if{|p| p.category != category} unless category == "all products"
				prods.each do |p|
					row = @stock_products_store.append
					row[1] = p.name
					row[0] = p
				end
				@stock_products.model = @stock_products_store
				#@stock_notification.text = "products loaded..." if verbose
				@stock_notification.text = "" if verbose
			rescue Exception => e
				@stock_notification.text = e.message
			end
		end
	end

	def _update_log_products(verbose=true)
		Thread.new do
			begin
				category = @log_categories.active_iter[0]
				@log_notification.text = "loading products..." if verbose
				@log_products.model = nil
				@log_products_store.clear
				prods = $client.product_all.sort{|x,y| x.name.downcase <=> y.name.downcase}
				prods.delete_if{|p| p.category != category} unless category == "all products"
				prods.each do |p|
					row = @log_products_store.append
					row[1] = p.name
					row[0] = p
				end
				@log_products.model = @log_products_store
				#@log_notification.text = "products loaded..." if verbose
				@log_notification.text = "" if verbose
			rescue Exception => e
				@log_notification.text = e.message
			end
		end
	end
	def _update_slog_products(verbose=true)
		Thread.new do
			begin
				category = @slog_categories.active_iter[0]
				@slog_notification.text = "loading products..." if verbose
				@slog_products.model = nil
				@slog_products_store.clear
				prods = $client.product_all.sort{|x,y| x.name.downcase <=> y.name.downcase}
				prods.delete_if{|p| p.category != category} unless category == "all products"
				prods.each do |p|
					row = @slog_products_store.append
					row[1] = p.name
					row[0] = p
				end
				@slog_products.model = @slog_products_store
				#@log_notification.text = "products loaded..." if verbose
				@slog_notification.text = "" if verbose
			rescue Exception => e
				@slog_notification.text = e.message
			end
		end
	end

	def _add_clear(all=true)
		@manage_members.text = "0.0"
		@manage_debuggers.text = "0.0"
		@manage_plebs.text = "0.0"
		@add_barcode.text = "" if all
		@add_stock.text = ""
		@add_name.text = ""
		@add_prodcat.active = -1
		@add_notification.text = "" if all
		@continuous_stock.active = false
	end

	def _purchase_clear(all=true)
		@purchase_members_orig.text = "0.0"
		@purchase_debuggers_orig.text = "0.0"
		@purchase_plebs_orig.text = "0.0"
		@purchase_members.text = ""
		@purchase_debuggers.text = ""
		#@purchase_debugger.active = -1
    check_purchase_debugger_reset
		@purchase_plebs.text = ""
		@purchase_barcode.text = "" if all
		@purchase_stock.text = ""
		@purchase_last.text = ""
		@purchase_amount.text = ""
		@purchase_price.text = ""
		@purchase_date.text = Time.now.strftime("%Y-%m-%d")
		@purchase_name.text = ""
		@purchase_category.text = ""
		@purchase_notification.text = "" if all
	end
	def _stock_clear(all=true)
		@stock_barcode.text = "" if all
		@stock_stock.text = ""
		@stock_stock_new.text = ""
		@stock_name.text = ""
		@stock_category.text = ""
		@stock_notification.text = "" if all
	end
	def _log_clear(all=true)
		@log_barcode.text = "" if all
		@log_name.text = ""
		@log_notification.text = "" if all
	end
	def _slog_clear(all=true)
		@slog_barcode.text = "" if all
		@slog_name.text = ""
		@slog_notification.text = "" if all
	end


	def _update_log(barcode=nil)
		@purchase_log_store.clear 
		Thread.new do
			begin
			ps = $client.product_purchases
			if not barcode.nil?
				ps.delete_if{|p| p.product != barcode}
			end
			ps.each do |ll|
				@purchase_log_store.append[0] = ll
			end
			rescue Exception => e
				@log_notification.text = e.message
			end
		end
	end
	def _update_slog(barcode=nil)
		@spurchase_log_store.clear 
		Thread.new do
			begin
			ps = $client.product_sales
			if not barcode.nil?
				ps.delete_if{|p| p.product != barcode}
			end
			ps.each do |ll|
				@spurchase_log_store.append[0] = ll
			end
			rescue Exception => e
				@slog_notification.text = e.message
			end
		end
	end







end

register_window(ProtjesGlade)

end
