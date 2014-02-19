require 'time'
require 'gettext'

module Ig3tool

	class BibliotheekWindow < GladeHelper
		include GetText

		MENU_PATH = ["Bibliotheek", "Bibliotheek"]
		ICON = "stock_book_xklein.png"

		attr :glade

		#  def initialize(path_or_data, root = nil, domain = nil, localedir = nil, flag = GladeXML::FILE)
		#  bindtextdomain(domain, localedir, nil, "UTF-8")
		# @glade = GladeXML.new(path_or_data, root, domain, localedir, flag) {|handler| method(handler)}
		#
		def initialize

			super("bibliotheek.xml")

			# $client = Client.new("infogroep.be")

			@tabs = @glade.get_object("tabs")

			@books_isbn      = @glade.get_object("books_isbn")
			@books_title     = @glade.get_object("books_title")
			@books_author    = @glade.get_object("books_author")
			@books_publisher = @glade.get_object("books_publisher")
			@books_year      = @glade.get_object("books_year")
			@books_section   = @glade.get_object("books_section")
			@books_copies    = @glade.get_object("books_copies")

			@books_fields = {
			"isbn" => @books_isbn, 
			"title" => @books_title, 
			"author" => @books_author, 
			"publisher" => @books_publisher, 
			"year" => @books_year, 
			"copies" => @books_copies
			}


			@books_notification    = @glade.get_object("books_notification")

			@loan_memberid   = @glade.get_object("loan_memberid")
			@loan_isbn       = @glade.get_object("loan_isbn")
			@loan_title       = @glade.get_object("loan_title")
			@loan_warranty   = @glade.get_object("loan_warranty")
			@loan_notification    = @glade.get_object("loan_notification")

			@loan_fields = {
			"isbn" => @loan_isbn,
			"warranty" => @loan_warranty,
			"member" => @loan_memberid
			}

			@books_list   = @glade.get_object("books_list")
			@loan_list    = @glade.get_object("loan_list")
			@loan_list.model = @loan_list_store = Gtk::ListStore.new(Object, String, String, String, String, String, String)
			ll = Gtk::CellRendererText.new
			@loan_list.insert_column(-1, "loan date", ll) do |tvc, cell, m ,iter|
			cell.text = Time.parse(iter[0].loan_date).strftime("%d/%m/%y")
			end
			@loan_list.insert_column(-1, "return on", ll) do |tvc, cell, m ,iter|
			date = Time.parse(iter[0].return_date)
			ll.foreground = "red" if date > Time.now
			cell.text = date.strftime("%d/%m/%y")
			ll.foreground = "black"
			end
			@loan_list.insert_column(-1, "username", ll) do |tvc, cell, m ,iter|
			cell.text = $client.person_member(iter[0].member_id).username
			end
			@loan_list.insert_column(-1, "memberid", ll) do |tvc, cell, m ,iter|
			cell.text = iter[0].member_id
			end
			@loan_list.insert_column(-1, "isbn", ll) do |tvc, cell, m ,iter|
			cell.text = iter[0].isbn
			end
			@loan_list.insert_column(-1, "warranty", ll) do |tvc, cell, m ,iter|
			cell.text = iter[0].warranty
			end

			@books_list = @glade.get_object("books_list")
			@books_list.model = @books_list_store = Gtk::ListStore.new(Object, String)
			bl = Gtk::CellRendererText.new
			@books_list.insert_column(-1, "title", bl) do |tvc, cell, m ,iter|
			cell.text = (iter[0].title.smaller(50) + " (#{iter[0].author})").smaller(62)
			end


			_update_sections
			_update_books_list
			_update_loan_list


		end

		def select_book(widget, path, column)
			iter = widget.model.get_iter(path)
			_show iter[0]
		end

		def select_loan(widget, path, column)
			iter = widget.model.get_iter(path)
			@loan_isbn.text = iter[0].isbn
			loan_isbn_set(nil)
			@loan_memberid.text = iter[0].member_id
			@loan_warranty.text = iter[0].warranty
		end


		def select_section()
			#Thread.new do
			#  if @books_section.active_iter[0].nil?
			#    books = nil
			#  else
			#    books = $client.bib_lookup({"section" => @books_section.active_iter[0].name})
			#  end
			#  _update_books_list(books)
			#end
		end

		def get_fields(ignore_empty = true)
			fields = {}
			@books_fields.each do |k, f|
				temp = f.text.strip
				fields[k] = temp unless temp.empty? and ignore_empty
			end
			fields["section"] = @books_section.active_iter[0].name unless @books_section.active_iter[0].nil?
			fields
		end

		def get_loan_fields
			fields = {}
			@loan_fields.each do |k, f|
				fields[k] = f.text unless f.text.strip.empty?
			end
			fields
		end

		def books_save(widget)
			begin
				$client.bib_add!(get_fields(false))
				_update_books_list
				#books_clear
				@books_notification.text = "changes saved to book!"
			rescue Exception => e
				puts e.backtrace
				@books_notification.text = e.message.smaller
			end

		end
		def loan_extend(widget)
			begin
				$client.bib_extend!(get_loan_fields)
				_update_loan_list
				loan_clear(nil)
				@loan_notification.text = "the ig3tool imps extend the book for 3 weeks..."
			rescue Exception => e
				puts e.backtrace
				@loan_notification.text = e.message.smaller
			end
		end

		def hl_loan(a)
		end

		def loan_return(widget)
			begin
				$client.bib_return!(get_loan_fields)
				_update_loan_list
				loan_clear(nil)
				@loan_notification.text = "book returned to the ig3tool imps..."
			rescue Exception => e
				puts e.backtrace
				@loan_notification.text = e.message.smaller
			end
		end

		def books_delete(widget)
			begin
				$client.bib_remove!(@books_isbn.text.strip)
				_update_books_list
				reset_books_fields
				@books_notification.text = "the ig3tool imps trashed the book..."
			rescue Exception => e
				puts e.backtrace
				@loan_notification.text = e.message.smaller
			end
		end

		def loan_refresh(widget)
			_update_loan_list
		end

		def books_refresh(widget)
			_update_books_list
		end

		def tabfocus(widget, arg0, arg1)
			if arg1 == 1
				_update_loan_list
			else
				_update_books_list
			end
		end

		def isbn_ins(a,b,c)
			reset_books_fields(false)
		end
		def isbn_del(a,b,c,d)
			reset_books_fields(false)
		end
		def loan_isbn_ins(a,b,c,d)
			@loan_title.text = ""
		end
		def loan_isbn_del(a,b,c)
			@loan_title.text = ""
		end

		def loan_isbn_set(widget)
			begin
				book = $client.bib_info(@loan_isbn.text)
				raise Exception, "the ig3tool imps found no such book..." if book.nil?
				_show(book)
				#@loan_title.text = book.title
			rescue Exception => e
				puts e.backtrace
				@loan_notification.text = e.message.smaller
			end
		end


		def books_find(widget)
			Thread.new do
				begin
					books = $client.bib_lookup(get_fields)
					puts books
					case books.size
					when 0	#book not found in db
						_lookup_isbnbook(@books_isbn.text)
					when 1
						_show(books.first)
					else
						_update_books_list(books)
					end
				rescue Exception => e
					puts e.backtrace
					@books_notification.text = e.message.smaller
				end
			end
		end

		def reset_books_fields(all=true)
			@books_isbn.text = "" if all
			@loan_isbn.text = ""
			@books_title.text = ""
			@loan_title.text = ""
			@loan_memberid.text = ""
			@books_author.text = ""
			@books_publisher.text = ""
			@books_year.text = ""
			@books_copies.text = ""
			@books_section.active = 0
			@books_notification.text = ""
		end

		def books_clear(widget, all=true)
			reset_books_fields(all)
			#_update_books_list
		end


		def loan_clear(widget, all=true)
			@loan_isbn.text = ""
			@loan_memberid.text = ""
			@loan_warranty.text = "5"
			@loan_notification.text = "" if all
			@loan_title.text = ""
			reset_books_fields
		end

		def loan_loan(widget)
			@loan_notification.text = ""
			begin
				fields = get_loan_fields
				if fields["member"] =~ /[a-zA-Z]+/
					puts "username ipv barcode: #{fields["member"]}"
					membership = $client.person_membership(fields["member"])
					if membership.nil?
						raise IG3Error, "#{fields["member"]} is not a member..."
					else
						fields["member"] = membership.barcode
					end
				end
				$client.bib_loan!(fields)
				_update_loan_list
				loan_clear(nil)
			rescue Exception => e
				puts e.backtrace
				@loan_notification.text = e.message.smaller(65)
			end
		end

		def books_loan(widget)
			@tabs.page = 1
		end





		private


		def _lookup_amazon_isbn(isbn,update = true)
			begin
				require 'amazon/aws/search'
			rescue Exception => e
				STDERR.puts "Ruby/Amazon/Aws/Search kon niet geladen worden: " + e.to_s
				return {}
			end
			#voor amazon bestaan der 2 libs die sterk op elkaar lijke qua naam
			#juiste is: http://www.caliban.org/ruby/ruby-aws/

			bookhsh = {}
			token =  "1857ZGN71N9Z8AV4HE02"	#verplaats naar client
			associate = "wwwinfogroepb-20"
			#return false unless _isbn?(true,isbn) # Indien strenge test faalt
			# You need a amazon-dev-token in client.rb
			#token = CONFIG['amazon-dev-token']
			#return unless $amazon_loaded and token.instance_of?(String) and not token.empty?

			begin
				#req = Amazon::Search::Request.new(CONFIG["amazon-dev-token"],CONFIG["amazon-associates-id"])
				req = Amazon::AWS::Search::Request.new(token,associate)
				il = Amazon::AWS::ItemLookup.new("ASIN", {'ItemId' => isbn} )
				rg = Amazon::AWS::ResponseGroup.new
				res = req.search(il,rg)
				#dont ask, feel free to improve (numlock)
				books = res['item_lookup_response'].to_h
				moar_book = books['items'].to_h
				no_idea = moar_book['item']
				book = no_idea['item_attributes'].to_h

				title = book['product_name'].to_s.strip
				author = book['author'].to_s.strip
				publisher = book['manufacturer'].to_s.strip

				bookhsh.store(:title, title)			if title
				bookhsh.store(:author, author)			if author
				bookhsh.store(:publisher, publisher)	if publisher

				if update
					@books_title.text		= title
					@books_author.text		= author
					@books_publisher.text	= publisher
					@books_isbn.text		= isbn
				end
				bookhsh
			rescue Exception => e
				STDERR.puts e.message
				@books_notification.text = "Fout: Lookup Amazon: #{e.message.smaller}"
				{}
			end
		end

		def _lookup_isbndb_isbn(isbn,update = true)
			def fetch(uri_string, limit)		#follow redirects
				raise "Server loop" if limit < 0
				response = Net::HTTP.get_response(URI.parse(uri_string))
				case response
				when Net::HTTPSuccess	then response
				when Net::HTTPRedirection then fetch(response['location'], limit - 1)
				else
					response.error!
				end
			end
			def process_book(doc,isbn,update)
				bookhsh = {}
				doc.elements.each("ISBNdb/BookList/BookData"){|book|
					#oh god, but title etc has no specific id in the xml, so can't filter on it
					#processes all the books, although only 1 book should be returned by the server as we search for isbn
					book.elements.each("Title"){ |_title|
						title = _title.text.strip
						bookhsh.store(:title, title)	if title
					}
					book.elements.each("AuthorsText"){ |_author|
						author = _author.text.strip
						bookhsh.store(:author,author)	if author
					}
					book.each_element_with_attribute("publisher_id"){ |_pub|
						pub = _pub.text.strip
						bookhsh.store(:publisher,pub)	if pub
					}
				}
				if update
					@books_author.text		= bookhsh[:author]
					@books_title.text		= bookhsh[:title]
					@books_publisher.text = bookhsh[:publisher]
					@books_isbn.text		= isbn
				end
				return bookhsh
			end

			begin
				require 'net/http'
				require 'rexml/document'
			rescue Exception => e
				STDERR.puts "Ruby/ISBN-DB kon niet geladen worden: " + e.to_s
				{}
			end

			#move to client (or just leave it here as you really can't do any harm with this key)
			key = "Y42N22G5"
			url = "http://isbndb.com/api/books.xml?"

			isbnquery = "index1=isbn&value1=#{isbn}"
			response = fetch("#{url}access_key=#{key}&#{isbnquery}", 10)
			doc = REXML::Document.new(response.body)
			puts "#{url}access_key=#{key}&#{isbnquery}"
			return process_book(doc,isbn,update)

		rescue Exception => e
			#in case of an error we return empty hash == no book
			STDERR.puts e.message
			@books_notification.text = "Fout: Lookup ISBNDB: #{e.message.smaller}"
			{}
		end

		def _lookup_isbnbook(isbn, update = true)
			bookhsh = {}
			bookhsh = _lookup_amazon_isbn(isbn,update) if isbn.size == 10
			bookhsh = _lookup_isbndb_isbn(isbn,update) if bookhsh.size == 0
			return bookhsh	#hash, either empty or :title, :author, :publisher avail
		end


		def _show(book)
			@books_isbn.text = book["isbn"]
			@loan_isbn.text = book["isbn"]
			@books_title.text = book["title"]
			@loan_title.text = book["title"]
			@loan_notification.text = ""
			@books_author.text = book["author"]
			@books_publisher.text = book["publisher"]
			@books_year.text = book["year"]
			@books_copies.text = book["copies"]
			_update_sections
			sections = $client.bib_sections.collect{|b| b.name}
			index = sections.index book.section
			@books_section.active = index+1
		end

		def _update_books_list(books=nil, clear=true)
			@books_notification.text = "loading books..."
			@books_list_store.clear if clear
			Thread.new do
				books = $client.bib_books if books.nil?
				unless books.empty?
					books.each do |b|
						@books_list_store.append[0] = b
					end
				end
				if books.empty?
					@books_notification.text = "the ig3tool imps found no books..."
				else
					@books_notification.text = ""
				end
			end

		end

		def _update_loan_list(clear=true)
			@loan_list_store.clear if clear
			Thread.new do
				loans = $client.bib_loans
				loans.each do |b|
					@loan_list_store.append[0] = b
				end
			end

		end


		def _update_sections
			sections = $client.bib_sections
			sections_model = Gtk::ListStore.new(Object, String)

			empty = sections_model.append
			empty[0] = nil
			empty[1] = "ANY: Any section"

			sections.each do |s|
				row    = sections_model.append
				row[0] = s
				row[1] = s.name + ": " + s.full_name
			end

			@books_section.model = sections_model
			@books_section.active = 0
			@books_section.clear
			renderer = Gtk::CellRendererText.new
			@books_section.pack_start(renderer, true)
			@books_section.set_attributes(renderer, :text => 1)
		end



	end

	register_window(BibliotheekWindow)


end
