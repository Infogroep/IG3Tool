require 'gettext'
module Ig3tool
	class LoginWindow < GladeHelper
		include GetText

    MENU_PATH = ["Login", "Login"]
    ICON = "stock_print.png"

		attr :glade

		def initialize(client, &block)
      super("loginwindow.glade", "loginwindow")

			@username = @glade.get_widget("username")
			@password = @glade.get_widget("password")
			@apply    = @glade.get_widget("apply")
			@loginwin = @glade.get_widget("loginwindow")
			@success  = block

		end

		def password_activate(widget)
			@apply.activate
		end
		def apply(widget)
			h = {"username" => @username.text, "password" => @password.text}
      @username.text = ""
      @password.text = ""
			$client.wannabe!(h)
      @loginwin.hide
			@success.call
		rescue Token => t
			puts "ERROR: #{t.message}"
			Ig3tool::error_dialog(nil, t)
		end
		def cancel(widget)
      @username.text = ""
      @password.text = ""
      @loginwin.hide
      Gtk.main_quit
			return nil
		end
		def destroy_event(widget, arg0)
      @username.text = ""
      @password.text = ""
      @loginwin.hide
		end
		def delete_event(widget, arg0)
      @username.text = ""
      @password.text = ""
      @loginwin.hide
		end
		def username_activate(widget)
			@password.grab_focus
		end
	end

end

