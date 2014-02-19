module Ig3tool

	module_function

	def messagebox(title,message)

		overwrite = false
		dialog = Gtk::MessageDialog.new(nil,
																		Gtk::Dialog::DESTROY_WITH_PARENT | Gtk::Dialog::MODAL,
																		Gtk::MessageDialog::QUESTION,
																		Gtk::MessageDialog::BUTTONS_YES_NO,
																		message)
		dialog.title = title
		dialog.run do |response|
			case response
			when Gtk::Dialog::RESPONSE_YES
				overwrite = true
			end
			dialog.destroy
		end
		overwrite # Return overwrite? boolean -> true indien 'YES'
	end
end
